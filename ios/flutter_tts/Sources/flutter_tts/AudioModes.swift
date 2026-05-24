import AVFoundation

enum AudioModes: String {
  case iosAudioModeDefault
  case iosAudioModeGameChat
  case iosAudioModeMeasurement
  case iosAudioModeMoviePlayback
  case iosAudioModeSpokenAudio
  case iosAudioModeVideoChat
  case iosAudioModeVideoRecording
  case iosAudioModeVoiceChat
  case iosAudioModeVoicePrompt

  func toAVAudioSessionMode() -> AVAudioSession.Mode? {
    switch self {
    case .iosAudioModeDefault:
      if #available(iOS 12.0, *) {
          return .default
      }
      return nil
    case .iosAudioModeGameChat:
        if #available(iOS 12.0, *) {
            return .gameChat
        }
        return nil
    case .iosAudioModeMeasurement:
        if #available(iOS 12.0, *) {
            return .measurement
        }
        return nil
    case .iosAudioModeMoviePlayback:
        if #available(iOS 12.0, *) {
            return .moviePlayback
        }
        return nil
    case .iosAudioModeSpokenAudio:
        if #available(iOS 12.0, *) {
            return .spokenAudio
        }
        return nil
    case .iosAudioModeVideoChat:
        if #available(iOS 12.0, *) {
            return .videoChat
        }
        return nil
    case .iosAudioModeVideoRecording:
        if #available(iOS 12.0, *) {
            return .videoRecording
        }
        return nil
    case .iosAudioModeVoiceChat:
        if #available(iOS 12.0, *) {
            return .voiceChat
        }
        return nil
    case .iosAudioModeVoicePrompt:
        if #available(iOS 12.0, *) {
            return .voicePrompt
        }
        return nil
    }
  }
}
