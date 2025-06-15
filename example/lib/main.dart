import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'language_helper.dart'; // Import the facade

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

enum TtsState { playing, stopped, paused, continued }

class MyAppState extends State<MyApp> {
  late FlutterTts flutterTts;
  List<String?> rawEngines = [];
  List<DropdownMenuItem<String?>> engineItems = [];
  String? engine;
  List<Map<String, String>?> rawVoices = [];
  List<DropdownMenuItem<Map<String, String>?>> voiceItems = [];
  Completer<void> _voiceDataReadyCompleter = Completer<void>();
  Map<String, String>? voice;
  bool getDefaultVoiceRetried = false;
  List<String?> rawLanguages = [];
  List<DropdownMenuItem<String?>> languageItems = [];
  String? language;
  double volume = 0.8;
  double pitch = 1.0;
  double rate = !kIsWeb ? 0.5 : 0.9;
  bool isCurrentLanguageInstalled = false;

  String? _newVoiceText;
  int? _inputLength;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isMacOS => !kIsWeb && Platform.isMacOS;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  @override
  initState() {
    super.initState();
    initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDefaults(); // invoked after initial build of context is complete
    });
  }

  // from initState()
  void initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    flutterTts.setStartHandler(() {
      setState(() {
        if (kDebugMode) debugPrint("TtsState: Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        if (kDebugMode) debugPrint("TtsState: Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        if (kDebugMode) debugPrint("TtsState: Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        if (kDebugMode) debugPrint("TtsState: Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        if (kDebugMode) debugPrint("TtsState: Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        if (kDebugMode) debugPrint("TtsState: Error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future<void> _getDefaults() async {
    if (kDebugMode) debugPrint('_getDefaults...');
    if (isAndroid) await _getDefaultEngine();
    if (kIsWeb) setState(() {}); // Tickle the UI
    await _getDefaultVoice();
  }

  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  Future<dynamic> _getVoices() async => await flutterTts.getVoices;

  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;

  Future<void> _getDefaultEngine() async {
    if (!isAndroid) return; // safety-check
    if (kDebugMode) debugPrint('_getDefaultEngine...');
    var e = await flutterTts.getDefaultEngine;
    if (e != null) {
      if (kDebugMode) debugPrint('Default Engine: $e');
      setState(() => engine = e as String);
    }
  }

  Future<void> _getDefaultVoice() async {
    if (kDebugMode) debugPrint('_getDefaultVoice..');
    try {
      await _voiceDataReadyCompleter.future.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      if (kDebugMode) debugPrint("Timeout waiting for voice data");
      if (!getDefaultVoiceRetried) {
        getDefaultVoiceRetried = true; // run only once
        _voiceDataReadyCompleter = Completer<void>(); // re-use
        setState(() {}); // Tickle the UI
        _getDefaultVoice();
      }
      return;
    } catch (e) {
      if (kDebugMode) debugPrint("Error waiting for voice data: $e");
      return;
    }
    if (kDebugMode) {
      debugPrint('_voiceDataReadyCompleter.isCompleted, so continuing..');
    }
    if (kDebugMode) debugPrint("rawVoices count: ${rawVoices.length}");
    if (rawVoices.isEmpty) return;

    if (isAndroid) {
      var defVoice = await flutterTts.getDefaultVoice;
      if (kDebugMode) debugPrint('Android Default Voice: $defVoice');
      if (defVoice != null) {
        var rawVoice = rawVoices.firstWhere((v) => mapEquals(v, defVoice));
        voice = rawVoice;
        if (voice != null) changedVoicesDropDownItem(voice);
      }
    } else {
      String myLocale;
      // Web may return just the language code, e.g. "de", if the browser's
      // Settings/Language contains preferred language entries containing only
      // the language without a region (e.g. "German" and not "German (Germany)").
      Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (kDebugMode) debugPrint('Device Locale (ISO): $deviceLocale');
      // TTS uses Unicode BCP47 Locale Identifiers instead of the ISO standard
      myLocale = deviceLocale.toLanguageTag();
      if (kIsWeb && !myLocale.contains('-')) {
        var webLocale = getBrowserLanguage();
        if (kDebugMode) debugPrint('webLocale: $webLocale');
        if (webLocale != null) myLocale = webLocale;
      }
      if (kDebugMode) debugPrint('Device/Browser Locale (BCP47): $myLocale');
      // TTS auto-selects the first matching raw voice with locale
      var rawVoice = rawVoices.firstWhere((v) => v?['locale'] == myLocale,
          orElse: () => rawVoices
              .firstWhere((v) => v?['locale']?.startsWith(myLocale) ?? false));
      voice = rawVoice;
      if (kDebugMode) debugPrint('Computed Default Voice: $voice');
      if (voice != null) changedVoicesDropDownItem(voice);
    }
  }

  Future<void> _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String?>> getEnginesDropDownMenuItems(
      List<dynamic> engines) {
    if (kDebugMode) debugPrint('getEnginesDropDownMenuItems...');
    if (engineItems.isEmpty) {
      rawEngines.clear();
      for (dynamic item in engines) {
        // if (kDebugMode) debugPrint('Engine: $item');
        rawEngines.add(item);
        engineItems
            .add(DropdownMenuItem<String?>(value: item, child: Text(item)));
      }
    }
    return engineItems;
  }

  Future<void> changedEnginesDropDownItem(String? selectedEngine) async {
    if (selectedEngine == null || selectedEngine.trim().isEmpty) {
      return;
    }
    if (kDebugMode) debugPrint('changedEnginesDropDownItem...');
    await flutterTts.setEngine(selectedEngine);
    engine = selectedEngine;
    voiceItems.clear();
    voice = null;
    languageItems.clear();
    language = null;
    isCurrentLanguageInstalled = false;
    _voiceDataReadyCompleter = Completer<void>(); // re-use
    setState(() {});
    getDefaultVoiceRetried = false;
    await _getDefaultVoice();
  }

  List<DropdownMenuItem<Map<String, String>?>> getVoicesDropDownMenuItems(
      List<dynamic> voices) {
    if (kDebugMode) {
      debugPrint('getVoicesDropDownMenuItems: voices count: ${voices.length}');
    }
    if (kDebugMode) debugPrint("voiceItems.count: ${voiceItems.length}");
    if (voiceItems.isEmpty) {
      rawVoices.clear();
      for (dynamic item in voices) {
        // if (kDebugMode) debugPrint('Voice: $item');
        var v = Map<String, String>.from(item);
        rawVoices.add(v); // remains unsorted
        // if (kDebugMode) debugPrint('Raw Voice: $v');
        var menuItem = DropdownMenuItem<Map<String, String>?>(
          value: v,
          child: Text("${v['name']} (${v['locale']})"),
        );
        if (!voiceItems
            .any((element) => mapEquals(element.value, menuItem.value))) {
          voiceItems.add(menuItem);
        }
      }
      voiceItems.sort((a, b) {
        return a.child
            .toString()
            .toLowerCase()
            .compareTo(b.child.toString().toLowerCase());
      });
    }
    if (voiceItems.isNotEmpty && !_voiceDataReadyCompleter.isCompleted) {
      _voiceDataReadyCompleter.complete();
      if (kDebugMode) {
        debugPrint(
            '_voiceDataReadyCompleter completed with ${voiceItems.length} voiceItems');
      }
    }
    return voiceItems;
  }

  Future<void> changedVoicesDropDownItem(
      Map<String, String>? selectedVoice) async {
    if (selectedVoice == null || selectedVoice.isEmpty) {
      return;
    }
    if (kDebugMode) debugPrint('changedVoicesDropDownItem...');
    await flutterTts.setVoice(selectedVoice);
    voice = selectedVoice;
    language = selectedVoice['locale'];
    setState(() {});
  }

  List<DropdownMenuItem<String?>> getLanguagesDropDownMenuItems(
      List<dynamic> languages) {
    if (kDebugMode) debugPrint('getLanguagesDropDownMenuItems...');
    if (languageItems.isEmpty) {
      rawLanguages.clear();
      for (dynamic item in languages) {
        // if (kDebugMode) debugPrint('Language: $item');
        rawLanguages.add(item); // remains unsorted
        var menuItem =
            DropdownMenuItem<String?>(value: item, child: Text(item));
        if (!languageItems.any((element) => element.value == menuItem.value)) {
          languageItems.add(menuItem);
        }
      }
      languageItems.sort((a, b) {
        return a.child
            .toString()
            .toLowerCase()
            .compareTo(b.child.toString().toLowerCase());
      });
    }
    return languageItems;
  }

  Future<void> changedLanguagesDropDownItem(String? selectedLanguage) async {
    if (selectedLanguage == null || selectedLanguage.trim().isEmpty) {
      return;
    }
    if (kDebugMode) debugPrint('changedLanguagesDropDownItem...');
    await flutterTts.setLanguage(selectedLanguage);
    language = selectedLanguage;
    if (isAndroid) {
      flutterTts
          .isLanguageInstalled(language!)
          .then((value) => isCurrentLanguageInstalled = (value as bool));
    } else {
      isCurrentLanguageInstalled = false;
    }

    // if the locale is changed, TTS auto-selects the first matching voice
    if (voiceItems.isNotEmpty) {
      var voiceItem =
          voiceItems.firstWhere((v) => v.value?['locale'] == selectedLanguage);
      voice = voiceItem.value;
      if (voice != null) changedVoicesDropDownItem(voice);
    }
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  Future<void> saveToFile(String? text) async {
    if (text == null || text.trim().isEmpty) return;
    // Mangle text to a filename
    String myText = text.trim();
    myText = myText.replaceAll(RegExp(r'\s+'), '_'); // one or more spaces
    myText = myText.replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}_]', unicode: true),
        ''); // \p{L} for letters, \p{M} for combining marks ("diacritics"), \p{N}
    myText = myText.substring(0, min(myText.length, 40));
    if (myText.isEmpty) return;
    String fileName = isAndroid ? '$myText.mp3' : '$myText.caf';
    await flutterTts.synthesizeToFile(text, fileName);
    if (kDebugMode) debugPrint('synthesized to: $fileName');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter TTS'),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              _inputSection(),
              _btnSection(),
              _engineSection(), // _getEngines
              _voiceSection(), // _getVoices
              _languageSection(), // _getLanguages
              _buildSliders(),
              if (isAndroid) _getMaxSpeechInputLengthSection(),
            ],
          ),
        ),
        floatingActionButton: (isAndroid || isIOS) &&
                _newVoiceText != null &&
                _newVoiceText!.trim().isNotEmpty
            ? FloatingActionButton(
                mini: true,
                onPressed: () => saveToFile(_newVoiceText),
                tooltip: 'Synthesize to File',
                child: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  Widget _engineSection() {
    if (isAndroid) {
      if (engineItems.isNotEmpty) {
        return _enginesDropDownSection(<dynamic>[]);
      } else {
        return FutureBuilder<dynamic>(
            future: _getEngines(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return _enginesDropDownSection(
                      snapshot.data as List<dynamic>);
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return const Text('No data to load engines');
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Loading engines...');
              } else {
                // Other states (e.g., ConnectionState.none,
                // or if future is null initially)
                return const Text('Waiting to start loading engines...');
              }
            });
      }
    } else {
      return const SizedBox(width: 0, height: 0);
    }
  }

  Widget _voiceSection() {
    if (voiceItems.isNotEmpty) {
      if (!_voiceDataReadyCompleter.isCompleted) {
        _voiceDataReadyCompleter.complete(); // Safety complete
      }
      return _voicesDropDownSection(<dynamic>[]);
    } else {
      return FutureBuilder<dynamic>(
          future: _getVoices(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return _voicesDropDownSection(snapshot.data as List<dynamic>);
              } else if (snapshot.hasError) {
                if (!_voiceDataReadyCompleter.isCompleted) {
                  _voiceDataReadyCompleter.completeError(
                      snapshot.error ?? "Unknown error loading voices");
                }
                return Text('Error: ${snapshot.error}');
              } else {
                return const Text('No data to load voices');
              }
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading voices...');
            } else {
              // Other states (e.g., ConnectionState.none,
              // or if future is null initially)
              return const Text('Waiting to start loading voices...');
            }
          });
    }
  }

  Widget _languageSection() {
    if (languageItems.isNotEmpty) {
      return _languageDropDownSection(<dynamic>[]);
    } else {
      return FutureBuilder<dynamic>(
          future: _getLanguages(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return _languageDropDownSection(snapshot.data as List<dynamic>);
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return const Text('No data to load languages');
              }
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading Languages...');
            } else {
              // Other states (e.g., ConnectionState.none,
              // or if future is null initially)
              return const Text('Waiting to start loading languages...');
            }
          });
    }
  }

  Widget _inputSection() => Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
      child: TextField(
        maxLines: 11,
        minLines: 6,
        onChanged: (String value) {
          _onChange(value);
        },
      ));

  Widget _btnSection() {
    return Container(
      padding: const EdgeInsets.only(top: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonColumn(Colors.green, Colors.greenAccent, Icons.play_arrow,
              'PLAY', _speak),
          _buildButtonColumn(
              Colors.red, Colors.redAccent, Icons.stop, 'STOP', _stop),
          _buildButtonColumn(
              Colors.blue, Colors.blueAccent, Icons.pause, 'PAUSE', _pause),
        ],
      ),
    );
  }

  Widget _enginesDropDownSection(List<dynamic> engines) {
    return Container(
      padding: const EdgeInsets.only(top: 50.0),
      child: DropdownButton<String?>(
        value: engine,
        hint: const Text('Choose an engine'),
        items: getEnginesDropDownMenuItems(engines),
        onChanged: changedEnginesDropDownItem,
      ),
    );
  }

  Widget _voicesDropDownSection(List<dynamic> voices) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      child: DropdownButton<Map<String, String>?>(
        value: voice,
        hint: const Text('Choose a voice'),
        items: getVoicesDropDownMenuItems(voices),
        onChanged: changedVoicesDropDownItem,
      ),
    );
  }

  Widget _languageDropDownSection(List<dynamic> languages) {
    return Container(
        padding: const EdgeInsets.only(top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String?>(
              value: language,
              hint: const Text('Choose a language'),
              items: getLanguagesDropDownMenuItems(languages),
              onChanged: changedLanguagesDropDownItem,
            ),
            const SizedBox(
              width: 5.0,
            ),
            Visibility(
              visible: isAndroid,
              child: Text("Is installed: $isCurrentLanguageInstalled"),
            ),
          ],
        ));
  }

  Column _buildButtonColumn(Color color, Color splashColor, IconData icon,
      String label, Function func) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: Icon(icon),
              color: color,
              splashColor: splashColor,
              onPressed: () => func()),
          Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: color)))
        ]);
  }

  Widget _getMaxSpeechInputLengthSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: const Text('Get max speech input length'),
          onPressed: () async {
            _inputLength = await flutterTts.getMaxSpeechInputLength;
            setState(() {});
          },
        ),
        Text("$_inputLength characters"),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [_volume(), _pitch(), _rate()],
    );
  }

  Widget _volume() {
    return Slider(
        value: volume,
        onChanged: (newVolume) {
          setState(() => volume = newVolume);
        },
        min: 0.0,
        max: 1.0,
        divisions: 10,
        label: "Volume: $volume");
  }

  Widget _pitch() {
    return Slider(
      value: pitch,
      onChanged: (newPitch) {
        setState(() => pitch = newPitch);
      },
      min: 0.5,
      max: 2.0,
      divisions: 15,
      label: "Pitch: $pitch",
      activeColor: Colors.red,
    );
  }

  Widget _rate() {
    return Slider(
      value: rate,
      onChanged: (newRate) {
        setState(() => rate = newRate);
      },
      min: 0.0,
      max: 1.0,
      divisions: 10,
      label: "Rate: $rate",
      activeColor: Colors.green,
    );
  }
}
