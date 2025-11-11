import AVFoundation

extension IosTextToSpeechAudioCategory {
    func toAVAudioSessionCategory() -> AVAudioSession.Category {
        switch self {
        case IosTextToSpeechAudioCategory.ambientSolo:
            return .soloAmbient
        case IosTextToSpeechAudioCategory.ambient:
            return .ambient
        case IosTextToSpeechAudioCategory.playback:
            return .playback
        case IosTextToSpeechAudioCategory.playAndRecord:
            return .playAndRecord
        }
    }
}
