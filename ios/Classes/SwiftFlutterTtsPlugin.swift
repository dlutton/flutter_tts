import Flutter
import UIKit
import AVFoundation
    
public class SwiftFlutterTtsPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  let synthesizer = AVSpeechSynthesizer()
  var language: String = AVSpeechSynthesisVoice.currentLanguageCode() 
  var rate: Float = AVSpeechUtteranceDefaultSpeechRate

  var channel = FlutterMethodChannel()
    
  init(channel: FlutterMethodChannel) {
    super.init()
    self.channel = channel
    synthesizer.delegate = self
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_tts", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterTtsPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      let text: String = call.arguments as! String
      self.speak(text: text)
      result(1)
      break
    case "setLanguage":
      let language: String = call.arguments as! String
      self.setLanguage(language: language, result: result)
      break
    case "setRate":
      let rate: Double = call.arguments as! Double
      self.setRate(rate: Float(rate))
      result(1)
      break
    case "stop":
      self.stop()
      result(1)
      break
    case "getLanguages":
      self.getLanguages(result: result)
      break
    default: 
      result(FlutterMethodNotImplemented)
    }
  }

  private func speak(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: self.language)
    utterance.rate = self.rate

    self.synthesizer.speak(utterance)
  }

  private func setLanguage(language: String, result: FlutterResult) {
    var voices: [String] = []
    for voice in (AVSpeechSynthesisVoice.speechVoices()){
      voices.append(voice.language)
    }
    if !(voices.contains(language)){
      self.channel.invokeMethod("speak.onError", arguments: "Invalid language code - \(language)")
      result(0)
    } else {
      self.language = language
      result(1)
    }
  }

  private func setRate(rate: Float) {
    self.rate = rate
  }

  private func stop() {
    self.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
  }

  private func getLanguages(result: FlutterResult) {
    var voices: [String] = []
    for voice in (AVSpeechSynthesisVoice.speechVoices()){
        voices.append(voice.language)
    }
    result(voices)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onComplete", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onStart", arguments: nil)
  }

}
