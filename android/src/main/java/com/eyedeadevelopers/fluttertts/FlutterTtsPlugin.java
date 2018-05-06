package com.eyedeadevelopers.fluttertts;

import android.app.Activity;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.util.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.UUID;

/** FlutterTtsPlugin */
public class FlutterTtsPlugin implements MethodCallHandler {
  private final MethodChannel channel;
  private TextToSpeech tts;
  private final String tag = "TTS";
  String uuid;
  Bundle bundle;

  /** Plugin registration. */
  private FlutterTtsPlugin(Activity activity, MethodChannel channel) {
    this.channel = channel;
    this.channel.setMethodCallHandler(this);

    bundle = new Bundle();
    tts = new TextToSpeech(activity.getApplicationContext(), onInitListener);
  };

  private UtteranceProgressListener utteranceProgressListener =
      new UtteranceProgressListener() {
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

  private TextToSpeech.OnInitListener onInitListener =
      new TextToSpeech.OnInitListener() {
        @Override
        public void onInit(int status) {
          if (status == TextToSpeech.SUCCESS) {
            tts.setOnUtteranceProgressListener(utteranceProgressListener);

            try {
              Locale locale = tts.getDefaultVoice().getLocale();
              if (isLanguageAvailable(locale)) {
                tts.setLanguage(locale);
              }
            } catch (NullPointerException e) {
              Log.d(tag, "getDefaultVoice: " + e.getMessage() + " (known issue with API 21 & 22)");
            }
          } else {
            Log.d(tag, "Failed to initialize TextToSpeech");
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
    } else if (call.method.equals("stop")) {
      stop();
      result.success(1);
    } else if (call.method.equals("setSpeechRate")) {
      String rate = call.arguments.toString();
      setSpeechRate(Float.parseFloat(rate));
      result.success(1);
    } else if (call.method.equals("setVolume")) {
      String volume = call.arguments.toString();
      setVolume(Float.parseFloat(volume), result);
    } else if (call.method.equals("setPitch")) {
      String pitch = call.arguments.toString();
      setPitch(Float.parseFloat(pitch), result);
    } else if (call.method.equals("setLanguage")) {
      String language = call.arguments.toString();
      setLanguage(language, result);
    } else if (call.method.equals("getLanguages")) {
      getLanguages(result);
    } else if (call.method.equals("isLanguageAvailable")) {
      String language = ((HashMap) call.arguments()).get("language").toString();
      Locale locale = new Locale(language);
      final Boolean isAvailable = isLanguageAvailable(locale);
      result.success(isAvailable);
    } else {
      result.notImplemented();
    }
  }

  void setSpeechRate(float rate) {
    tts.setSpeechRate(rate);
  }

  Boolean isLanguageAvailable(Locale locale) {
    Boolean isLanguageAvailable = false;
    if (tts.isLanguageAvailable(locale) == TextToSpeech.LANG_AVAILABLE) {
      isLanguageAvailable = true;
    } else {
      Log.d(tag, "Language is not available - " + locale);
    }
    return isLanguageAvailable;
  }

  void setLanguage(String language, Result result) {
    Locale locale = new Locale(language);
    if (isLanguageAvailable(locale)) {
      tts.setLanguage(locale);
      result.success(1);
    } else {
      result.success(0);
    }
  }

  void setVolume(float volume, Result result) {
    if (volume >= 0.0F && volume <= 1.0F) {
      bundle.putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume);
      result.success(1);
    } else {
      Log.d(tag, "Invalid volume " + volume + " value - Range is from 0.0 to 1.0");
      result.success(0);
    }
  }

  void setPitch(float pitch, Result result) {
    if (pitch >= 0.5F && pitch <= 2.0F) {
      tts.setPitch(pitch);
      result.success(1);
    } else {
      Log.d(tag, "Invalid pitch " + pitch + " value - Range is from 0.5 to 2.0");
      result.success(0);
    }
  }

  void getLanguages(Result result) {
    ArrayList<String> locales = new ArrayList<>();
    try {
      for (Locale locale : tts.getAvailableLanguages()) {
        locales.add(locale.toLanguageTag());
      }
      result.success(locales);
    } catch (NullPointerException e) {
      Log.d(tag, "getAvailableLanguages: " + e.getMessage() + " - (known issue with API 21 & 22)");
      result.success(null);
    }
  }

  void speak(String text) {
    uuid = UUID.randomUUID().toString();
    tts.speak(text, TextToSpeech.QUEUE_FLUSH, bundle, uuid);
  }

  void stop() {
    tts.stop();
  }
}