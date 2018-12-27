import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

enum TtsState { playing, stopped }

class _MyAppState extends State<MyApp> {
  FlutterTts flutterTts;
  List<dynamic> languages;
  String language;

  String _newVoiceText;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  @override
  initState() {
    super.initState();
    initTts();
    _getLanguages();
  }

  initTts() async {
    flutterTts = new FlutterTts();

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _speak() async {
    var result = await flutterTts.speak(_newVoiceText);
    if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    var items = new List<DropdownMenuItem<String>>();
    for (String type in languages) {
      items.add(new DropdownMenuItem(value: type, child: new Text(type)));
    }
    return items;
  }

  void changedDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
    });
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  void _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Flutter TTS'),
          ),
          body: languages != null
              ? _buildRowWithLanguages()
              : _buildRowWithoutLanguages()),
    );
  }

  Widget _buildRowWithoutLanguages() => new Column(children: <Widget>[
        new Container(
            alignment: Alignment.topCenter,
            padding: new EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
            child: new TextField(
              onChanged: (String value) {
                _onChange(value);
              },
            )),
        new Container(
            padding: new EdgeInsets.only(top: 200.0),
            child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new IconButton(
                      icon: new Icon(Icons.play_arrow),
                      onPressed: _newVoiceText == null || isPlaying == true
                          ? null
                          : () => _speak(),
                      color: Colors.green,
                      splashColor: Colors.greenAccent),
                  new IconButton(
                      icon: new Icon(Icons.stop),
                      onPressed: isStopped == true ? null : () => _stop(),
                      color: Colors.red,
                      splashColor: Colors.redAccent),
                ]))
      ]);

  Widget _buildRowWithLanguages() => new Column(children: <Widget>[
        new Container(
            alignment: Alignment.topCenter,
            padding: new EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
            child: new TextField(
              onChanged: (String value) {
                _onChange(value);
              },
            )),
        new Container(
            padding: new EdgeInsets.only(top: 200.0),
            child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new IconButton(
                      icon: new Icon(Icons.play_arrow),
                      onPressed: _newVoiceText == null || isPlaying == true
                          ? null
                          : () => _speak(),
                      color: Colors.green,
                      splashColor: Colors.greenAccent),
                  new IconButton(
                      icon: new Icon(Icons.stop),
                      onPressed: isStopped == true ? null : () => _stop(),
                      color: Colors.red,
                      splashColor: Colors.redAccent),
                  new DropdownButton(
                    value: language,
                    items: getDropDownMenuItems(),
                    onChanged: changedDropDownItem,
                  )
                ]))
      ]);
}
