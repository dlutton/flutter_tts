# ChangeLog

## 4.2.3

### Fixes

- **Android:** Fix TTS reconnection behaviors
- **Windows:** Replace deprecated exec_program with execute_process
- **Windows:** Fix error on MSVC compilers

## 4.2.2

### Fixes

- **Web:** Fixing setLanguage on iOS browsers

## 4.2.1

### Fixes

- **iOS:** speeding up iOS plugin initialization
- **Android:** Fixes npe on plugin initialization

## 4.2.0

### Features

- **Windows:** Added extra metadata for voices
- **Web:** Added progress events using onboundary

## 4.1.0

### Fixes

- **Windows:** Fixes setvoices
- **iOS:** Fixes exported audio having the wrong sampleRate on ios 18
- **Android:** Fixes 'Reply already submitted' bug during synthesizeToFile

### Features

- **Android:** Added AudioFocus and Audio Attributes For Navigation
- **Android/iOS/macOS:** Added extra metadata for voices
- **Web:** Migrated js_interop to support WASM
- **Android/iOS:** Improving synthesizeToFile

## 4.0.2

### Fixes

- **Package:** using recommended static analysis and fixing issues from analyze
- **Package:** Upating android example to use declarative plugins block

## 4.0.1

### Fixes

- **Android:** Fixing synthesizeToFile

## 4.0.0

### Features

- **iOS:** Add clear selected voice
- **Android:** Add clear selected voice
- **Android:** Upgrade to Kotlin 1.9.10
- **Android:** Upgrade Gradle to 8.2.0
- **Android:** Change compileSDK target to 34

### Fixes

- **Android:** Fix TTS initialization (removed setInitHandler)
- **Web:** Fix pause
- **Package:** Fix describeEnum deprecation (requires Flutter SDK >=2.15.0)
- **Package:** Remove unnecessary foundation.dart include

## 3.8.5

### Fixes

- **iOS:** Fix AVSpeechSynthesisVoiceGender with available on iOS 13 or greater

## 3.8.4

- **Android:** Fix 'Reply already submitted' bug
- **iOS:** Return additional voice information fields (quality, gender, and identifier)
- **iOS:** Fix synthesizeToFile on iOS 17+

## 3.8.3

### Fixes

- **Android:** Clear pending method calls on initialization

## 3.8.2

### Fixes

- **Web:** Fixing onError to prevent crashing

## 3.8.1

- **iOS:** Fixing fileName type back to URL

## 3.8.0

### Features

- *iOS/Android:** Support relative path of synthesization audio file
- **Android:** Improved android manifest notice
- **Android:** Removed deprecated registerWith
- **iOS:** Improved iOS audio documentation

### Fixes

- **Android:** Set speaking and synth to false in the stop method
- **Web:** Fix error in check available language without locale (country)

## 3.7.0

### Features

- **iOS:** add option to disable the auto stop for the audio session after speech completion
- **Android:** Upgrade gradle and kotlin. Make project compatible with AGP 8

### Fixes

- **Web:** Add try-catch on initializing web plugin.
- **iOS:** Support project import fallback if the generated compatibility header is not copied when this plugin is created as a library.

## 3.6.3

- **Android:** fixed initHandler with setEngineInitHandler
- **Android:** refactored pause work around which fixed a couple of reports bugs

## 3.6.2

- **Android:** setEngine - adding initHandler within the method

## 3.6.1

### Fixes

- **Android:** setEngine initialization bug

### Features

- **Android:** added initHandler for android to help with engine initialization

## 3.6.0

### Features

- **Android:** Adding pause/continue
- **Windows:** Adding callbacks

### Fixes

- **All:** Adding async/await to Channel invokeMethods

## 3.5.3

### Features

- **Android:** Adding getDefaultVoice

## 3.5.2

### Updates

- **Android:** Converting Java to Kotlin and package upgrades

## 3.5.1

### Fixes

- **Web:** Fixing late variable and updating value being passed through a message channel to a primitive type

## 3.5.0

### Features

- **Web:** - Adding setVoice support

### Fixes

- **Web:** Fix chrome bug

## 3.4.0

### Features

- **Windows:** - Adding Windows Support

## 3.3.3

### Fixes

- **iOS:** Fix synthesizeToFile fatal error

## 3.3.2

### Fixes

- **Android:** Fix build.gradle missing property

## 3.3.1

### Fixes

- **Web:** Fix awaitSpeakCompletion

## 3.3.0

### Features

- **iOS:** Adding support for AVAudioSession.Mode

## 3.2.4

### Fixes

- **Android:** Fix compileSDK version

## 3.2.3

### Fixes

- **Android:** Fix await speak completion when queue mode is set to 1

## 3.2.2

### Fixes

- **Android:** Android 11 fix

## 3.2.1

### Fixes

- **Android:** Fix deprecation warning

## 3.2.0

### Features

- **Android:** Adding get max speech input length
- **Android:** Changed Android speed rate mapping
- **iOS/macOS/Android:** Adding awaitSynthCompletion for synthesize to file

### Fixes

- **Android:** Fix tts connection disconnection after long running time

## 3.1.0

### Features

- **Android:** Adding set engine and get default engine

## 3.0.0

### Features

- Adding null safety

## 2.1.0

### Features

- **Android:** Adding the ability to set the queue mode

## 2.0.0

### Features

- **Android:** Adding installed language check

### BREAKING CHANGES

- **iOS/Android:** Adding voice name and locale to voice methods

## 1.3.0

- All: Adding await speak completion

## 1.2.7

- iOS: Adding utterance settings to synthesizeToFile
- Android: Fix crash when utterance completes after Engine is detached

## 1.2.6

- Android: Fixing new API onAttachedToEngine call

## 1.2.5

- macOS: Adding support

## 1.2.4

- iOS: Deactivate audio session only when needed
- Android:  Better exception handling for getLanguages
- Android:  Adding getEngines
- Android:  Adding new Android plugin APIs

## 1.2.3

- iOS: Adding synthesize to file
- iOS: Fix set category ios

## 1.2.2

- Web: Adding pause and continue

## 1.2.1

- iOS: Fix setting iOS Category
- iOS/Android: Adding additional platform calls

## 1.2.0

- iOS: Adding Set Audio Session Category
- Android: Bug fixes

## 1.1.0

- iOS: Adding Pause
- iOS: Adding set Shared Instance

## 1.0.0

- iOS/Android: Feature - Speech marks
- iOS/Android: Breaking changes to Speech rate

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
