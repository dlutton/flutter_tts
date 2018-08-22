import Flutter
import UIKit
import AVFoundation
    
public class SwiftFlutterTtsPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  let synthesizer = AVSpeechSynthesizer()
  var language: String = AVSpeechSynthesisVoice.currentLanguageCode() 
  var rate: Float = AVSpeechUtteranceDefaultSpeechRate
  var languages: [String] = []
  var volume: Float = 1.0
  var pitch: Float = 1.0

  var channel = FlutterMethodChannel()
    
  init(channel: FlutterMethodChannel) {
    super.init()
    self.channel = channel
    synthesizer.delegate = self
    setLanguages()
  }

  private func setLanguages() {
    for voice in (AVSpeechSynthesisVoice.speechVoices()){
      self.languages.append(voice.language)
    }
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
    case "isLanguageAvailable":
      let arg: Dictionary<String, String> = call.arguments as! Dictionary<String, String>
      self.isLanguageAvailable(language: arg["language"]! as String, result: result)
      break
    default: 
      result(FlutterMethodNotImplemented)
    }
  }

  private func speak(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: self.language)
    utterance.rate = self.rate
    utterance.volume = self.volume 
    utterance.pitchMultiplier = self.pitch 

    self.synthesizer.speak(utterance)
  }

  private func setLanguage(language: String, result: FlutterResult) {
    if !(self.languages.contains(language)) {
      result(0)
    } else {
      self.language = language
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
    result(self.languages)
  }

  private func isLanguageAvailable(language: String, result: FlutterResult) {
    var isAvailable: Bool = false
    if (self.languages.contains(language)) {
      isAvailable = true
    }
    result(isAvailable);
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onComplete", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onStart", arguments: nil)
  }

}
