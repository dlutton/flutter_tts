import AVFoundation

extension IosTextToSpeechAudioCategoryOptions {
    func toAVAudioSessionCategoryOptions() -> AVAudioSession.CategoryOptions? {
        switch self {
        case IosTextToSpeechAudioCategoryOptions.mixWithOthers:
            return .mixWithOthers
        case IosTextToSpeechAudioCategoryOptions.duckOthers:
            return .duckOthers
        case IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers:
            if #available(iOS 9.0, *) {
                return .interruptSpokenAudioAndMixWithOthers
            } else {
                return nil
            }
        case IosTextToSpeechAudioCategoryOptions.allowBluetooth:
            return .allowBluetoothHFP
        case IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP:
            return .allowBluetoothA2DP
        case IosTextToSpeechAudioCategoryOptions.allowAirPlay:
            if #available(iOS 10.0, *) {
                return .allowBluetoothA2DP
            } else {
                return nil
            }
        case IosTextToSpeechAudioCategoryOptions.defaultToSpeaker:
            return .defaultToSpeaker
        }
    }
}
