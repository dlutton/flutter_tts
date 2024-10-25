import FlutterMacOS
import Foundation
import AVFoundation

public class FlutterTtsPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  final var iosAudioCategoryKey = "iosAudioCategoryKey"
  final var iosAudioCategoryOptionsKey = "iosAudioCategoryOptionsKey"
  
  let synthesizer = AVSpeechSynthesizer()
  var language: String = AVSpeechSynthesisVoice.currentLanguageCode()
  var rate: Float = AVSpeechUtteranceDefaultSpeechRate
  var languages = Set<String>()
  var volume: Float = 1.0
  var pitch: Float = 1.0
  var voice: AVSpeechSynthesisVoice?
  var awaitSpeakCompletion: Bool = false
  var awaitSynthCompletion: Bool = false
  var speakResult: FlutterResult!
  var synthResult: FlutterResult!

  var channel = FlutterMethodChannel()
  init(channel: FlutterMethodChannel) {
    super.init()
    self.channel = channel
    synthesizer.delegate = self
    setLanguages()
  }

  private func setLanguages() {
    for voice in AVSpeechSynthesisVoice.speechVoices(){
      self.languages.insert(voice.language)
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_tts", binaryMessenger: registrar.messenger)
    let instance = FlutterTtsPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      let text: String = call.arguments as! String
      self.speak(text: text, result: result)
      break
    case "awaitSpeakCompletion":
      self.awaitSpeakCompletion = call.arguments as! Bool
      result(1)
      break
    case "awaitSynthCompletion":
      self.awaitSynthCompletion = call.arguments as! Bool
      result(1)
      break
    case "synthesizeToFile":
      guard let args = call.arguments as? [String: Any] else {
        result("iOS could not recognize flutter arguments in method: (sendParams)")
        return
      }
      let text = args["text"] as! String
      let fileName = args["fileName"] as! String
      self.synthesizeToFile(text: text, fileName: fileName, result: result)
      break
    case "pause":
      self.pause(result: result)
      break
    case "setLanguage":
      let language: String = call.arguments as! String
      self.setLanguage(language: language, result: result)
      break
    case "setSpeechRate":
      let rate: Double = call.arguments as! Double
      self.setRate(rate: Float(rate))
      result(1)
      break
    case "setVolume":
      let volume: Double = call.arguments as! Double
      self.setVolume(volume: Float(volume), result: result)
      break
    case "setPitch":
      let pitch: Double = call.arguments as! Double
      self.setPitch(pitch: Float(pitch), result: result)
      break
    case "stop":
      self.stop()
      result(1)
      break
    case "getLanguages":
      self.getLanguages(result: result)
      break
    case "getSpeechRateValidRange":
      self.getSpeechRateValidRange(result: result)
      break
    case "isLanguageAvailable":
      let language: String = call.arguments as! String
      self.isLanguageAvailable(language: language, result: result)
      break
    case "getVoices":
      self.getVoices(result: result)
      break
    case "setVoice":
      guard let args = call.arguments as? [String: String] else {
        result("iOS could not recognize flutter arguments in method: (sendParams)")
        return
      }
      self.setVoice(voice: args, result: result)
      break
    case "autoStopSharedSession":
      // MacOS does not have a shared audio session so just accept the call
      result(1)
      break
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func speak(text: String, result: @escaping FlutterResult) {
    if (self.synthesizer.isPaused) {
      if (self.synthesizer.continueSpeaking()) {
        if self.awaitSpeakCompletion {
          self.speakResult = result
        } else {
          result(1)
        }
      } else {
        result(0)
      }
    } else {
      let utterance = AVSpeechUtterance(string: text)
      if self.voice != nil {
        utterance.voice = self.voice!
      } else {
        utterance.voice = AVSpeechSynthesisVoice(language: self.language)
      }
      utterance.rate = self.rate
      utterance.volume = self.volume
      utterance.pitchMultiplier = self.pitch
      
      self.synthesizer.speak(utterance)
      if self.awaitSpeakCompletion {
        self.speakResult = result
      } else {
        result(1)
      }
    }
  }
  
  private func synthesizeToFile(text: String, fileName: String, result: @escaping FlutterResult) {
    var output: AVAudioFile?
    var failed = false
    let utterance = AVSpeechUtterance(string: text)

    if #available(iOS 13.0, *) {
      self.synthesizer.write(utterance) { (buffer: AVAudioBuffer) in
        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
            NSLog("unknow buffer type: \(buffer)")
            failed = true
            return
        }
        if pcmBuffer.frameLength == 0 {
            // finished
        } else {
          // append buffer to file
          let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
          NSLog("Saving utterance to file: \(fileURL.absoluteString)")
            
          if output == nil {
            do {
              output = try AVAudioFile(
              forWriting: fileURL,
              settings: pcmBuffer.format.settings, 
              commonFormat: .pcmFormatFloat32,
              interleaved: false)
            } catch {
                NSLog(error.localizedDescription)
                failed = true
                return
            }
          }
            
          try! output!.write(from: pcmBuffer)
        }
      }
    } else {
        result("Unsupported iOS version")
    }
    if failed {
        result(0)
    }
    if self.awaitSynthCompletion {
      self.synthResult = result
    } else {
      result(1)
    }
  }

  private func pause(result: FlutterResult) {
      if (self.synthesizer.pauseSpeaking(at: AVSpeechBoundary.word)) {
        result(1)
      } else {
        result(0)
      }
  }

  private func setLanguage(language: String, result: FlutterResult) {
    if !(self.languages.contains(where: {$0.range(of: language, options: [.caseInsensitive, .anchored]) != nil})) {
      result(0)
    } else {
      self.language = language
      self.voice = nil
      result(1)
    }
  }

  private func setRate(rate: Float) {
    self.rate = rate
  }

  private func setVolume(volume: Float, result: FlutterResult) {
    if (volume >= 0.0 && volume <= 1.0) {
      self.volume = volume
      result(1)
    } else {
      result(0)
    }
  }

  private func setPitch(pitch: Float, result: FlutterResult) {
    if (volume >= 0.5 && volume <= 2.0) {
      self.pitch = pitch
      result(1)
    } else {
      result(0)
    }
  }
    
  private func stop() {
    self.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
  }

  private func getLanguages(result: FlutterResult) {
    result(Array(self.languages))
  }

  private func getSpeechRateValidRange(result: FlutterResult) {
    let validSpeechRateRange: [String:String] = [
      "min": String(AVSpeechUtteranceMinimumSpeechRate),
      "normal": String(AVSpeechUtteranceDefaultSpeechRate),
      "max": String(AVSpeechUtteranceMaximumSpeechRate),
      "platform": "ios"
    ]
    result(validSpeechRateRange)
  }

  private func isLanguageAvailable(language: String, result: FlutterResult) {
    var isAvailable: Bool = false
    if (self.languages.contains(where: {$0.range(of: language, options: [.caseInsensitive, .anchored]) != nil})) {
      isAvailable = true
    }
    result(isAvailable);
  }

  private func getVoices(result: FlutterResult) {
    if #available(macOS 10.15, *) {
      let voices = NSMutableArray()
      var voiceDict: [String: String] = [:]
      for voice in AVSpeechSynthesisVoice.speechVoices() {
        voiceDict["name"] = voice.name
        voiceDict["locale"] = voice.language
        voiceDict["quality"] = voice.quality.stringValue
        if #available(macOS 10.15, *) {
          voiceDict["gender"] = voice.gender.stringValue
        }
        voiceDict["identifier"] = voice.identifier
        voices.add(voiceDict)
      }
      result(voices)
    } else {
      // Since voice selection is not supported below iOS 9, make voice getter and setter
      // have the same bahavior as language selection.
      getLanguages(result: result)
    }
  }



  private func setVoice(voice: [String: String], result: FlutterResult) {
      if #available(iOS 9.0, *) {
          // Check if identifier exists and is not empty
          if let identifier = voice["identifier"], !identifier.isEmpty {
              // Find the voice by identifier
              if let selectedVoice = AVSpeechSynthesisVoice(identifier: identifier) {
                  self.voice = selectedVoice
                  self.language = selectedVoice.language
                  result(1)
                  return
              }
          }
          
          // If no valid identifier, search by name and locale, then prioritize by quality
          if let name = voice["name"], let locale = voice["locale"] {
              let matchingVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.name == name && $0.language == locale }
              
              if !matchingVoices.isEmpty {
                  // Sort voices by quality: premium (if available) > enhanced > others
                  let sortedVoices = matchingVoices.sorted { (voice1, voice2) -> Bool in
                      let quality1 = voice1.quality
                      let quality2 = voice2.quality
                      
                      // macOS 13.0+ supports premium quality
                      if #available(macOS 13.0, *) {
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
                      result(1)
                      return
                  }
              }
          }
          
          // No matching voice found
          result(0)
      } else {
          // Handle older iOS versions if needed
          setLanguage(language: voice["name"]!, result: result)
      }
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    if self.awaitSpeakCompletion {
      self.speakResult(1)
    }
    if self.awaitSynthCompletion {
      self.synthResult(1)
    }
    self.channel.invokeMethod("speak.onComplete", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onStart", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onPause", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onContinue", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onCancel", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    let nsWord = utterance.speechString as NSString
    let data: [String:String] = [
      "text": utterance.speechString,
      "start": String(characterRange.location),
      "end": String(characterRange.location + characterRange.length),
      "word": nsWord.substring(with: characterRange)
    ]
    self.channel.invokeMethod("speak.onProgress", arguments: data)
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

@available(macOS 10.15, *)
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
