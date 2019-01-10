# ChangeLog

## 0.2.2
- Android: Fixing Locale bug

## 0.2.1
- IOS: Fixing getLanguages bug

## 0.2.0

- Android: Adding exception catch for samsung devices
- Android: Using default com.google.android.tts engine
- Android: Get and Set Voice
- Android: InitHandler 
- Cleaning up the example

## 0.1.2

- Support for Android background execution
- Updating Android build gradle version to 3.2.1

## 0.1.1

- Fixing TTS bound error in the example
- Fixing default voice language not found error on Android

## 0.1.0

- Updating version for improved maintenance score
- Updating package description for improved maintenance score

## 0.0.8

- Adding analysis_options.yaml for improved health score
- Fixing info/errors from flutter analyze

## 0.0.7

- Updating SDK version in pubspec.yaml
- Adding package link to README
- Fixing language string warning received from xcode

## 0.0.6

- Android: Upgrading Gradle 4.1 to 4.4
- Android: Setting minSdk version to 21
- Android: Adding try/catch to getAvailableLanguages & getDefaultVoice methods (Issues with API 21 & 22)

## 0.0.5

- Adding IOS/Android isLanguageAvailable
- Rename setRate to setSpeechRate

## 0.0.4

- Simplify podspec for Cocoapods 1.5.0

## 0.0.3

- Adding IOS/Android speech pitch and volume

## 0.0.2

- Flutter formatting and fixing pubspec sdk versioning

## 0.0.1

- first POC :
  - methods : speak, stop, setRate, setLangauge, getLanguages
  - a globalHandler for completion