import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'interop_types.dart';

enum TtsState { playing, stopped, paused, continued }

class FlutterTtsPlugin {
  static const String platformChannel = "flutter_tts";
  static late MethodChannel channel;
  bool awaitSpeakCompletion = false;

  TtsState ttsState = TtsState.stopped;

  Completer<dynamic>? _speechCompleter;

  bool get isPlaying => ttsState == TtsState.playing;

  bool get isStopped => ttsState == TtsState.stopped;

  bool get isPaused => ttsState == TtsState.paused;

  bool get isContinued => ttsState == TtsState.continued;

  static void registerWith(Registrar registrar) {
    channel =
        MethodChannel(platformChannel, const StandardMethodCodec(), registrar);
    final instance = FlutterTtsPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  late final SpeechSynthesisUtterance utterance;
  List<SpeechSynthesisVoice> voices = [];
  List<String> languages = [];
  Timer? t;
  bool supported = false;

  FlutterTtsPlugin() {
    try {
      utterance = SpeechSynthesisUtterance();
      _listeners();
      supported = true;
    } catch (e) {
      print('Initialization of TTS failed. Functions are disabled. Error: $e');
    }
  }

  void _listeners() {
    utterance.onStart = (JSAny e) {
      print('[TTS_WEB] onStart: speech started');
      print('[TTS_WEB] onStart: utterance.voice=${utterance.voice?.name} / ${utterance.voice?.lang}');
      print('[TTS_WEB] onStart: utterance.lang=${utterance.lang}');
      ttsState = TtsState.playing;
      channel.invokeMethod("speak.onStart", null);
      var bLocal = (utterance.voice?.isLocalService ?? false);
      print('[TTS_WEB] onStart: isLocalService=$bLocal');
      if (!bLocal) {
        t = Timer.periodic(Duration(seconds: 14), (t) {
          if (ttsState == TtsState.playing) {
            synth.pause();
            synth.resume();
          } else {
            t.cancel();
          }
        });
      }
    }.toJS;
    // js.JsFunction.withThis((e) {
    //   ttsState = TtsState.playing;
    //   channel.invokeMethod("speak.onStart", null);
    // });
    utterance.onEnd = (JSAny e) {
      ttsState = TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter?.complete();
        _speechCompleter = null;
      }
      t?.cancel();
      channel.invokeMethod("speak.onComplete", null);
    }.toJS;

    utterance.onPause = (JSAny e) {
      ttsState = TtsState.paused;
      channel.invokeMethod("speak.onPause", null);
    }.toJS;

    utterance.onResume = (JSAny e) {
      ttsState = TtsState.continued;
      channel.invokeMethod("speak.onContinue", null);
    }.toJS;

    utterance.onError = (JSObject event) {
      ttsState = TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter = null;
      }
      t?.cancel();
      print(event); // Log the entire event object to get more details
      channel.invokeMethod("speak.onError", event["error"]);
    }.toJS;

    utterance.onBoundary = (JSObject event) {
      int charIndex = event['charIndex'] as int;
      String name = event['name'] as String;
      if (name == 'sentence') return;
      String text = utterance['text'] as String;
      int endIndex = charIndex;
      while (endIndex < text.length &&
          !RegExp(r'[\s,.!?]').hasMatch(text[endIndex])) {
        endIndex++;
      }
      String word = text.substring(charIndex, endIndex);
      Map<String, dynamic> progressArgs = {
        'text': text,
        'start': charIndex,
        'end': endIndex,
        'word': word
      };
      channel.invokeMethod("speak.onProgress", progressArgs);
    }.toJS;

    synth.onVoicesChanged = (JSAny e) {
      channel.invokeMethod("synth.onVoicesChanged", null);
    }.toJS;
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    if (!supported) return;
    switch (call.method) {
      case 'speak':
        final text = call.arguments as String?;
        if (awaitSpeakCompletion) {
          _speechCompleter = Completer();
        }
        _speak(text);
        if (awaitSpeakCompletion) {
          return _speechCompleter?.future;
        }
        break;
      case 'awaitSpeakCompletion':
        awaitSpeakCompletion = (call.arguments as bool?) ?? false;
        return 1;
      case 'stop':
        _stop();
        return 1;
      case 'pause':
        _pause();
        return 1;
      case 'setLanguage':
        final language = call.arguments as String;
        _setLanguage(language);
        return 1;
      case 'getLanguages':
        return _getLanguages();
      case 'getVoices':
        return getVoices();
      case 'setVoice':
        final tmpVoiceMap =
            Map<String, String>.from(call.arguments as LinkedHashMap);
        return _setVoice(tmpVoiceMap);
      case 'setSpeechRate':
        final rate = call.arguments as double;
        _setRate(rate);
        return 1;
      case 'setVolume':
        final volume = call.arguments as double;
        _setVolume(volume);
        return 1;
      case 'setPitch':
        final pitch = call.arguments as double;
        _setPitch(pitch);
        return 1;
      case 'isLanguageAvailable':
        final lang = call.arguments as String;
        return _isLanguageAvailable(lang);
      default:
        throw PlatformException(
            code: 'Unimplemented',
            details: "The flutter_tts plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  void _speak(String? text) {
    print('[TTS_WEB] _speak called with text: ${text?.substring(0, text.length > 50 ? 50 : text.length)}...');
    print('[TTS_WEB] _speak: current ttsState=$ttsState');
    print('[TTS_WEB] _speak: utterance.voice=${utterance.voice?.name} / ${utterance.voice?.lang}');
    print('[TTS_WEB] _speak: utterance.lang=${utterance.lang}');
    if (text == null || text.isEmpty) {
      print('[TTS_WEB] _speak: text is null or empty, returning');
      return;
    }
    if (ttsState == TtsState.stopped || ttsState == TtsState.paused) {
      utterance.text = text;
      if (ttsState == TtsState.paused) {
        print('[TTS_WEB] _speak: resuming paused speech');
        synth.resume();
      } else {
        print('[TTS_WEB] _speak: calling synth.speak() with voice=${utterance.voice?.name}');
        synth.speak(utterance);
      }
    } else {
      print('[TTS_WEB] _speak: skipped - ttsState is $ttsState (not stopped or paused)');
    }
  }

  void _stop() {
    if (ttsState != TtsState.stopped) {
      synth.cancel();
    }
  }

  void _pause() {
    if (ttsState == TtsState.playing || ttsState == TtsState.continued) {
      synth.pause();
    }
  }

  void _setRate(double rate) => utterance.rate = rate;
  void _setVolume(double volume) => utterance.volume = volume;
  void _setPitch(double pitch) => utterance.pitch = pitch;
  void _setLanguage(String language) {
    print('[TTS_WEB] _setLanguage called with: $language');
    var allVoices = synth.getVoices().toDart;
    print('[TTS_WEB] _setLanguage: ${allVoices.length} voices available');
    var targetList = allVoices.where((e) {
      return e.lang.toLowerCase().startsWith(language.toLowerCase());
    });
    print('[TTS_WEB] _setLanguage: ${targetList.length} voices match language $language');
    if (targetList.isNotEmpty) {
      print('[TTS_WEB] _setLanguage: setting voice to ${targetList.first.name} / ${targetList.first.lang}');
      utterance.voice = targetList.first;
      utterance.lang = targetList.first.lang;
    } else {
      print('[TTS_WEB] _setLanguage: NO matching voice found for $language');
    }
  }

  void _setVoice(Map<String?, String?> voice) {
    print('[TTS_WEB] _setVoice called with: name=${voice["name"]}, locale=${voice["locale"]}');
    var tmpVoices = synth.getVoices().toDart;
    print('[TTS_WEB] _setVoice: ${tmpVoices.length} voices available from synth.getVoices()');
    var targetList = tmpVoices.where((e) {
      return voice["name"] == e.name && voice["locale"] == e.lang;
    });
    print('[TTS_WEB] _setVoice: ${targetList.length} voices match name=${voice["name"]} AND locale=${voice["locale"]}');
    if (targetList.isNotEmpty) {
      print('[TTS_WEB] _setVoice: SUCCESS - setting utterance.voice to ${targetList.first.name} / ${targetList.first.lang}');
      utterance.voice = targetList.first;
      utterance.lang = targetList.first.lang;
      print('[TTS_WEB] _setVoice: utterance.voice is now ${utterance.voice?.name} / ${utterance.voice?.lang}');
    } else {
      print('[TTS_WEB] _setVoice: FAILED - no matching voice found!');
      // Log first few available voices for debugging
      for (var i = 0; i < tmpVoices.length && i < 5; i++) {
        print('[TTS_WEB] _setVoice: available[$i]: ${tmpVoices[i].name} / ${tmpVoices[i].lang}');
      }
    }
  }

  bool _isLanguageAvailable(String? language) {
    if (voices.isEmpty) _setVoices();
    if (languages.isEmpty) _setLanguages();
    for (var lang in languages) {
      if (!language!.contains('-')) {
        lang = lang.split('-').first;
      }
      if (lang.toLowerCase() == language.toLowerCase()) return true;
    }
    return false;
  }

  List<String?>? _getLanguages() {
    if (voices.isEmpty) _setVoices();
    if (languages.isEmpty) _setLanguages();
    return languages;
  }

  void _setVoices() {
    voices = synth.getVoices().toDart;
  }

  Future<List<Map<String, String>>> getVoices() async {
    var tmpVoices = synth.getVoices().toDart;
    print('[TTS_WEB] getVoices: returning ${tmpVoices.length} voices');
    return tmpVoices
        .map((voice) => {"name": voice.name, "locale": voice.lang})
        .toList();
  }

  void _setLanguages() {
    var langs = <String>{};
    for (var v in voices) {
      langs.add(v.lang);
    }

    languages = langs.toList();
  }
}
