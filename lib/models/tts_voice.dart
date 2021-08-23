/// {@template tts_voice}
/// Represents a wapper around Android's Voice class and
/// Swift's AVSpeechSynthesisVoice class.
///
/// It exposes basic information about the underlying classes like the name,
/// locale and gender of the synthetic voice.
///
/// {@endtemplate}
class TTSVoice {
  /// {@macro tts_voice}
  const TTSVoice({
    required this.name,
    required this.locale,
    required this.gender,
  });

  TTSVoice.fromMap(Map map)
      : this.name = map['name']!.toString(),
        this.locale = map['locale']!.toString(),
        this.gender = TTSVoiceGenderFromString.fromString(
          map['gender']!.toString(),
        );

  /// The tts_voice's name.
  final String name;

  /// The tts_voice's locale.
  final String locale;

  /// The tts_voice's gender.
  final TTSVoiceGender gender;
}

enum TTSVoiceGender {
  male,
  female,
  unspecified,
}

extension TTSVoiceGenderFromString on TTSVoiceGender {
  static TTSVoiceGender fromString(String value) {
    switch (value) {
      case "female":
        return TTSVoiceGender.female;

      case "male":
        return TTSVoiceGender.male;

      default:
        return TTSVoiceGender.unspecified;
    }
  }

  /// Helper to determine if value is male.
  bool get isMale => this == TTSVoiceGender.male;

  /// Helper to determine if value is female.
  bool get isFemale => this == TTSVoiceGender.female;

  /// Helper to determine if value is unspecified.
  bool get isUnspecified => this == TTSVoiceGender.unspecified;
}
