import AVFoundation

extension IosTextToSpeechAudioMode {
    func toAVAudioSessionMode() -> AVAudioSession.Mode? {
        switch self {
        case IosTextToSpeechAudioMode.defaultMode:
            if #available(iOS 12.0, *) {
                return .default
            }
            return nil
        case IosTextToSpeechAudioMode.gameChat:
            if #available(iOS 12.0, *) {
                return .gameChat
            }
            return nil
        case IosTextToSpeechAudioMode.measurement:
                if #available(iOS 12.0, *) {
                    return .measurement
                }
                return nil
        case IosTextToSpeechAudioMode.moviePlayback:
                if #available(iOS 12.0, *) {
                    return .moviePlayback
                }
                return nil
        case IosTextToSpeechAudioMode.spokenAudio:
                if #available(iOS 12.0, *) {
                    return .spokenAudio
                }
                return nil
        case IosTextToSpeechAudioMode.videoChat:
                if #available(iOS 12.0, *) {
                    return .videoChat
                }
                return nil
        case IosTextToSpeechAudioMode.videoRecording:
                if #available(iOS 12.0, *) {
                    return .videoRecording
                }
                return nil
        case IosTextToSpeechAudioMode.voiceChat:
                if #available(iOS 12.0, *) {
                    return .voiceChat
                }
                return nil
        case IosTextToSpeechAudioMode.voicePrompt:
            if #available(iOS 12.0, *) {
                return .voicePrompt
            }
            return nil
        }
    }
}
