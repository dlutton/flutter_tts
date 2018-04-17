import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef void ErrorHandler(String message);

class FlutterTts {
  static const MethodChannel _channel = const MethodChannel('flutter_tts');

  VoidCallback startHandler;
  VoidCallback completionHandler;
  ErrorHandler errorHandler;

  FlutterTts() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  Future<dynamic> speak(String text) => _channel.invokeMethod('speak', text);

  Future<dynamic> setLanguage(String language) =>
      _channel.invokeMethod('setLanguage', language);

  Future<dynamic> setRate(double rate) =>
      _channel.invokeMethod('setRate', rate);

  Future<dynamic> setVolume(double volume) =>
      _channel.invokeMethod('setVolume', volume);

  Future<dynamic> setPitch(double pitch) =>
      _channel.invokeMethod('setPitch', pitch);

  Future<dynamic> stop() => _channel.invokeMethod('stop');

  Future<dynamic> pause() => _channel.invokeMethod('pause');

  Future<List<dynamic>> get getLanguages async {
    final List<dynamic> languages = await _channel.invokeMethod('getLanguages');
    return languages;
  }

  void setStartHandler(VoidCallback callback) {
    startHandler = callback;
  }

  void setCompletionHandler(VoidCallback callback) {
    completionHandler = callback;
  }

  void setErrorHandler(ErrorHandler handler) {
    errorHandler = handler;
  }

  Future platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "speak.onStart":
        if (startHandler != null) {
          startHandler();
        }
        break;
      case "speak.onComplete":
        if (completionHandler != null) {
          completionHandler();
        }
        break;
      case "speak.onError":
        if (errorHandler != null) {
          errorHandler(call.arguments);
        }
        break;
      default:
        print('Unknowm method ${call.method}');
    }
  }
}
