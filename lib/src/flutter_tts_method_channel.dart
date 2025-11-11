import 'package:flutter/foundation.dart';
import 'package:flutter_tts/src/flutter_tts_platform_interface.dart';
import 'package:flutter_tts/src/messages.g.dart';
import 'package:multiple_result/multiple_result.dart';

class FlutterTtsMethodChannel extends FlutterTtsPlatform
    implements TtsFlutterApi {
  @protected
  final TtsHostApi hostApi = TtsHostApi();

  FlutterTtsMethodChannel() {
    TtsFlutterApi.setUp(this);
  }

  @override
  Future<ResultDart<TtsResult>> awaitSpeakCompletion(
    bool awaitCompletion,
  ) async {
    try {
      return Result.success(
        await hostApi.awaitSpeakCompletion(awaitCompletion),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> clearVoice() async {
    try {
      return Result.success(await hostApi.clearVoice());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<List<String>>> getLanguages() async {
    try {
      return Result.success(await hostApi.getLanguages());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<List<Voice>>> getVoices() async {
    try {
      return Result.success(await hostApi.getVoices());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> pause() async {
    try {
      return Result.success(await hostApi.pause());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> setPitch(double pitch) async {
    try {
      return Result.success(await hostApi.setPitch(pitch));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> setSpeechRate(double rate) async {
    try {
      return Result.success(await hostApi.setSpeechRate(rate));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> setVoice(Voice voice) async {
    try {
      return Result.success(await hostApi.setVoice(voice));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> setVolume(double volume) async {
    try {
      return Result.success(await hostApi.setVolume(volume));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> speak(String text, {bool focus = false}) async {
    try {
      return Result.success(await hostApi.speak(text, focus));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> stop() async {
    try {
      return Result.success(await hostApi.stop());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  void onSpeakCancelCb() {
    onSpeakCancel?.call();
  }

  @override
  void onSpeakCompleteCb() {
    onSpeakComplete?.call();
  }

  @override
  void onSpeakResumeCb() {
    onSpeakResume?.call();
  }

  @override
  void onSpeakErrorCb(String error) {
    onSpeakError?.call(error);
  }

  @override
  void onSpeakPauseCb() {
    onSpeakPause?.call();
  }

  @override
  void onSpeakProgressCb(TtsProgress progress) {
    onSpeakProgress?.call(progress);
  }

  @override
  void onSpeakStartCb() {
    onSpeakStart?.call();
  }

  @override
  void onSynthCompleteCb() {
    onSynthComplete?.call();
  }

  @override
  void onSynthErrorCb(String error) {
    onSynthError?.call(error);
  }

  @override
  void onSynthStartCb() {
    onSynthStart?.call();
  }
}
