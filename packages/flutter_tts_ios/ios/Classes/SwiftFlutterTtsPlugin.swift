import AVFoundation
import Flutter
import UIKit

extension FlutterTtsErrorCode {
    func toStrCode() -> String {
        return "FlutterTtsErrorCode.\(rawValue)"
    }
}

let kVoiceSelectionNotSuported = "Voice selection is not supported below iOS 9.0"

/// 带泛型结果类型 R 的 completion 别名
typealias ResultCallback<R> = (Result<R, any Error>) -> Void

public class FlutterTtsPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate, TtsHostApi,
    IosTtsHostApi
{
    let iosAudioCategoryKey = "iosAudioCategoryKey"
    let iosAudioCategoryOptionsKey = "iosAudioCategoryOptionsKey"
    let iosAudioModeKey = "iosAudioModeKey"

    let synthesizer = AVSpeechSynthesizer()
    var rate: Float = AVSpeechUtteranceDefaultSpeechRate
    var volume: Float = 1.0
    var pitch: Float = 1.0
    var voice: AVSpeechSynthesisVoice?
    var awaitSpeakCompletion: Bool = false
    var awaitSynthCompletion: Bool = false
    var autoStopSharedSessionImpl: Bool = true
    var speakResult: ResultCallback<TtsResult>?
    var synthResult: ResultCallback<TtsResult>?

    lazy var audioSession = AVAudioSession.sharedInstance()
    lazy var language: String = AVSpeechSynthesisVoice.currentLanguageCode()

    lazy var languages: Set<String> = Set(AVSpeechSynthesisVoice.speechVoices().map(\.language))

    var flutterApi: TtsFlutterApi
    init(flutterApi: TtsFlutterApi) {
        self.flutterApi = flutterApi
        super.init()
        synthesizer.delegate = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let flutterApi = TtsFlutterApi(binaryMessenger: registrar.messenger())
        let instance = FlutterTtsPlugin(flutterApi: flutterApi)
        TtsHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        IosTtsHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }

    func speak(text: String, forceFocus: Bool, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        speakImpl(text: text, completion: completion)
    }

    func pause(completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        pauseImpl(completion: completion)
    }

    func stop(completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        stopImpl()
        completion(Result.success(TtsResult(success: true)))
    }

    func setSpeechRate(rate: Double, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        setRateImpl(rate: Float(rate))
        completion(Result.success(TtsResult(success: true)))
    }

    func setVolume(volume: Double, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        setVolumeImpl(volume: Float(volume), completion: completion)
    }

    func setPitch(pitch: Double, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        setPitchImpl(pitch: Float(pitch), completion: completion)
    }

    func setVoice(voice: Voice, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        setVoiceImpl(voice: voice, completion: completion)
    }

    func clearVoice(completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        clearVoiceImpl()
        completion(Result.success(TtsResult(success: true)))
    }

    func awaitSpeakCompletion(awaitCompletion: Bool, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        awaitSpeakCompletion = awaitCompletion
        completion(Result.success(TtsResult(success: true)))
    }

    func getLanguages(completion: @escaping (Result<[String], any Error>) -> Void) {
        getLanguagesImpl(completion: completion)
    }

    func getVoices(completion: @escaping (Result<[Voice], any Error>) -> Void) {
        getVoicesImpl(completion: completion)
    }

    func awaitSynthCompletion(awaitCompletion: Bool, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        awaitSynthCompletion = awaitCompletion
        completion(Result.success(TtsResult(success: true)))
    }

    func synthesizeToFile(
        text: String,
        fileName: String,
        isFullPath: Bool,
        completion: @escaping (Result<TtsResult, any Error>) -> Void
    ) {
        synthesizeToFileImpl(text: text, fileName: fileName, isFullPath: isFullPath, completion: completion)
    }

    func setSharedInstance(sharedSession: Bool, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        setSharedInstanceImpl(sharedInstance: sharedSession, completion: completion)
    }

    func autoStopSharedSession(autoStop: Bool, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        autoStopSharedSessionImpl = autoStop
        completion(Result.success(TtsResult(success: true)))
    }

    func setIosAudioCategory(
        category: IosTextToSpeechAudioCategory,
        options: [IosTextToSpeechAudioCategoryOptions],
        mode: IosTextToSpeechAudioMode,
        completion: @escaping (Result<TtsResult, any Error>) -> Void
    ) {
        setAudioCategoryImpl(category: category, audioOptions: options, mode: mode, completion: completion)
    }

    func getSpeechRateValidRange(completion: @escaping (Result<TtsRateValidRange, any Error>) -> Void) {
        getSpeechRateValidRangeImpl(completion: completion)
    }

    func setLanguange(language: String, completion: @escaping (Result<TtsResult, any Error>) -> Void) {
        setLanguageImpl(language: language, completion: completion)
    }

    func isLanguageAvailable(language: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        isLanguageAvailableImpl(language: language, completion: completion)
    }

    private func speakImpl(text: String, completion: @escaping ResultCallback<TtsResult>) {
        if synthesizer.isPaused {
            if synthesizer.continueSpeaking() {
                if awaitSpeakCompletion {
                    speakResult = completion
                } else {
                    completion(Result.success(TtsResult(success: true)))
                }
            } else {
                completion(Result.success(TtsResult(success: false)))
            }
        } else {
            let utterance = AVSpeechUtterance(string: text)
            if voice != nil {
                utterance.voice = voice!
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: language)
            }
            utterance.rate = rate
            utterance.volume = volume
            utterance.pitchMultiplier = pitch

            synthesizer.speak(utterance)
            if awaitSpeakCompletion {
                speakResult = completion
            } else {
                completion(Result.success(TtsResult(success: true)))
            }
        }
    }

    private func synthesizeToFileImpl(
        text: String, fileName: String, isFullPath: Bool,
        completion: @escaping ResultCallback<TtsResult>
    ) {
        var output: AVAudioFile?
        var failed = false
        let utterance = AVSpeechUtterance(string: text)

        if voice != nil {
            utterance.voice = voice!
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }
        utterance.rate = rate
        utterance.volume = volume
        utterance.pitchMultiplier = pitch

        if #available(iOS 13.0, *) {
            self.synthesizer.write(utterance) { (buffer: AVAudioBuffer) in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    NSLog("unknow buffer type: \(buffer)")
                    failed = true
                    return
                }
                print(pcmBuffer.format)
                if pcmBuffer.frameLength == 0 {
                    // finished
                } else {
                    // append buffer to file
                    let fileURL: URL
                    if isFullPath {
                        fileURL = URL(fileURLWithPath: fileName)
                    } else {
                        fileURL = FileManager.default.urls(
                            for: .documentDirectory, in: .userDomainMask
                        ).first!
                            .appendingPathComponent(fileName)
                    }
                    NSLog("Saving utterance to file: \(fileURL.absoluteString)")

                    if output == nil {
                        do {
                            if #available(iOS 17.0, *) {
                                guard
                                    let audioFormat = AVAudioFormat(
                                        commonFormat: .pcmFormatFloat32,
                                        sampleRate: pcmBuffer.format.sampleRate,
                                        channels: 1, interleaved: false
                                    )
                                else {
                                    NSLog("Error creating audio format for iOS 17+")
                                    failed = true
                                    return
                                }
                                output = try AVAudioFile(
                                    forWriting: fileURL, settings: audioFormat.settings
                                )
                            } else {
                                output = try AVAudioFile(
                                    forWriting: fileURL, settings: pcmBuffer.format.settings,
                                    commonFormat: .pcmFormatFloat32, interleaved: false
                                )
                            }
                        } catch {
                            NSLog("Error creating AVAudioFile: \(error.localizedDescription)")
                            failed = true
                            return
                        }
                    }

                    try! output!.write(from: pcmBuffer)
                }
            }
        } else {
            completion(Result.failure(PigeonError(code: FlutterTtsErrorCode.notSupportedOSVersion.toStrCode(),
                                                  message: kVoiceSelectionNotSuported,
                                                  details: nil)))
        }
        if failed {
            completion(Result.success(TtsResult(success: false)))
        }
        if awaitSynthCompletion {
            synthResult = completion
        } else {
            completion(Result.success(TtsResult(success: true)))
        }
    }

    private func pauseImpl(completion: ResultCallback<TtsResult>) {
        if synthesizer.pauseSpeaking(at: AVSpeechBoundary.word) {
            completion(Result.success(TtsResult(success: true)))
        } else {
            completion(Result.success(TtsResult(success: false)))
        }
    }

    private func setLanguageImpl(language: String, completion: ResultCallback<TtsResult>) {
        if !(languages.contains(where: {
            $0.range(of: language, options: [.caseInsensitive, .anchored]) != nil
        })) {
            completion(Result.success(TtsResult(success: false)))
        } else {
            self.language = language
            voice = nil
            completion(Result.success(TtsResult(success: true)))
        }
    }

    private func setRateImpl(rate: Float) {
        self.rate = rate
    }

    private func setVolumeImpl(volume: Float, completion: ResultCallback<TtsResult>) {
        if volume >= 0.0 && volume <= 1.0 {
            self.volume = volume
            completion(Result.success(TtsResult(success: true)))
        } else {
            completion(Result.success(TtsResult(success: false)))
        }
    }

    private func setPitchImpl(pitch: Float, completion: ResultCallback<TtsResult>) {
        if volume >= 0.5 && volume <= 2.0 {
            self.pitch = pitch
            completion(Result.success(TtsResult(success: true)))
        } else {
            completion(Result.success(TtsResult(success: false)))
        }
    }

    private func setSharedInstanceImpl(sharedInstance: Bool, completion: ResultCallback<TtsResult>) {
        do {
            try AVAudioSession.sharedInstance().setActive(sharedInstance)
            completion(Result.success(TtsResult(success: true)))
        } catch {
            completion(Result.success(TtsResult(success: false)))
        }
    }

    private func setAudioCategoryImpl(
        category: IosTextToSpeechAudioCategory,
        audioOptions: [IosTextToSpeechAudioCategoryOptions],
        mode: IosTextToSpeechAudioMode,
        completion: ResultCallback<TtsResult>
    ) {
        let category: AVAudioSession.Category = category.toAVAudioSessionCategory()
        let options: AVAudioSession.CategoryOptions = audioOptions.reduce([]) {
            completion, option -> AVAudioSession.CategoryOptions in
            return completion.union(option.toAVAudioSessionCategoryOptions() ?? [])
        }

        do {
            if #available(iOS 12.0, *) {
                let mode: AVAudioSession.Mode? = mode.toAVAudioSessionMode() ?? AVAudioSession.Mode.default
                try audioSession.setCategory(category, mode: mode!, options: options)
            } else {
                try audioSession.setCategory(category, options: options)
            }
            completion(Result.success(TtsResult(success: true)))
        } catch {
            print(error)
            completion(Result.success(TtsResult(success: false)))
        }
    }

    private func stopImpl() {
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    }

    private func getLanguagesImpl(completion: ResultCallback<[String]>) {
        completion(Result.success(Array(languages)))
    }

    private func getSpeechRateValidRangeImpl(completion: ResultCallback<TtsRateValidRange>) {
        let validSpeechRateRange = TtsRateValidRange(minimum: Double(AVSpeechUtteranceMinimumSpeechRate),
                                                     normal: Double(AVSpeechUtteranceDefaultSpeechRate),
                                                     maximum: Double(AVSpeechUtteranceMaximumSpeechRate),
                                                     platform: TtsPlatform.ios)
        completion(Result.success(validSpeechRateRange))
    }

    private func isLanguageAvailableImpl(language: String, completion: ResultCallback<Bool>) {
        var isAvailable = false
        if languages.contains(where: {
            $0.range(of: language, options: [.caseInsensitive, .anchored]) != nil
        }) {
            isAvailable = true
        }
        completion(Result.success(isAvailable))
    }

    private func getVoicesImpl(completion: ResultCallback<[Voice]>) {
        if #available(iOS 9.0, *) {
            var voices = [Voice]()
            for voice in AVSpeechSynthesisVoice.speechVoices() {
                var gender: String? = nil
                if #available(iOS 13.0, *) {
                    gender = voice.gender.stringValue
                }

                let voiceDict = Voice(name: voice.name,
                                      locale: voice.language,
                                      gender: gender,
                                      quality: voice.quality.stringValue,
                                      identifier: voice.identifier)
                voices.append(voiceDict)
            }
            completion(Result.success(voices))
        } else {
            completion(Result.failure(PigeonError(code: FlutterTtsErrorCode.notSupportedOSVersion.toStrCode(),
                                                  message: kVoiceSelectionNotSuported,
                                                  details: nil)))
        }
    }

    private func setVoiceImpl(voice: Voice, completion: ResultCallback<TtsResult>) {
        if #available(iOS 9.0, *) {
            // Check if identifier exists and is not empty
            if let identifier = voice.identifier, !identifier.isEmpty {
                // Find the voice by identifier
                if let selectedVoice = AVSpeechSynthesisVoice(identifier: identifier) {
                    self.voice = selectedVoice
                    self.language = selectedVoice.language
                    completion(Result.success(TtsResult(success: true)))
                    return
                }
            }

            // If no valid identifier, search by name and locale, then prioritize by quality
            let name = voice.name
            let locale = voice.locale
            let matchingVoices = AVSpeechSynthesisVoice.speechVoices().filter {
                $0.name == name && $0.language == locale
            }

            if !matchingVoices.isEmpty {
                // Sort voices by quality: premium (if available) > enhanced > others
                let sortedVoices = matchingVoices.sorted { voice1, voice2 -> Bool in
                    let quality1 = voice1.quality
                    let quality2 = voice2.quality

                    // macOS 13.0+ supports premium quality
                    if #available(iOS 16.0, *) {
                        if quality1 == .premium {
                            return true
                        } else if quality1 == .enhanced && quality2 != .premium {
                            return true
                        } else {
                            return false
                        }
                    } else {
                        // Fallback for macOS versions before 13.0 (no premium)
                        if quality1 == .enhanced {
                            return true
                        } else {
                            return false
                        }
                    }
                }

                // Select the highest quality voice
                if let selectedVoice = sortedVoices.first {
                    self.voice = selectedVoice
                    self.language = selectedVoice.language
                    completion(Result.success(TtsResult(success: true)))
                    return
                }
            }

            // No matching voice found
            completion(Result.success(TtsResult(success: false)))
        } else {
            completion(Result.failure(PigeonError(code: FlutterTtsErrorCode.notSupportedOSVersion.toStrCode(),
                                                  message: kVoiceSelectionNotSuported,
                                                  details: nil)))
        }
    }

    private func clearVoiceImpl() {
        voice = nil
    }

    private func shouldDeactivateAndNotifyOthers(_ session: AVAudioSession) -> Bool {
        var options: AVAudioSession.CategoryOptions = .duckOthers
        if #available(iOS 9.0, *) {
            options.insert(.interruptSpokenAudioAndMixWithOthers)
        }
        options.remove(.mixWithOthers)

        return !options.isDisjoint(with: session.categoryOptions)
    }

    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
    ) {
        if shouldDeactivateAndNotifyOthers(audioSession) && autoStopSharedSessionImpl {
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print(error)
            }
        }
        if awaitSpeakCompletion && speakResult != nil {
            speakResult!(Result.success(TtsResult(success: true)))
            speakResult = nil
        }
        if awaitSynthCompletion && synthResult != nil {
            synthResult!(Result.success(TtsResult(success: true)))
            synthResult = nil
        }

        flutterApi.onSpeakCompleteCb { _ in }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        flutterApi.onSpeakStartCb { _ in }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        flutterApi.onSpeakPauseCb { _ in }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        flutterApi.onSpeakResumeCb { _ in }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        flutterApi.onSpeakCancelCb { _ in }
    }

    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let nsWord = utterance.speechString as NSString
        let data = TtsProgress(
            text: utterance.speechString,
            start: Int64(characterRange.location),
            end: Int64(characterRange.location + characterRange.length),
            word: nsWord.substring(with: characterRange)
        )

        flutterApi.onSpeakProgressCb(progress: data) { _ in }
    }
}

extension AVSpeechSynthesisVoiceQuality {
    var stringValue: String {
        switch self {
        case .default:
            return "default"
        case .premium:
            return "premium"
        case .enhanced:
            return "enhanced"
        }
    }
}

@available(iOS 13.0, *)
extension AVSpeechSynthesisVoiceGender {
    var stringValue: String {
        switch self {
        case .male:
            return "male"
        case .female:
            return "female"
        case .unspecified:
            return "unspecified"
        }
    }
}
