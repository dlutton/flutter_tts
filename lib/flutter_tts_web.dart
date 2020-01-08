import 'dart:async';
import 'dart:html' as html;
import 'dart:js';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FlutterTtsPlugin {
  static const String PLATFORM_CHANNEL = "flutter_tts";
  static MethodChannel channel;

  static void registerWith(Registrar registrar) {
    channel = MethodChannel(
        PLATFORM_CHANNEL, const StandardMethodCodec(), registrar.messenger);
    final instance = FlutterTtsPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  html.SpeechSynthesis synth;
  html.SpeechSynthesisUtterance utterance;
  List<dynamic> voices;
  List<String> languages;

  FlutterTtsPlugin() {
    utterance = html.SpeechSynthesisUtterance();
    synth = html.window.speechSynthesis;

    _listeners();
  }

  void _listeners() {
    utterance.onStart
        .listen((e) => channel.invokeMethod("speak.onStart", null));
    utterance.onEnd
        .listen((e) => channel.invokeMethod("speak.onComplete", null));
    utterance.onError.listen((e) => channel.invokeMethod("speak.onError", e));
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'speak':
        final text = call.arguments as String;
        _speak(text);
        return 1;
        break;
      case 'stop':
        return _stop();
        break;
      case 'setLanguage':
        final language = call.arguments as String;
        _setLanguage(language);
        return 1;
        break;
      case 'getLanguages':
        return _getLanguages();
        break;
      case 'setSpeechRate':
        final rate = call.arguments as num;
        _setRate(rate);
        return 1;
        break;
      case 'setVolume':
        final volume = call.arguments as num;
        _setVolume(volume);
        return 1;
        break;
      case 'setPitch':
        final pitch = call.arguments as num;
        _setPitch(pitch);
        return 1;
        break;
      case 'isLanguageAvailable':
        final lang = call.arguments as String;
        return _isLanguageAvailable(lang);
        break;
      default:
        throw PlatformException(
            code: 'Unimplemented',
            details: "The flutter_tts plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  void _speak(String text) {
    synth.cancel();
    utterance.text = text;
    synth.speak(utterance);
  }

  void _stop() => synth.cancel();
  void _setRate(num rate) => utterance.rate = rate * 2.0;
  void _setVolume(num volume) => utterance.volume = volume;
  void _setPitch(num pitch) => utterance.pitch = pitch;
  void _setLanguage(String language) => utterance.lang = language;

  bool _isLanguageAvailable(String language) {
    if (voices?.isEmpty ?? true) _setVoices();
    if (languages?.isEmpty ?? true) _setLanguages();
    for (var lang in languages) {
      if (lang.toLowerCase() == language.toLowerCase()) return true;
    }
    return false;
  }

  List<String> _getLanguages() {
    if (voices?.isEmpty ?? true) _setVoices();
    if (languages?.isEmpty ?? true) _setLanguages();
    return languages;
  }

  void _setVoices() {
    voices =
        context['speechSynthesis'].callMethod('getVoices') as JsArray<dynamic>;
  }

  void _setLanguages() {
    var langs = Set<String>();
    for (var v in voices) {
      langs.add(v['lang'] as String);
    }

    languages = langs.toList();
  }
}
