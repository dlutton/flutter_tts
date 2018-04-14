package com.eyedeadevelopers.fluttertts;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.app.Activity;
import android.util.Log;
import android.os.Bundle;

import java.util.Locale;
import java.util.ArrayList;
import java.util.UUID;
import java.lang.Float;
/**
 * FlutterTtsPlugin
 */
public class FlutterTtsPlugin implements MethodCallHandler {
  private final MethodChannel channel;
  private final Activity activity;
  private TextToSpeech tts;
  String uuid;

  /**
   * Plugin registration.
   */
  private FlutterTtsPlugin(Activity activity, MethodChannel channel) {
    this.activity = activity;
    this.channel = channel;
    this.channel.setMethodCallHandler(this);

    tts = new TextToSpeech(activity.getApplicationContext(), onInitListener);
    uuid = UUID.randomUUID().toString();
  };

  private UtteranceProgressListener utteranceProgressListener = new UtteranceProgressListener() {
    @Override
    public void onStart(String utteranceId) {
      channel.invokeMethod("speak.onStart", true);
    }

    @Override
    public void onDone(String utteranceId) {
      channel.invokeMethod("speak.onComplete", true);
    }

    @Override
    @Deprecated
    public void onError(String utteranceId) {
      channel.invokeMethod("speak.onError", "Error from TextToSpeech");
    }

    @Override
    public void onError(String utteranceId, int errorCode) {
      channel.invokeMethod("speak.onError", "Error from TextToSpeech - " + errorCode);
    }

  };

  private TextToSpeech.OnInitListener onInitListener = new TextToSpeech.OnInitListener() {
    @Override
    public void onInit(int status) {
      if (status == TextToSpeech.SUCCESS) {
        tts.setOnUtteranceProgressListener(utteranceProgressListener);
        
        Locale locale = tts.getDefaultVoice().getLocale();
        locale = new Locale(locale.toString());
        if (checkLanguage(locale)) {
          tts.setLanguage(locale);
        }
      } else {
        Log.e("error", "Failed to initialize TextToSpeech");
      }
    }
  };

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_tts");
    channel.setMethodCallHandler(new FlutterTtsPlugin(registrar.activity(), channel));
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("speak")) {
      String text = call.arguments.toString();
      speak(text);
      result.success(1);
    } else if (call.method.equals("stop")){
      stop(); 
      result.success(1);
    } else if (call.method.equals("setRate")) {
      String rate = call.arguments.toString();
      setRate(Float.parseFloat(rate));
      result.success(1);
    } else if (call.method.equals("setLanguage")){
      String language = call.arguments.toString();
      setLanguage(language, result);
    }  else if (call.method.equals("getLanguages")){
      getLanguages(result);
    }  else {
      result.notImplemented();
    }
  }

  void setRate(float rate) {
    tts.setSpeechRate(rate);
  }

  private Boolean checkLanguage(Locale locale){
    Boolean isLangAvailable = false;
    if (tts.isLanguageAvailable(locale) == TextToSpeech.LANG_AVAILABLE) {
      isLangAvailable = true;
    } else {
      Log.e("error", "Language is not available - " + locale);
    }
    return isLangAvailable;
  }

  void setLanguage(String language, Result result) {
    Locale locale = new Locale(language);
    if (checkLanguage(locale)) {
      tts.setLanguage(locale);
      result.success(1);
    }
  }

  void getLanguages(Result result) {
    ArrayList<String> locales = new ArrayList<>();
    for (Locale locale : tts.getAvailableLanguages()) {
      locales.add(locale.toLanguageTag());
    }
    result.success(locales);
  }

  void speak(String text) {
    tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, uuid);
  }

  void stop() {
    tts.stop();
  }
}
