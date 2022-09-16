package com.tundralabs.fluttertts

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.*
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.lang.reflect.Field
import java.util.*
import kotlin.collections.ArrayList
import kotlin.collections.HashMap


/** FlutterTtsPlugin  */
class FlutterTtsPlugin : MethodCallHandler, FlutterPlugin {
    private var handler: Handler? = null
    private var methodChannel: MethodChannel? = null
    private var speakResult: Result? = null
    private var synthResult: Result? = null
    private var awaitSpeakCompletion = false
    private var speaking = false
    private var awaitSynthCompletion = false
    private var synth = false
    private var context: Context? = null
    private var tts: TextToSpeech? = null
    private val tag = "TTS"
    private val googleTtsEngine = "com.google.android.tts"
    private var isTtsInitialized = false
    private var isPaused = false
    private var textToSpeakArrayPosition = 0
    private var textToSpeak: String = ""
    private var textToSpeakLength = 0
    private var textToSpeakArray = ArrayList<String>()
    private var lastWordWasSilence = false
    private val pendingMethodCalls = ArrayList<Runnable>()
    private val utterances = HashMap<String, String>()
    private var bundle: Bundle? = null
    private var silencems = 0
    private var queueMode: Int = TextToSpeech.QUEUE_FLUSH
    private fun initInstance(messenger: BinaryMessenger, context: Context) {
        this.context = context
        methodChannel = MethodChannel(messenger, "flutter_tts")
        methodChannel!!.setMethodCallHandler(this)
        handler = Handler(Looper.getMainLooper())
        bundle = Bundle()
        tts = TextToSpeech(context, onInitListener, googleTtsEngine)
    }

    /** Android Plugin APIs  */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        initInstance(binding.binaryMessenger, binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stop()
        tts!!.shutdown()
        context = null
        methodChannel!!.setMethodCallHandler(null)
        methodChannel = null
    }

    private val utteranceProgressListener: UtteranceProgressListener =
        object : UtteranceProgressListener() {
            override fun onStart(utteranceIdLocal: String) {
                if (textToSpeakArrayPosition > 0) {
                    return
                }
                val utteranceId = getCurrentSentence()
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    invokeMethod("synth.onStart", true)
                } else {
                    Log.d(tag, "Utterance ID has started: $utteranceId")
                    invokeMethod("speak.onStart", true)
                }
                if (Build.VERSION.SDK_INT < 26) {
                    onProgress(utteranceId, 0, utterances[utteranceId]!!.length)
                }
            }

            override fun onDone(utteranceIdLocal: String) {
                if (textToSpeakArrayPosition < textToSpeakLength) {
                    continueReading()
                    return
                }
                speaking = false
                val utteranceId = getCurrentSentence()
                if (utteranceId.startsWith(SILENCE_PREFIX)) return
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    Log.d(tag, "Utterance ID has completed: $utteranceId")
                    if (awaitSynthCompletion) {
                        synthCompletion(1)
                    }
                    invokeMethod("synth.onComplete", true)
                } else {
                    Log.d(tag, "Utterance ID has completed: $utteranceId")
                    if (awaitSpeakCompletion && queueMode == TextToSpeech.QUEUE_FLUSH) {
                        speakCompletion(1)
                    }
                    invokeMethod("speak.onComplete", true)
                }
                utterances.remove(utteranceId)
            }

            override fun onStop(utteranceIdLocal: String, interrupted: Boolean) {
                val utteranceId = getCurrentSentence()
                Log.d(
                    tag,
                    "Utterance ID has been stopped: $utteranceId. Interrupted: $interrupted"
                )
                if (awaitSpeakCompletion) {
                    speaking = false
                }
                if(isPaused){                    
                    invokeMethod("speak.onPause", true)
                }else{
                    invokeMethod("speak.onCancel", true)
                }
            }

            private fun onProgress(utteranceIdLocal: String?, startAtLocal: Int, endAtLocal: Int) {

                val startAndEndAt = calculateStartAndEndAt(textToSpeakArrayPosition)
                var startAt: Int = startAndEndAt.get("startAt")!!
                startAt = startAt + startAtLocal
                var endAt: Int = startAndEndAt.get("endAt")!!
                endAt = startAt + endAtLocal

                val utteranceId = getCurrentSentence()
                if (utteranceId != null && !utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    val text = utterances[utteranceId]
                    val data = HashMap<String, String?>()
                    data["text"] = text
                    data["start"] = startAt.toString()
                    data["end"] = endAt.toString()
                    data["word"] = text!!.substring(startAt, endAt)
                    invokeMethod("speak.onProgress", data)
                }
            }

            // Requires Android 26 or later
            override fun onRangeStart(
                utteranceIdLocal: String,
                startAtLocal: Int,
                endAtLocal: Int,
                frame: Int
            ) {
                val utteranceId = getCurrentSentence()

                val startAndEndAt = calculateStartAndEndAt(textToSpeakArrayPosition)
                var startAt: Int = startAndEndAt.get("startAt")!!
                startAt = startAt + startAtLocal
                var endAt: Int = startAndEndAt.get("endAt")!!
                endAt = startAt + endAtLocal

                if (!utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    super.onRangeStart(utteranceIdLocal, startAtLocal, endAtLocal, frame)
                    onProgress(utteranceId, startAt, endAt)
                }
            }

            @Deprecated("")
            override fun onError(utteranceIdLocal: String) {
                val utteranceId = getCurrentSentence()
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    if (awaitSynthCompletion) {
                        synth = false
                    }
                    invokeMethod("synth.onError", "Error from TextToSpeech (synth)")
                } else {
                    if (awaitSpeakCompletion) {
                        speaking = false
                    }
                    invokeMethod("speak.onError", "Error from TextToSpeech (speak)")
                }
            }

            override fun onError(utteranceIdLocal: String, errorCode: Int) {
                val utteranceId = getCurrentSentence()
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    if (awaitSynthCompletion) {
                        synth = false
                    }
                    invokeMethod("synth.onError", "Error from TextToSpeech (synth) - $errorCode")
                } else {
                    if (awaitSpeakCompletion) {
                        speaking = false
                    }
                    invokeMethod("speak.onError", "Error from TextToSpeech (speak) - $errorCode")
                }
            }
        }

    fun speakCompletion(success: Int) {
        speaking = false
        handler!!.post { speakResult?.success(success) }
    }

    fun synthCompletion(success: Int) {
        synth = false
        handler!!.post { synthResult?.success(success) }
    }

    private fun continueReading() {
        if (textToSpeakArrayPosition >= textToSpeakLength) {
            return
        }
        if (isPaused) return

        val uuid: String = UUID.randomUUID().toString()
        val sentence: String = getCurrentSentence()
        //keep talking until we finish all
        if (lastWordWasSilence) {
            lastWordWasSilence = false
            tts!!.speak(sentence, TextToSpeech.QUEUE_FLUSH, bundle, uuid) == 0
            textToSpeakArrayPosition = textToSpeakArrayPosition + 1
        } else {
            lastWordWasSilence = true
            tts!!.playSilentUtterance(
                silencems.toLong(),
                TextToSpeech.QUEUE_FLUSH,
                SILENCE_PREFIX + uuid
            )
        }
    }

    private val onInitListener: TextToSpeech.OnInitListener =
        TextToSpeech.OnInitListener { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts!!.setOnUtteranceProgressListener(utteranceProgressListener)
                try {
                    val locale: Locale = tts!!.defaultVoice.locale
                    if (isLanguageAvailable(locale)) {
                        tts!!.language = locale
                    }
                } catch (e: NullPointerException) {
                    Log.e(tag, "getDefaultLocale: " + e.message)
                } catch (e: IllegalArgumentException) {
                    Log.e(tag, "getDefaultLocale: " + e.message)
                }

                // Handle pending method calls (sent while TTS was initializing)
                isTtsInitialized = true
                for (call in pendingMethodCalls) {
                    call.run()
                }
            } else {
                Log.e(tag, "Failed to initialize TextToSpeech")
            }
        }

    override fun onMethodCall(call: MethodCall, result: Result) {
        // If TTS is still loading
        if (!isTtsInitialized) {
            // Suspend method call until the TTS engine is ready
            val suspendedCall = Runnable { onMethodCall(call, result) }
            pendingMethodCalls.add(suspendedCall)
            return
        }
        when (call.method) {
            "speak" -> {
                if (isPaused) {
                    isPaused = false                    
                    continueReading()
                    invokeMethod("speak.onContinue", true)
                    result.success(1)
                    return
                }
                isPaused = false
                textToSpeakArrayPosition = 0
                textToSpeak = call.arguments.toString()
                if (speaking) {
                    // If TTS is set to queue mode, allow the utterance to be queued up rather than discarded
                    if (queueMode == TextToSpeech.QUEUE_FLUSH) {
                        result.success(0)
                        return
                    }
                }
                val b = speak(textToSpeak)
                if (!b) {
                    val suspendedCall = Runnable { onMethodCall(call, result) }
                    pendingMethodCalls.add(suspendedCall)
                    return
                }
                // Only use await speak completion if queueMode is set to QUEUE_FLUSH
                if (awaitSpeakCompletion && queueMode == TextToSpeech.QUEUE_FLUSH) {
                    speaking = true
                    speakResult = result
                } else {
                    result.success(1)
                }
            }
            "pause" -> {
                isPaused = true
                if (textToSpeakArrayPosition > 0) {
                    //go back one sentence
                    textToSpeakArrayPosition = textToSpeakArrayPosition - 1
                }
                tts!!.stop()
                result.success(1)
            }
            "awaitSpeakCompletion" -> {
                awaitSpeakCompletion = java.lang.Boolean.parseBoolean(call.arguments.toString())
                result.success(1)
            }
            "awaitSynthCompletion" -> {
                awaitSynthCompletion = java.lang.Boolean.parseBoolean(call.arguments.toString())
                result.success(1)
            }
            "getMaxSpeechInputLength" -> {
                val res = maxSpeechInputLength
                result.success(res)
            }
            "synthesizeToFile" -> {
                val text: String? = call.argument("text")
                if (synth) {
                    result.success(0)
                    return
                }
                val fileName: String? = call.argument("fileName")
                synthesizeToFile(text!!, fileName!!)
                if (awaitSynthCompletion) {
                    synth = true
                    synthResult = result
                } else {
                    result.success(1)
                }
            }
            "stop" -> {
                textToSpeakArrayPosition = 0
                stop()
                result.success(1)
            }
            "setEngine" -> {
                val engine: String = call.arguments.toString()
                setEngine(engine, result)
            }
            "setSpeechRate" -> {
                val rate: String = call.arguments.toString()
                // To make the FlutterTts API consistent across platforms,
                // Android 1.0 is mapped to flutter 0.5.
                setSpeechRate(rate.toFloat() * 2.0f)
                result.success(1)
            }
            "setVolume" -> {
                val volume: String = call.arguments.toString()
                setVolume(volume.toFloat(), result)
            }
            "setPitch" -> {
                val pitch: String = call.arguments.toString()
                setPitch(pitch.toFloat(), result)
            }
            "setLanguage" -> {
                val language: String = call.arguments.toString()
                setLanguage(language, result)
            }
            "getLanguages" -> getLanguages(result)
            "getVoices" -> getVoices(result)
            "getSpeechRateValidRange" -> getSpeechRateValidRange(result)
            "getEngines" -> getEngines(result)
            "getDefaultEngine" -> getDefaultEngine(result)
            "getDefaultVoice" -> getDefaultVoice(result)
            "setVoice" -> {
                val voice: HashMap<String?, String>? = call.arguments()
                setVoice(voice!!, result)
            }
            "isLanguageAvailable" -> {
                val language: String = call.arguments.toString()
                val locale: Locale = Locale.forLanguageTag(language)
                result.success(isLanguageAvailable(locale))
            }
            "setSilence" -> {
                val silencems: String = call.arguments.toString()
                this.silencems = silencems.toInt()
            }
            "setSharedInstance" -> result.success(1)
            "isLanguageInstalled" -> {
                val language: String = call.arguments.toString()
                result.success(isLanguageInstalled(language))
            }
            "areLanguagesInstalled" -> {
                val languages: List<String?>? = call.arguments()
                result.success(areLanguagesInstalled(languages!!))
            }
            "setQueueMode" -> {
                val queueMode: String = call.arguments.toString()
                this.queueMode = queueMode.toInt()
                result.success(1)
            }
            else -> result.notImplemented()
        }
    }

    private fun setSpeechRate(rate: Float) {
        tts!!.setSpeechRate(rate)
    }

    private fun isLanguageAvailable(locale: Locale?): Boolean {
        return tts!!.isLanguageAvailable(locale) >= TextToSpeech.LANG_AVAILABLE
    }

    private fun areLanguagesInstalled(languages: List<String?>): Map<String?, Boolean> {
        val result: MutableMap<String?, Boolean> = HashMap()
        for (language in languages) {
            result[language] = isLanguageInstalled(language)
        }
        return result
    }

    private fun isLanguageInstalled(language: String?): Boolean {
        val locale: Locale = Locale.forLanguageTag(language!!)
        if (isLanguageAvailable(locale)) {
            var voiceToCheck: Voice? = null
            for (v in tts!!.voices) {
                if (v.locale == locale && !v.isNetworkConnectionRequired) {
                    voiceToCheck = v
                    break
                }
            }
            if (voiceToCheck != null) {
                val features: Set<String> = voiceToCheck.features
                return (!features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED))
            }
        }
        return false
    }

    private fun setEngine(engine: String?, result: Result) {
        tts = TextToSpeech(context, onInitListener, engine)
        result.success(1)
    }

    private fun setLanguage(language: String?, result: Result) {
        val locale: Locale = Locale.forLanguageTag(language!!)
        if (isLanguageAvailable(locale)) {
            tts!!.language = locale
            result.success(1)
        } else {
            result.success(0)
        }
    }

    private fun setVoice(voice: HashMap<String?, String>, result: Result) {
        for (ttsVoice in tts!!.voices) {
            if (ttsVoice.name == voice["name"] && ttsVoice.locale
                    .toLanguageTag() == voice["locale"]
            ) {
                tts!!.voice = ttsVoice
                result.success(1)
                return
            }
        }
        Log.d(tag, "Voice name not found: $voice")
        result.success(0)
    }

    private fun setVolume(volume: Float, result: Result) {
        if (volume in (0.0f..1.0f)) {
            bundle!!.putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume)
            result.success(1)
        } else {
            Log.d(tag, "Invalid volume $volume value - Range is from 0.0 to 1.0")
            result.success(0)
        }
    }

    private fun setPitch(pitch: Float, result: Result) {
        if (pitch in (0.5f..2.0f)) {
            tts!!.setPitch(pitch)
            result.success(1)
        } else {
            Log.d(tag, "Invalid pitch $pitch value - Range is from 0.5 to 2.0")
            result.success(0)
        }
    }

    private fun getVoices(result: Result) {
        val voices = ArrayList<HashMap<String, String>>()
        try {
            for (voice in tts!!.voices) {
                val voiceMap = HashMap<String, String>()
                voiceMap["name"] = voice.name
                voiceMap["locale"] = voice.locale.toLanguageTag()
                voices.add(voiceMap)
            }
            result.success(voices)
        } catch (e: NullPointerException) {
            Log.d(tag, "getVoices: " + e.message)
            result.success(null)
        }
    }

    private fun getLanguages(result: Result) {
        val locales = ArrayList<String>()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // While this method was introduced in API level 21, it seems that it
                // has not been implemented in the speech service side until API Level 23.
                for (locale in tts!!.availableLanguages) {
                    locales.add(locale.toLanguageTag())
                }
            } else {
                for (locale in Locale.getAvailableLocales()) {
                    if (locale.variant.isEmpty() && isLanguageAvailable(locale)) {
                        locales.add(locale.toLanguageTag())
                    }
                }
            }
        } catch (e: MissingResourceException) {
            Log.d(tag, "getLanguages: " + e.message)
        } catch (e: NullPointerException) {
            Log.d(tag, "getLanguages: " + e.message)
        }
        result.success(locales)
    }

    private fun getEngines(result: Result) {
        val engines = ArrayList<String>()
        try {
            for (engineInfo in tts!!.engines) {
                engines.add(engineInfo.name)
            }
        } catch (e: Exception) {
            Log.d(tag, "getEngines: " + e.message)
        }
        result.success(engines)
    }

    private fun getDefaultEngine(result: Result) {
        val defaultEngine: String = tts!!.defaultEngine
        result.success(defaultEngine)
    }

    private fun getDefaultVoice(result: Result) {
        val defaultVoice: Voice? = tts!!.defaultVoice
        val voice = HashMap<String, String>()
        if (defaultVoice != null) {
            voice["name"] = defaultVoice.name
            voice["locale"] = defaultVoice.locale.toLanguageTag()
        }
        result.success(voice)
    }

    private fun getSpeechRateValidRange(result: Result) {
        // Valid values available in the android documentation.
        // https://developer.android.com/reference/android/speech/tts/TextToSpeech#setSpeechRate(float)
        // To make the FlutterTts API consistent across platforms,
        // we map Android 1.0 to flutter 0.5 and so on.
        val data = HashMap<String, String>()
        data["min"] = "0"
        data["normal"] = "0.5"
        data["max"] = "1.5"
        data["platform"] = "android"
        result.success(data)
    }

    private fun speak(text: String): Boolean {
        if (ismServiceConnectionUsable(tts)) {
            val uuid: String = UUID.randomUUID().toString()
            utterances[uuid] = text

            //Use a unique word that will never occur in a text here,
            //because we will split the user text with it and it will be removed
            val splitKey: String = "__fftts_dcdea_split_here__"

            var encodedText = text
            //do not split ... as they are used in text
            encodedText = encodedText.replace("...", "__ddd_dcdea_triple_dot__")

            val splitablePunctuations = arrayOf("?", ".", "!", ":", ";")
            //iterate through map and concatenate        
            for (punctuation in splitablePunctuations) {
                encodedText = encodedText.replace(punctuation, punctuation + splitKey)
            }
            encodedText = encodedText.replace( "__ddd_dcdea_triple_dot__", "...")

            //break long text to sentence and start reading.
            textToSpeakArray = ArrayList(
                encodedText.split(splitKey)
            )
            textToSpeakLength = textToSpeakArray.size

            val sentence: String = getCurrentSentence()
            textToSpeakArrayPosition = textToSpeakArrayPosition + 1
            return tts!!.speak(sentence, TextToSpeech.QUEUE_FLUSH, bundle, uuid) == 0
        }
        isTtsInitialized = false
        tts = TextToSpeech(context, onInitListener, googleTtsEngine)
        return false
    }

    private fun stop() {
        tts!!.stop()
    }

    private val maxSpeechInputLength: Int
        get() = TextToSpeech.getMaxSpeechInputLength()

    private fun synthesizeToFile(text: String, fileName: String) {
        val file = File(context!!.getExternalFilesDir(null), fileName)
        val uuid: String = UUID.randomUUID().toString()
        bundle!!.putString(
            TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID,
            SYNTHESIZE_TO_FILE_PREFIX + uuid
        )
        val result: Int =
            tts!!.synthesizeToFile(text, bundle, file, SYNTHESIZE_TO_FILE_PREFIX + uuid)
        if (result == TextToSpeech.SUCCESS) {
            Log.d(tag, "Successfully created file : " + file.path)
        } else {
            Log.d(tag, "Failed creating file : " + file.path)
        }
    }

    private fun invokeMethod(method: String, arguments: Any) {
        handler!!.post {
            if (methodChannel != null) methodChannel!!.invokeMethod(
                method,
                arguments
            )
        }
    }

    private fun ismServiceConnectionUsable(tts: TextToSpeech?): Boolean {
        var isBindConnection = true
        if (tts == null) {
            return false
        }
        val fields: Array<Field> = tts.javaClass.declaredFields
        for (j in fields.indices) {
            fields[j].isAccessible = true
            if ("mServiceConnection" == fields[j].name && "android.speech.tts.TextToSpeech\$Connection" == fields[j].type.name) {
                try {
                    if (fields[j][tts] == null) {
                        isBindConnection = false
                        Log.e(tag, "*******TTS -> mServiceConnection == null*******")
                    }
                } catch (e: IllegalArgumentException) {
                    e.printStackTrace()
                } catch (e: IllegalAccessException) {
                    e.printStackTrace()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        return isBindConnection
    }

    companion object {
        private const val SILENCE_PREFIX = "SIL_"
        private const val SYNTHESIZE_TO_FILE_PREFIX = "STF_"

        /** Plugin registration.  */
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val instance = FlutterTtsPlugin()
            instance.initInstance(registrar.messenger(), registrar.activeContext())
        }
    }

    //returns where the sentence we are reading 
    //starts in the text and wher it ends
    private fun calculateStartAndEndAt(position: Int): HashMap<String, Int> {
        val pos = HashMap<String, Int>()
        var startAt = 0
        val currentSentence: String = textToSpeakArray[position]

        for (i in 0..position) {
            if (i == position) break
            startAt += textToSpeakArray[i].length
        }

        pos.put("startAt", startAt)
        pos.put("endAt", startAt + currentSentence.length)
        return pos
    }

    //returns the decoded sentence we are reading
    private fun getCurrentSentence(): String {
        return textToSpeakArray[textToSpeakArrayPosition]
    }
}