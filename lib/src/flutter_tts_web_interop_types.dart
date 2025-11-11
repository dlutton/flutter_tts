import 'dart:js_interop';

@JS('speechSynthesis')
external SpeechSynthesis get synth;

@JS()
extension type SpeechSynthesis._(JSObject _) implements JSObject {
  external void cancel();

  external JSArray<SpeechSynthesisVoice> getVoices();

  external void pause();

  external void resume();

  external void speak(SpeechSynthesisUtterance utterance);
}

@JS()
extension type SpeechSynthesisUtterance._(JSObject _) implements JSObject {
  external SpeechSynthesisUtterance();

  external String lang;

  external double pitch;

  external double rate;

  external String text;

  external SpeechSynthesisVoice? voice;

  external double volume;

  // Event listeners

  @JS('onstart')
  external set onStart(JSFunction listener);

  @JS('onend')
  external set onEnd(JSFunction listener);

  @JS('onpause')
  external set onPause(JSFunction listener);

  @JS('onresume')
  external set onResume(JSFunction listener);

  @JS('onerror')
  external set onError(JSFunction listener);

  @JS('onboundary')
  external set onBoundary(JSFunction listener);
}

@JS()
extension type SpeechSynthesisVoice._(JSObject _) implements JSObject {
  @JS('default')
  external bool get isDefault;

  external String get lang;

  @JS('localService')
  external bool get isLocalService;

  external String get name;
}
