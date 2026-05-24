import AVFoundation

enum AudioCategory: String {
  case iosAudioCategoryAmbientSolo
  case iosAudioCategoryAmbient
  case iosAudioCategoryPlayback
  case iosAudioCategoryPlaybackAndRecord
  
  func toAVAudioSessionCategory() -> AVAudioSession.Category {
    switch self {
    case .iosAudioCategoryAmbientSolo:
      return .soloAmbient
    case .iosAudioCategoryAmbient:
      return .ambient
    case .iosAudioCategoryPlayback:
      return .playback
    case .iosAudioCategoryPlaybackAndRecord:
      return .playAndRecord
    }
  }
}
