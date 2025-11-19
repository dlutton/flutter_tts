// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tts_android/flutter_tts_android.dart';
import 'package:flutter_tts_windows/flutter_tts_windows.dart';

extension on Voice {
  String get displayName {
    final elements = <String>[name, locale];
    if (gender != null) {
      elements.add(gender!);
    }
    if (quality != null) {
      elements.add(quality!);
    }
    return elements.join(' - ');
  }
}

void main() {
  runZonedGuarded(() => runApp(MyApp()), (error, stackTrace) {
    print("Error: $error");
    print("Stack Trace: $stackTrace");
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum TtsState { playing, stopped, paused, continued }

class _MyAppState extends State<MyApp> {
  late FlutterTtsPlatform flutterTts;
  String? language;
  String? engine;
  Voice? voice;
  final voices = <Voice>[];
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  String? _newVoiceText;
  int? _inputLength;
  final _editingController = TextEditingController();

  TtsProgress? _speakingProgess;

  bool _isWordBoundary = true;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  @override
  initState() {
    super.initState();
    initTts();
  }

  dynamic initTts() {
    flutterTts = FlutterTts.platform;

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.onSpeakStart = () {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    };

    flutterTts.onSpeakComplete = () {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
        _speakingProgess = null;
      });
    };

    flutterTts.onSpeakCancel = () {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
        _speakingProgess = null;
      });
    };

    flutterTts.onSpeakPause = () {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    };

    flutterTts.onSpeakResume = () {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    };

    flutterTts.onSpeakError = (msg) {
      print("error: $msg");
      setState(() {
        ttsState = TtsState.stopped;
        _speakingProgess = null;
      });
    };

    flutterTts.onSpeakProgress = (progress) {
      setState(() {
        _speakingProgess = progress;
      });
    };

    flutterTts.getVoices().then((value) {
      value.when(
        (newVoices) => setState(() {
          voices.clear();
          voices.addAll(newVoices);
        }),
        (e) => print("Error: $e"),
      );
    });
  }

  Future<List<String>> _getLanguages() async {
    final languages = await flutterTts.getLanguages();
    switch (languages) {
      case SuccessDart():
        return languages.success;
      case FailureDart():
        print("Error: ${languages.error}");
        return [];
    }
  }

  Future<List<String>> _getEngines() async {
    if (flutterTts case final FlutterTtsAndroid tts) {
      final engines = await tts.getEngines();
      switch (engines) {
        case SuccessDart(success: var newEngines):
          return newEngines;
        case FailureDart(error: var e):
          print("Error: $e");
          return [];
      }
    }

    return [];
  }

  Future<void> _getDefaultEngine() async {
    if (flutterTts case final FlutterTtsAndroid tts) {
      final defaultEngine = await tts.getDefaultEngine();
      switch (defaultEngine) {
        case SuccessDart(success: var newEngine):
          engine = newEngine;
          break;
        case FailureDart(error: var e):
          print("Error: $e");
          engine = null;
          break;
      }
    }
  }

  Future<void> _getDefaultVoice() async {
    if (flutterTts case final FlutterTtsAndroid tts) {
      final defVoice = await tts.getDefaultVoice();
      switch (defVoice) {
        case SuccessDart():
          voice = defVoice.success;
          break;
        case FailureDart():
          print("Error: ${defVoice.error}");
          voice = null;
          break;
      }
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
    await flutterTts.awaitSpeakCompletion(awaitCompletion: true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    switch (result) {
      case SuccessDart():
        if (result.success.success) {
          setState(() => ttsState = TtsState.stopped);
        }
        break;
      case FailureDart():
        print("Error: ${result.error}");
        break;
    }
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    switch (result) {
      case SuccessDart():
        if (result.success.success) {
          setState(() => ttsState = TtsState.paused);
        }
        break;
      case FailureDart():
        print("Error: ${result.error}");
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(
    List<dynamic> engines,
  ) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(
        DropdownMenuItem(value: type as String?, child: Text((type as String))),
      );
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    if (selectedEngine != null && selectedEngine.isNotEmpty) {
      if (flutterTts case final FlutterTtsAndroid tts) {
        await tts.setEngine(selectedEngine);
        setState(() {
          engine = selectedEngine;
          language = null;
          voice = null;
          voices.clear();
        });
      }
    }
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
    List<dynamic> languages,
  ) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(
        DropdownMenuItem(value: type as String?, child: Text((type as String))),
      );
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) async {
    var newIsCurrentLanguageInstalled = false;
    setState(() {
      language = selectedType;
      voice = null;
      isCurrentLanguageInstalled = newIsCurrentLanguageInstalled;
    });
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(title: Text('Flutter TTS')),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              if (_speakingProgess case final progess?) ...[
                Padding(
                  padding: EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
                  child: Text(
                    progess.word,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (progess.start > 0)
                          TextSpan(
                            text: progess.text.substring(0, progess.start),
                          ),
                        TextSpan(
                          text: progess.text.substring(
                            math.max(0, progess.start),
                            math.min(progess.text.length, progess.end),
                          ),
                          style: TextStyle(color: Colors.red),
                        ),
                        if (progess.end < progess.text.length - 1)
                          TextSpan(text: progess.text.substring(progess.end)),
                      ],
                    ),
                  ),
                ),
              ],
              _inputSection(),
              _btnSection(),
              _engineSection(),
              _futureBuilder(),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [_buildGetVoiceBtn(), _buildAddTextToSpeak()],
              ),
              if (voices.isNotEmpty) _buildSelectVoice(),
              _buildSliders(),
              if (isAndroid) _getMaxSpeechInputLengthSection(),
            ],
          ),
        ),
      ),
    );
  }

  TextButton _buildAddTextToSpeak() {
    return TextButton(
      onPressed: () {
        _newVoiceText = """
The quick brown fox jumps over the lazy dog. 
混沌未分天地乱，茫茫渺渺无人见。 自从盘古破鸿蒙，开辟从兹清浊辨。 覆载群生仰至仁，发明万物皆为善。 欲知造化会元功，须看《西游释厄传》。
The quick brown fox jumps over the lazy dog.
我说"1<2" & 3>0，对吧？
Whether the weather be fine or whether the weather be not.
Whether the weather be cold or whether the weather be hot.
We'll weather the weather whether we like it or not.
季姬寂，集鸡，鸡即棘鸡。棘鸡饥叽，季姬及箕稷济鸡。鸡既济，跻姬笈，季姬忌，急咭鸡，鸡急，继圾几，季姬急，即籍箕击鸡，箕疾击几伎，伎即齑，鸡叽集几基，季姬急极屐击鸡，鸡既殛，季姬激，即记《季姬击鸡记》。
なまむぎ　なまごめ　なまたまご
간장공장 공장장은 강공장장이고된장공장 공장장은 공공장장이다
Cinq chiens chassent six chats.
На дворе-трава, на траве-дрова. Не руби дрова на траве-двора.
""";
        _editingController.text = _newVoiceText!;
      },
      child: Text("Add Default Text"),
    );
  }

  TextButton _buildGetVoiceBtn() {
    return TextButton(
      onPressed: () async {
        var result = await flutterTts.getVoices();
        switch (result) {
          case SuccessDart():
            setState(() {
              voices.clear();
              voices.addAll(result.success);
            });
            break;
          case FailureDart():
            print("Error: ${result.error}");
            break;
        }
      },
      child: Text("Get Voices"),
    );
  }

  DropdownButton<Voice> _buildSelectVoice() {
    final selectedLang = language?.split('-').first;
    var voiceToShow = voices.where(
      (element) =>
          selectedLang == null || element.locale.startsWith(selectedLang),
    );

    if (voiceToShow.isEmpty) {
      voiceToShow = voices;
    }

    return DropdownButton(
      value: voice,
      items: [
        for (final ii in voiceToShow)
          DropdownMenuItem(value: ii, child: Text(ii.displayName)),
      ],
      onChanged: (value) {
        setState(() {
          voice = value;
        });

        if (value != null) {
          flutterTts.setVoice(value);
        }
      },
    );
  }

  Widget _engineSection() {
    if (isAndroid) {
      return FutureBuilder<dynamic>(
        future: _getEngines(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return _enginesDropDownSection(snapshot.data as List<dynamic>);
          } else if (snapshot.hasError) {
            return Text('Error loading engines...');
          } else {
            return Text('Loading engines...');
          }
        },
      );
    } else if (flutterTts case final FlutterTtsWindows winTts) {
      return Row(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isWordBoundary ? "Word Boundary" : "Sentence Boundary"),
          Switch(
            value: _isWordBoundary,
            onChanged: (value) async {
              await winTts.setBoundaryType(isWordBoundary: value);
              setState(() => _isWordBoundary = value);
            },
          ),
        ],
      );
    } else {
      return SizedBox(width: 0, height: 0);
    }
  }

  Widget _futureBuilder() => FutureBuilder<dynamic>(
    future: _getLanguages(),
    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
      if (snapshot.hasData) {
        return _languageDropDownSection(snapshot.data as List<dynamic>);
      } else if (snapshot.hasError) {
        return Text('Error loading languages...\n${snapshot.error}');
      } else {
        return Text('Loading Languages...');
      }
    },
  );

  Widget _inputSection() => Container(
    alignment: Alignment.topCenter,
    padding: EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
    child: TextField(
      controller: _editingController,
      maxLines: 11,
      minLines: 6,
      onChanged: (String value) {
        _onChange(value);
      },
    ),
  );

  Widget _btnSection() {
    return Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonColumn(
            Colors.green,
            Colors.greenAccent,
            Icons.play_arrow,
            'PLAY',
            _speak,
          ),
          _buildButtonColumn(
            Colors.red,
            Colors.redAccent,
            Icons.stop,
            'STOP',
            _stop,
          ),
          _buildButtonColumn(
            Colors.blue,
            Colors.blueAccent,
            Icons.pause,
            'PAUSE',
            _pause,
          ),
        ],
      ),
    );
  }

  Widget _enginesDropDownSection(List<dynamic> engines) => Container(
    padding: EdgeInsets.only(top: 50.0),
    child: DropdownButton(
      value: engine,
      items: getEnginesDropDownMenuItems(engines),
      onChanged: changedEnginesDropDownItem,
    ),
  );

  Widget _languageDropDownSection(List<dynamic> languages) => Container(
    padding: EdgeInsets.only(top: 10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton(
          value: language,
          items: getLanguageDropDownMenuItems(languages),
          onChanged: changedLanguageDropDownItem,
        ),
        Visibility(
          visible: isAndroid,
          child: Text("Is installed: $isCurrentLanguageInstalled"),
        ),
      ],
    ),
  );

  Column _buildButtonColumn(
    Color color,
    Color splashColor,
    IconData icon,
    String label,
    Function func,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          splashColor: splashColor,
          onPressed: () => func(),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getMaxSpeechInputLengthSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('Get max speech input length'),
          onPressed: () async {},
        ),
        Text("$_inputLength characters"),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(children: [_volume(), _pitch(), _rate()]);
  }

  Widget _volume() {
    return Slider(
      value: volume,
      onChanged: (newVolume) {
        setState(() {
          volume = newVolume;
          flutterTts.setVolume(volume);
        });
      },
      min: 0.0,
      max: 1.0,
      divisions: 10,
      label: "Volume: ${volume.toStringAsFixed(1)}",
    );
  }

  Widget _pitch() {
    return Slider(
      value: pitch,
      onChanged: (newPitch) {
        setState(() {
          pitch = newPitch;
          flutterTts.setPitch(pitch);
        });
      },
      min: 0.5,
      max: 2.0,
      divisions: 15,
      label: "Pitch: ${pitch.toStringAsFixed(1)}",
      activeColor: Colors.red,
    );
  }

  Widget _rate() {
    return Slider(
      value: rate,
      onChanged: (newRate) {
        setState(() {
          rate = newRate;
          flutterTts.setSpeechRate(rate);
        });
      },
      min: 0.0,
      max: 2.0,
      divisions: 20,
      label: "Rate: ${rate.toStringAsFixed(1)}",
      activeColor: Colors.green,
    );
  }
}
