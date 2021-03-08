# Text To Speech

[![pub package](https://img.shields.io/pub/v/flutter_tts.svg?style=for-the-badge&colorB=green)](https://pub.dartlang.org/packages/flutter_tts)

A flutter text to speech plugin (Swift,Java)

## Compatibility Status

[![Latest compatibility result for Stable channel](https://img.shields.io/endpoint?url=https://pub.green/packages/flutter_tts/badge?channel=stable)](https://pub.green/packages/flutter_tts)

[![Latest compatibility result for Beta channel](https://img.shields.io/endpoint?url=https://pub.green/packages/flutter_tts/badge?channel=beta)](https://pub.green/packages/flutter_tts)

[![Latest compatibility result for Dev channel](https://img.shields.io/endpoint?url=https://pub.green/packages/flutter_tts/badge?channel=dev)](https://pub.green/packages/flutter_tts)

## Features

- [x] Android, iOS, Web, & macOS
  - [x] speak
  - [x] stop
  - [x] get languages
  - [x] set language
  - [x] set speech rate
  - [x] set speech volume
  - [x] set speech pitch
  - [x] is language available
- [x] Android, iOS
  - [x] get voices
  - [x] set voice
  - [x] speech marks (requires iOS 7+ and Android 26+)
  - [x] synthesize to file (requires iOS 13+)
- [x] iOS, Web
  - [x] pause
- [x] Android
  - [x] set silence
  - [x] is lanaguage installed
  - [x] are languages installed
  - [x] get engines
  - [x] set queue mode
- [x] iOS
  - [x] set shared instance
  - [x] set audio session category

## Usage

## macOS

```bash
OSX version: 10.15
```

[Example App](https://github.com/dlutton/flutter_tts/tree/macOS_app) from the macOS_app branch

## Web

[Website](https://dlutton.github.io/flutter_tts) from the example directory.

## Android

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```java
minSdkVersion 21
```

## iOS

There's a known issue with integrating plugins that use Swift into a Flutter project created with the Objective-C template. [Flutter#16049](https://github.com/flutter/flutter/issues/16049)

[Example](https://github.com/dlutton/flutter_tts/blob/master/example/lib/main.dart)

To use this plugin :

- add the dependency to your [pubspec.yaml](https://github.com/dlutton/flutter_tts/blob/master/example/pubspec.yaml) file.

```yaml
  dependencies:
    flutter:
      sdk: flutter
    flutter_tts:
```

- instantiate FlutterTts

```dart
FlutterTts flutterTts = FlutterTts();

```

To set shared audio [instance](https://developer.apple.com/documentation/avfoundation/avaudiosession/1616504-sharedinstance) (iOS only):

```dart
await flutterTts.setSharedInstance(true);
```

To set audio [category and options](https://developer.apple.com/documentation/avfoundation/avaudiosession) (iOS only):

```dart
await flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playAndRecord, [
      IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      IosTextToSpeechAudioCategoryOptions.mixWithOthers
    ]);
```

To await speak completion.

```dart
await flutterTts.awaitSpeakCompletion(true);
```

### speak, stop, getLanguages, setLanguage, setSpeechRate, setVoice, setVolume, setPitch, isLanguageAvailable, setSharedInstance

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

await flutterTts.setSpeechRate(1.0);

await flutterTts.setVolume(1.0);

await flutterTts.setPitch(1.0);

await flutterTts.isLanguageAvailable("en-US");

// iOS and Web only
await flutterTts.pause();

// iOS, macOS, and Android only
await flutterTts.synthesizeToFile("Hello World", Platform.isAndroid ? "tts.wav" : "tts.caf");

await flutterTts.setVoice({"name": "Karen", "locale": "en-AU"});

// iOS only
await flutterTts.setSharedInstance(true);

// Android only
await flutterTts.setSilence(2);

await flutterTts.getEngines();

await flutterTts.isLanguageInstalled("en-AU");

await flutterTts.areLanguagesInstalled(["en-AU", "en-US"]);

await flutterTts.setQueueMode(1);
```

### Listening for platform calls

```dart
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

flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
  setState(() {
    _currentWord = word;
  });
});

flutterTts.setErrorHandler((msg) {
  setState(() {
    ttsState = TtsState.stopped;
  });
});

flutterTts.setCancelHandler((msg) {
  setState(() {
    ttsState = TtsState.stopped;
  });
});

// iOS and Web
flutterTts.setPauseHandler((msg) {
  setState(() {
    ttsState = TtsState.paused;
  });
});

flutterTts.setContinueHandler((msg) {
  setState(() {
    ttsState = TtsState.continued;
  });
});
```

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.dev/).

For help on editing plugin code, view the [documentation](https://flutter.dev/platform-plugins/#edit-code).
