# ChangeLog

## 0.9.2

- iOS: Changing audio session to playAndRecord

## 0.9.1

- Android: Fixing method call error

## 0.9.0

- Android: Adding synthesize to file

## 0.8.7

- Android: Fix sporadic ANR on initialization

## 0.8.6

- iOS: Reducing volume of other sessions while TTS is playing

## 0.8.5

- Android: Fix Android async platform initialization
- Android: Removing initHandler

## 0.8.2

- Web: Adding isLanguageAvailable method
- All: Fixing isLanguageAvailable platform channel and making it case insensitive

## 0.8.0

- Web: Adding Web Support

## 0.7.0

- iOS: Adding Swift version 4.2 to podspec and correct audio playback category

## 0.6.0

- Android: AndroidX support

## 0.5.2

- Android: Bug Fix on isLanguageAvailable

## 0.5.1

- Applying flutter format to fix health suggestion

## 0.5.0

- Android: Adding silence before speak
- Android: Removing deprecated API

## 0.2.6

- IOS: Add voice selection implementation

## 0.2.5

- Android: Ensure invokeMethod runs on main thread

## 0.2.4

- Android: setting minSDK back to 21 and adding instructions to readme
- Android: Adding fallback for getLanguages and defaultLanguage

## 0.2.3

- IOS: Audio continues with the Ring/Silent switch set to silent

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
