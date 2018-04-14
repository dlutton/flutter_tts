# Text To Speech

A flutter text to speech plugin (Swift,Java)

## Features

- [x] Android & iOS
  - [x] speak
  - [x] stop
  - [x] get languages
  - [x] set language
  - [x] speech rate

## Usage

[Example](https://github.com/dlutton/flutter_tts/blob/master/example/lib/main.dart) 

To use this plugin : 

- add the dependency to your [pubspec.yaml](https://github.com/dlutton/flutter_tts/blob/master/example/pubspec.yaml) file.

```yaml
  dependencies:
    flutter:
      sdk: flutter
    flutter_tts:
```

- instantiate a FlutterTts instance

```dart
FlutterTts flutterTts = new FlutterTts();
```

### speak, stop, getLanguages, setLanguage, speech rate

```dart
Future _speak() async{
    var result = await flutterTts.speak("Hello World");
    if (result == 1) setState(() => ttsState = TtsState.playing);
}

Future _stop() async{
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
}

List<dynamic> languages = await flutterTts.getLanguages;

await flutterTts.setLanguage("en-US");

await flutterTts.setRate(1.0);
```

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).