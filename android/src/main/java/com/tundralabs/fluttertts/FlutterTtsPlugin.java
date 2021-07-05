package com.tundralabs.fluttertts;

import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.speech.tts.Voice;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.MissingResourceException;
import java.util.Set;
import java.util.UUID;
import java.lang.reflect.Field;

/** FlutterTtsPlugin */
public class FlutterTtsPlugin implements MethodCallHandler, FlutterPlugin {
  private Handler handler;
  private MethodChannel methodChannel;
  private MethodChannel.Result speakResult;
  private MethodChannel.Result synthResult;
  private boolean awaitSpeakCompletion = false;
  private boolean speaking = false;
  private boolean awaitSynthCompletion = false;
  private boolean synth = false;
  private Context context;
  private TextToSpeech tts;
  private final String tag = "TTS";
  private final String googleTtsEngine = "com.google.android.tts";
  private boolean isTtsInitialized = false;
  private ArrayList<Runnable> pendingMethodCalls = new ArrayList<>();
  private final HashMap<String, String> utterances = new HashMap<>();
  Bundle bundle;
  private int silencems;
  private static final String SILENCE_PREFIX = "SIL_";
  private static final String SYNTHESIZE_TO_FILE_PREFIX = "STF_";
  private int queueMode = TextToSpeech.QUEUE_FLUSH;

  /** Plugin registration. */
  @SuppressWarnings("deprecation")
  public static void registerWith(Registrar registrar) {
    FlutterTtsPlugin instance = new FlutterTtsPlugin();
    instance.initInstance(registrar.messenger(), registrar.activeContext());
  }

  private void initInstance(BinaryMessenger messenger, Context context) {
    this.context = context;
    methodChannel = new MethodChannel(messenger, "flutter_tts");
    methodChannel.setMethodCallHandler(this);
    handler = new Handler(Looper.getMainLooper());
    bundle = new Bundle();
    tts = new TextToSpeech(context, onInitListener, googleTtsEngine);
  }

  /** Android Plugin APIs */
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    initInstance(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    stop();
    tts.shutdown();
    context = null;
    methodChannel.setMethodCallHandler(null);
    methodChannel = null;
  }

  private UtteranceProgressListener utteranceProgressListener =
      new UtteranceProgressListener() {
        @Override
        public void onStart(String utteranceId) {
          if (utteranceId != null && utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
            invokeMethod("synth.onStart", true);
          } else {
            Log.d(tag, "Utterance ID has started: " + utteranceId);
            invokeMethod("speak.onStart", true);
          }
          if (Build.VERSION.SDK_INT < 26) {
            this.onProgress(utteranceId, 0, utterances.get(utteranceId).length());
          }
        }

        @Override
        public void onDone(String utteranceId) {
          if (utteranceId != null && utteranceId.startsWith(SILENCE_PREFIX)) return;
          if (utteranceId != null && utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
            Log.d(tag, "Utterance ID has completed: " + utteranceId);
            if (awaitSynthCompletion) {
              synthCompletion(1);
            }
            invokeMethod("synth.onComplete", true);
          } else {
            Log.d(tag, "Utterance ID has completed: " + utteranceId);
            if (awaitSpeakCompletion) {
              speakCompletion(1);
            }
            invokeMethod("speak.onComplete", true);
          }
          utterances.remove(utteranceId);
        }

        @Override
        public void onStop(String utteranceId, boolean interrupted) {
          Log.d(
              tag,
              "Utterance ID has been stopped: " + utteranceId + ". Interrupted: " + interrupted);
          if (awaitSpeakCompletion) {
            speaking = false;
          }
          invokeMethod("speak.onCancel", true);
        }

        private void onProgress(String utteranceId, int startAt, int endAt) {
          if (utteranceId != null && !utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
            final String text = utterances.get(utteranceId);
            final HashMap<String, String> data = new HashMap<>();
            data.put("text", text);
            data.put("start", Integer.toString(startAt));
            data.put("end", Integer.toString(endAt));
            data.put("word", text.substring(startAt, endAt));
            invokeMethod("speak.onProgress", data);
          }
        }

        // Requires Android 26 or later
        @Override
        public void onRangeStart(String utteranceId, int startAt, int endAt, int frame) {
          if (utteranceId != null && !utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
            super.onRangeStart(utteranceId, startAt, endAt, frame);
            this.onProgress(utteranceId, startAt, endAt);
          }
        }

        @Override
        @Deprecated
        public void onError(String utteranceId) {
          if (utteranceId != null && utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
            if (awaitSynthCompletion) {
              synth = false;
            }
            invokeMethod("synth.onError", "Error from TextToSpeech (synth)");
          } else {
            if (awaitSpeakCompletion) {
              speaking = false;
            }
            invokeMethod("speak.onError", "Error from TextToSpeech (speak)");
          }
        }

        @Override
        public void onError(String utteranceId, int errorCode) {
          if (utteranceId != null && utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
            if (awaitSynthCompletion) {
              synth = false;
            }
            invokeMethod("synth.onError", "Error from TextToSpeech (synth) - " + errorCode);
          } else {
            if (awaitSpeakCompletion) {
              speaking = false;
            }
            invokeMethod("speak.onError", "Error from TextToSpeech (speak) - " + errorCode);
          }
        }
      };

  void speakCompletion(final int success) {
    speaking = false;
    handler.post(
        new Runnable() {
          @Override
          public void run() {
            speakResult.success(success);
          }
        });
  }

  void synthCompletion(final int success) {
    synth = false;
    handler.post(
        new Runnable() {
          @Override
          public void run() {
            synthResult.success(success);
          }
        });
  }

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
            } catch (NullPointerException | IllegalArgumentException e) {
              Log.e(tag, "getDefaultLocale: " + e.getMessage());
            }

            // Handle pending method calls (sent while TTS was initializing)
            isTtsInitialized = true;
            for (Runnable call : pendingMethodCalls) {
              call.run();
            }
          } else {
            Log.e(tag, "Failed to initialize TextToSpeech");
          }
        }
      };

  @Override
  public void onMethodCall(@NonNull final MethodCall call, @NonNull final Result result) {
    // If TTS is still loading
    if (!isTtsInitialized) {
      // Suspend method call until the TTS engine is ready
      final Runnable suspendedCall =
          new Runnable() {
            public void run() {
              onMethodCall(call, result);
            }
          };
      pendingMethodCalls.add(suspendedCall);
      return;
    }
    switch (call.method) {
      case "speak":
        {
          String text = call.arguments.toString();
          if (this.speaking) {
            result.success(0);
            break;
          }
          boolean b = speak(text);
          if (!b) {
            final Runnable suspendedCall =
                    new Runnable() {
                      public void run() {
                        onMethodCall(call, result);
                      }
                    };
            pendingMethodCalls.add(suspendedCall);
            return;
          }
          if (this.awaitSpeakCompletion) {
            this.speaking = true;
            this.speakResult = result;
          } else {
            result.success(1);
          }
          break;
        }
      case "awaitSpeakCompletion":
        {
          this.awaitSpeakCompletion = Boolean.parseBoolean(call.arguments.toString());
          result.success(1);
          break;
        }
      case "awaitSynthCompletion":
        {
          this.awaitSynthCompletion = Boolean.parseBoolean(call.arguments.toString());
          result.success(1);
          break;
        }
      case "synthesizeToFile":
        {
          String text = call.argument("text");
          if (this.synth) {
            result.success(0);
            break;
          }
          String fileName = call.argument("fileName");
          synthesizeToFile(text, fileName);
          if (this.awaitSynthCompletion) {
            this.synth = true;
            this.synthResult = result;
          } else {
            result.success(1);
          }
          break;
        }
      case "stop":
        stop();
        result.success(1);
        break;
      case "setEngine":
        String engine = call.arguments.toString();
        setEngine(engine, result);
        break;
      case "setSpeechRate":
        String rate = call.arguments.toString();
        setSpeechRate(Float.parseFloat(rate));
        result.success(1);
        break;
      case "setVolume":
        String volume = call.arguments.toString();
        setVolume(Float.parseFloat(volume), result);
        break;
      case "setPitch":
        String pitch = call.arguments.toString();
        setPitch(Float.parseFloat(pitch), result);
        break;
      case "setLanguage":
        {
          String language = call.arguments.toString();
          setLanguage(language, result);
          break;
        }
      case "getLanguages":
        getLanguages(result);
        break;
      case "getVoices":
        getVoices(result);
        break;
      case "getSpeechRateValidRange":
        getSpeechRateValidRange(result);
        break;
      case "getEngines":
        getEngines(result);
        break;
      case "getDefaultEngine":
        getDefaultEngine(result);
        break;
      case "setVoice":
        HashMap<String, String> voice = call.arguments();
        setVoice(voice, result);
        break;
      case "isLanguageAvailable":
        {
          String language = call.arguments().toString();
          Locale locale = Locale.forLanguageTag(language);
          result.success(isLanguageAvailable(locale));
          break;
        }
      case "setSilence":
        String silencems = call.arguments.toString();
        this.silencems = Integer.parseInt(silencems);
        break;
      case "setSharedInstance":
        result.success(1);
        break;
      case "isLanguageInstalled":
        String language = call.arguments().toString();
        result.success(isLanguageInstalled(language));
        break;
      case "areLanguagesInstalled":
        List<String> languages = call.arguments();
        result.success(areLanguagesInstalled(languages));
        break;
      case "setQueueMode":
        String queueMode = call.arguments.toString();
        this.queueMode = Integer.parseInt(queueMode);
        result.success(1);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  void setSpeechRate(float rate) {
    tts.setSpeechRate(rate);
  }

  Boolean isLanguageAvailable(Locale locale) {
    return tts.isLanguageAvailable(locale) >= TextToSpeech.LANG_AVAILABLE;
  }

  Map<String, Boolean> areLanguagesInstalled(List<String> languages) {
    Map<String, Boolean> result = new HashMap<>();
    for (String language : languages) {
      result.put(language, isLanguageInstalled(language));
    }
    return result;
  }

  boolean isLanguageInstalled(String language) {
    Locale locale = Locale.forLanguageTag(language);
    if (isLanguageAvailable(locale)) {
      Voice voiceToCheck = null;
      for (Voice v : tts.getVoices()) {
        if (v.getLocale().equals(locale) && !v.isNetworkConnectionRequired()) {
          voiceToCheck = v;
          break;
        }
      }
      if (voiceToCheck != null) {
        Set<String> features = voiceToCheck.getFeatures();
        return features != null
            && !features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED);
      }
    }
    return false;
  }

  void setEngine(String engine, Result result) {
    tts = new TextToSpeech(context, onInitListener, engine);
    result.success(1);
  }

  void setLanguage(String language, Result result) {
    Locale locale = Locale.forLanguageTag(language);
    if (isLanguageAvailable(locale)) {
      tts.setLanguage(locale);
      result.success(1);
    } else {
      result.success(0);
    }
  }

  void setVoice(HashMap<String, String> voice, Result result) {
    for (Voice ttsVoice : tts.getVoices()) {
      if (ttsVoice.getName().equals(voice.get("name"))
          && ttsVoice.getLocale().toLanguageTag().equals(voice.get("locale"))) {
        tts.setVoice(ttsVoice);
        result.success(1);
        return;
      }
    }
    Log.d(tag, "Voice name not found: " + voice);
    result.success(0);
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

  void getVoices(Result result) {
    ArrayList<HashMap<String, String>> voices = new ArrayList<>();
    try {
      for (Voice voice : tts.getVoices()) {
        HashMap<String, String> voiceMap = new HashMap<>();
        voiceMap.put("name", voice.getName());
        voiceMap.put("locale", voice.getLocale().toLanguageTag());
        voices.add(voiceMap);
      }
      result.success(voices);
    } catch (NullPointerException e) {
      Log.d(tag, "getVoices: " + e.getMessage());
      result.success(null);
    }
  }

  void getLanguages(Result result) {
    ArrayList<String> locales = new ArrayList<>();
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        // While this method was introduced in API level 21, it seems that it
        // has not been implemented in the speech service side until API Level 23.
        for (Locale locale : tts.getAvailableLanguages()) {
          locales.add(locale.toLanguageTag());
        }
      } else {
        for (Locale locale : Locale.getAvailableLocales()) {
          if (locale.getVariant().isEmpty() && isLanguageAvailable(locale)) {
            locales.add(locale.toLanguageTag());
          }
        }
      }
    } catch (MissingResourceException | NullPointerException e) {
      Log.d(tag, "getLanguages: " + e.getMessage());
    }
    result.success(locales);
  }

  void getEngines(Result result) {
    ArrayList<String> engines = new ArrayList<>();
    try {
      for (TextToSpeech.EngineInfo engineInfo : tts.getEngines()) {
        engines.add(engineInfo.name);
      }
    } catch (Exception e) {
      Log.d(tag, "getEngines: " + e.getMessage());
    }
    result.success(engines);
  }

  void getDefaultEngine(Result result) {
    final String defaultEngine = tts.getDefaultEngine();
    result.success(defaultEngine);
  }

  void getSpeechRateValidRange(Result result) {
    // Valid values available in the android documentation.
    // https://developer.android.com/reference/android/speech/tts/TextToSpeech#setSpeechRate(float)
    final HashMap<String, String> data = new HashMap<String, String>();
    data.put("min", "0");
    data.put("normal", "1");
    data.put("max", "3");
    data.put("platform", "android");
    result.success(data);
  }

  private boolean speak(String text) {
    String uuid = UUID.randomUUID().toString();
    utterances.put(uuid, text);
    if (ismServiceConnectionUsable(tts)) {
      if (silencems > 0) {
        tts.playSilentUtterance(silencems, TextToSpeech.QUEUE_FLUSH, SILENCE_PREFIX + uuid);
        return tts.speak(text, TextToSpeech.QUEUE_ADD, bundle, uuid) == 0;
      } else {
        return tts.speak(text, this.queueMode, bundle, uuid) == 0;
      }
    } else {
      isTtsInitialized = false;
      tts = new TextToSpeech(context, onInitListener, googleTtsEngine);
      return false;
    }
  }

  private void stop() {
    tts.stop();
  }

  private void synthesizeToFile(String text, String fileName) {
    File file = new File(context.getExternalFilesDir(null), fileName);
    String uuid = UUID.randomUUID().toString();
    bundle.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, SYNTHESIZE_TO_FILE_PREFIX + uuid);

    int result = tts.synthesizeToFile(text, bundle, file, SYNTHESIZE_TO_FILE_PREFIX + uuid);
    if (result == TextToSpeech.SUCCESS) {
      Log.d(tag, "Successfully created file : " + file.getPath());
    } else {
      Log.d(tag, "Failed creating file : " + file.getPath());
    }
  }

  private void invokeMethod(final String method, final Object arguments) {
    handler.post(
        new Runnable() {
          @Override
          public void run() {
            if (methodChannel != null) methodChannel.invokeMethod(method, arguments);
          }
        });
  }

  private boolean ismServiceConnectionUsable(TextToSpeech tts) {

    boolean isBindConnection = true;
    if (tts == null) {
      return false;
    }
    Field[] fields = tts.getClass().getDeclaredFields();
    for (int j = 0; j < fields.length; j++) {
      fields[j].setAccessible(true);
      if ("mServiceConnection".equals(fields[j].getName()) && "android.speech.tts.TextToSpeech$Connection".equals(fields[j].getType().getName())) {
        try {
          if (fields[j].get(tts) == null) {
            isBindConnection = false;
            Log.e(tag, "*******TTS -> mServiceConnection == null*******");
          }
        } catch (IllegalArgumentException e) {
          e.printStackTrace();
        } catch (IllegalAccessException e) {
          e.printStackTrace();
        } catch (Exception e) {
          e.printStackTrace();
        }
      }
    }
    return isBindConnection;
  }

}
