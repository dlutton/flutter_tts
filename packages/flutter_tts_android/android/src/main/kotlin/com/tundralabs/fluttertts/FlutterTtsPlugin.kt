package com.tundralabs.fluttertts

import android.content.ContentValues
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import java.lang.reflect.Field
import java.util.Locale
import java.util.MissingResourceException
import java.util.UUID

typealias ResultCallback<T> = (Result<T>) -> Unit

fun <T> FlutterTtsErrorCode.toKtResult(): Result<T> {
    return Result.failure(FlutterError("FlutterTtsErrorCode.$raw", name))
}

/** FlutterTtsPlugin  */
class FlutterTtsPlugin : FlutterPlugin, TtsHostApi, AndroidTtsHostApi {
    private val kTtsInitTimeOutMs: Long = 1000

    private var handler: Handler? = null
    private var speakResult: ResultCallback<TtsResult>? = null
    private var synthResult: ResultCallback<TtsResult>? = null
    private var awaitSpeakCompletion = false
    private var speaking = false
    private var awaitSynthCompletion = false
    private var synth = false
    private var context: Context? = null
    private var tts: TextToSpeech? = null
    private val tag = "TTS"
    private val pendingMethodCalls = ArrayList<Runnable>()
    private val utterances = HashMap<String, String>()
    private var bundle: Bundle? = null
    private var silenceMs = 0
    private var lastProgress = 0
    private var currentText: String? = null
    private var pauseText: String? = null
    private var isPaused: Boolean = false
    private var queueMode: Int = TextToSpeech.QUEUE_FLUSH
    private var ttsStatus: Int? = null
    private var selectedEngine: String? = null
    private var engineResult: ResultCallback<TtsResult>? = null
    private var parcelFileDescriptor: ParcelFileDescriptor? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private var flutterApi: TtsFlutterApi? = null

    companion object {
        private const val SILENCE_PREFIX = "SIL_"
        private const val SYNTHESIZE_TO_FILE_PREFIX = "STF_"
    }

    private fun initInstance(context: Context) {
        this.context = context
        handler = Handler(Looper.getMainLooper())
        bundle = Bundle()

        handler?.postDelayed(onInitTimeoutRunnable, kTtsInitTimeOutMs)
        tts = TextToSpeech(context, onInitListenerWithoutCallback)
    }

    /** Android Plugin APIs  */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterApi = TtsFlutterApi(binding.binaryMessenger)
        initInstance(binding.applicationContext)
        TtsHostApi.setUp(binding.binaryMessenger, this)
        AndroidTtsHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopImpl()
        tts!!.shutdown()
        TtsHostApi.setUp(binding.binaryMessenger, null)
        AndroidTtsHostApi.setUp(binding.binaryMessenger, null)
        context = null
    }

    private val utteranceProgressListener: UtteranceProgressListener =
        object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String) {
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    handler?.post {
                        flutterApi?.onSynthStartCb { }
                    }
                } else {
                    if (isPaused) {
                        handler?.post {
                            flutterApi?.onSpeakResumeCb { }
                        }
                        isPaused = false
                    } else {
                        Log.d(tag, "Utterance ID has started: $utteranceId")
                        handler?.post {
                            flutterApi?.onSpeakStartCb { }
                        }
                    }
                }
                if (Build.VERSION.SDK_INT < 26) {
                    onProgress(utteranceId, 0, utterances[utteranceId]!!.length)
                }
            }

            override fun onDone(utteranceId: String) {
                if (utteranceId.startsWith(SILENCE_PREFIX)) return
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    closeParcelFileDescriptor(false)
                    Log.d(tag, "Utterance ID has completed: $utteranceId")
                    if (awaitSynthCompletion) {
                        synthCompletion(1)
                    }

                    handler?.post {
                        flutterApi?.onSynthCompleteCb { }
                    }
                } else {
                    Log.d(tag, "Utterance ID has completed: $utteranceId")
                    if (awaitSpeakCompletion && queueMode == TextToSpeech.QUEUE_FLUSH) {
                        speakCompletion(1)
                    }

                    handler?.post {
                        flutterApi?.onSpeakCompleteCb { }
                    }
                }
                lastProgress = 0
                pauseText = null
                utterances.remove(utteranceId)
                releaseAudioFocus()
            }

            override fun onStop(utteranceId: String, interrupted: Boolean) {
                Log.d(
                    tag, "Utterance ID has been stopped: $utteranceId. Interrupted: $interrupted"
                )
                if (awaitSpeakCompletion) {
                    speaking = false
                }
                if (isPaused) {
                    handler?.post {
                        flutterApi?.onSpeakPauseCb { }
                    }
                } else {
                    handler?.post {
                        flutterApi?.onSpeakCancelCb { }
                    }
                }
                releaseAudioFocus()
            }

            private fun onProgress(utteranceId: String?, startAt: Int, endAt: Int) {
                if (utteranceId != null && !utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    val text = utterances[utteranceId]
                    if (text != null) {
                        var data = TtsProgress(
                            text = text,
                            start = startAt.toLong(),
                            end = endAt.toLong(),
                            word = text.substring(startAt, endAt)
                        )

                        handler?.post {
                            flutterApi?.onSpeakProgressCb(data) { }
                        }
                    }
                }
            }

            // Requires Android 26 or later
            override fun onRangeStart(utteranceId: String, startAt: Int, endAt: Int, frame: Int) {
                if (!utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    lastProgress = startAt
                    super.onRangeStart(utteranceId, startAt, endAt, frame)
                    onProgress(utteranceId, startAt, endAt)
                }
            }

            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String) {
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    closeParcelFileDescriptor(true)
                    if (awaitSynthCompletion) {
                        synth = false
                    }

                    handler?.post {
                        flutterApi?.onSynthErrorCb("Error from TextToSpeech (synth)") {}
                    }
                } else {
                    if (awaitSpeakCompletion) {
                        speaking = false
                    }

                    handler?.post {
                        flutterApi?.onSpeakErrorCb("Error from TextToSpeech (speak)") {}
                    }
                }
                releaseAudioFocus()
            }

            override fun onError(utteranceId: String, errorCode: Int) {
                if (utteranceId.startsWith(SYNTHESIZE_TO_FILE_PREFIX)) {
                    closeParcelFileDescriptor(true)
                    if (awaitSynthCompletion) {
                        synth = false
                    }

                    handler?.post {
                        flutterApi?.onSynthErrorCb("Error from TextToSpeech (synth) - $errorCode") {}
                    }
                } else {
                    if (awaitSpeakCompletion) {
                        speaking = false
                    }
                    handler?.post {
                        flutterApi?.onSpeakErrorCb("Error from TextToSpeech (speak) - $errorCode") {}
                    }
                }
            }
        }

    fun speakCompletion(success: Int) {
        speaking = false
        handler!!.post {
            speakResult?.invoke(Result.success(TtsResult(success != 0)))
            speakResult = null
        }
    }

    fun synthCompletion(success: Int) {
        synth = false
        handler!!.post {
            synthResult?.invoke(Result.success(TtsResult(success != 0)))
            synthResult = null
        }
    }

    private val onInitListenerWithCallback: TextToSpeech.OnInitListener =
        TextToSpeech.OnInitListener { status ->
            handler?.removeCallbacks(onInitTimeoutRunnable)
            // Handle pending method calls (sent while TTS was initializing)
            synchronized(this@FlutterTtsPlugin) {
                ttsStatus = status
                for (call in pendingMethodCalls) {
                    call.run()
                }
                pendingMethodCalls.clear()
            }

            if (status == TextToSpeech.SUCCESS) {
                tts!!.setOnUtteranceProgressListener(utteranceProgressListener)
                try {
                    val locale: Locale = tts!!.defaultVoice.locale
                    if (isLanguageAvailableImpl(locale)) {
                        tts!!.language = locale
                    }
                } catch (e: NullPointerException) {
                    Log.e(tag, "getDefaultLocale: " + e.message)
                } catch (e: IllegalArgumentException) {
                    Log.e(tag, "getDefaultLocale: " + e.message)
                }

                engineResult?.invoke(Result.success(TtsResult(true)))
            } else {
                engineResult?.invoke(
                    FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult()
                )
            }
            //engineResult = null
        }

    private val onInitTimeoutRunnable = Runnable {
        Log.e("TTS", "TTS init timeout")

        engineResult?.invoke(FlutterTtsErrorCode.TTS_INIT_TIMEOUT.toKtResult())

        ttsStatus = TextToSpeech.ERROR
        for (call in pendingMethodCalls) {
            call.run()
        }
        pendingMethodCalls.clear()
    }

    private val onInitListenerWithoutCallback: TextToSpeech.OnInitListener =
        TextToSpeech.OnInitListener { status ->
            handler?.removeCallbacks(onInitTimeoutRunnable)
            // Handle pending method calls (sent while TTS was initializing)
            synchronized(this@FlutterTtsPlugin) {
                ttsStatus = status
                for (call in pendingMethodCalls) {
                    call.run()
                }
                pendingMethodCalls.clear()
            }

            if (status == TextToSpeech.SUCCESS) {
                tts!!.setOnUtteranceProgressListener(utteranceProgressListener)
                try {
                    val locale: Locale = tts!!.defaultVoice.locale
                    if (isLanguageAvailableImpl(locale)) {
                        tts!!.language = locale
                    }
                } catch (e: NullPointerException) {
                    Log.e(tag, "getDefaultLocale: " + e.message)
                } catch (e: IllegalArgumentException) {
                    Log.e(tag, "getDefaultLocale: " + e.message)
                }
            } else {
                Log.e(tag, "Failed to initialize TextToSpeech with status: $status")
            }
        }

    private fun setSpeechRateImpl(rate: Float) {
        tts!!.setSpeechRate(rate)
    }

    private fun isLanguageAvailableImpl(locale: Locale?): Boolean {
        return tts!!.isLanguageAvailable(locale) >= TextToSpeech.LANG_AVAILABLE
    }

    private fun areLanguagesInstalledImpl(languages: List<String>): Map<String, Boolean> {
        val result: MutableMap<String, Boolean> = HashMap()
        for (language in languages) {
            result[language] = isLanguageInstalledImpl(language)
        }
        return result
    }

    private fun isLanguageInstalledImpl(language: String?): Boolean {
        val locale: Locale = Locale.forLanguageTag(language!!)
        if (isLanguageAvailableImpl(locale)) {
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

    private fun setEngineImpl(engine: String?, result: ResultCallback<TtsResult>) {
        ttsStatus = null
        selectedEngine = engine
        engineResult = result

        handler?.postDelayed(onInitTimeoutRunnable, kTtsInitTimeOutMs)
        tts = TextToSpeech(context, onInitListenerWithCallback, engine)
    }

    private fun setVoiceImpl(
        voice: com.tundralabs.fluttertts.Voice, callback: (Result<TtsResult>) -> Unit
    ) {
        for (ttsVoice in tts!!.voices) {
            if (ttsVoice.name == voice.name && ttsVoice.locale.toLanguageTag() == voice.locale) {
                tts!!.voice = ttsVoice
                callback(Result.success(TtsResult(true)))
                return
            }
        }
        Log.d(tag, "Voice name not found: $voice")
        callback(Result.success(TtsResult(false)))
    }

    private fun clearVoiceImpl(callback: ResultCallback<TtsResult>) {
        tts!!.voice = tts!!.defaultVoice
        callback(Result.success(TtsResult(true)))
    }

    private fun setVolumeImpl(volume: Float, callback: ResultCallback<TtsResult>) {
        if (volume in (0.0f..1.0f)) {
            bundle!!.putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume)
            callback(Result.success(TtsResult(true)))
        } else {
            Log.d(tag, "Invalid volume $volume value - Range is from 0.0 to 1.0")
            callback(Result.success(TtsResult(false)))
        }
    }

    private fun setPitchImpl(pitch: Float, callback: ResultCallback<TtsResult>) {
        if (pitch in (0.5f..2.0f)) {
            tts!!.setPitch(pitch)
            callback(Result.success(TtsResult(true)))
        } else {
            Log.d(tag, "Invalid pitch $pitch value - Range is from 0.5 to 2.0")
            callback(Result.success(TtsResult(false)))
        }
    }

    private fun getVoicesImpl(result: ResultCallback<List<com.tundralabs.fluttertts.Voice>>) {
        val voices = ArrayList<com.tundralabs.fluttertts.Voice>()
        try {
            for (voice in tts!!.voices) {
                voices.add(readVoiceProperties(voice))
            }
            result(Result.success(voices))
        } catch (e: NullPointerException) {
            Log.d(tag, "getVoices: " + e.message)
            result(Result.success(voices))
        }
    }

    private fun getLanguagesImpl(result: ResultCallback<List<String>>) {
        val locales = ArrayList<String>()
        try {
            // While this method was introduced in API level 21, it seems that it
            // has not been implemented in the speech service side until API Level 23.
            for (locale in tts!!.availableLanguages) {
                locales.add(locale.toLanguageTag())
            }
        } catch (e: MissingResourceException) {
            Log.d(tag, "getLanguages: " + e.message)
        } catch (e: NullPointerException) {
            Log.d(tag, "getLanguages: " + e.message)
        }
        result(Result.success(locales))
    }

    private fun getEnginesImpl(result: ResultCallback<List<String>>) {
        val engines = ArrayList<String>()
        try {
            for (engineInfo in tts!!.engines) {
                engines.add(engineInfo.name)
            }
        } catch (e: Exception) {
            Log.d(tag, "getEngines: " + e.message)
        }
        result(Result.success(engines))
    }

    private fun getDefaultEngineImpl(result: ResultCallback<String?>) {
        val defaultEngine: String? = tts!!.defaultEngine
        result(Result.success(defaultEngine))
    }

    private fun getDefaultVoiceImpl(result: ResultCallback<com.tundralabs.fluttertts.Voice?>) {
        val defaultVoice: Voice? = tts!!.defaultVoice
        var voice: com.tundralabs.fluttertts.Voice? = null
        if (defaultVoice != null) {
            voice = readVoiceProperties(defaultVoice)
        }
        result(Result.success(voice))
    }

    // Add voice properties into the voice map
    fun readVoiceProperties(voice: Voice): com.tundralabs.fluttertts.Voice {
        return Voice(
            voice.name, voice.locale.toLanguageTag(), null, qualityToString(voice.quality), null
        )
    }

    // Function to map quality integer to the constant name
    fun qualityToString(quality: Int): String {
        return when (quality) {
            Voice.QUALITY_VERY_HIGH -> "very high"
            Voice.QUALITY_HIGH -> "high"
            Voice.QUALITY_NORMAL -> "normal"
            Voice.QUALITY_LOW -> "low"
            Voice.QUALITY_VERY_LOW -> "very low"
            else -> "unknown"
        }
    }

    private fun getSpeechRateValidRangeImpl(result: ResultCallback<TtsRateValidRange>) {
        // Valid values available in the android documentation.
        // https://developer.android.com/reference/android/speech/tts/TextToSpeech#setSpeechRate(float)
        // To make the FlutterTts API consistent across platforms,
        // we map Android 1.0 to flutter 0.5 and so on.
        val data = TtsRateValidRange(
            0.0, 0.5, 1.5, TtsPlatform.ANDROID
        )
        result(Result.success(data))
    }

    private fun speakImpl(text: String, focus: Boolean): Boolean {
        val uuid: String = UUID.randomUUID().toString()
        utterances[uuid] = text
        return if (ismServiceConnectionUsable(tts)) {
            if (focus) {
                requestAudioFocus()
            }

            if (silenceMs > 0) {
                tts!!.playSilentUtterance(
                    silenceMs.toLong(), TextToSpeech.QUEUE_FLUSH, SILENCE_PREFIX + uuid
                )
                tts!!.speak(text, TextToSpeech.QUEUE_ADD, bundle, uuid) == 0
            } else {
                tts!!.speak(text, queueMode, bundle, uuid) == 0
            }
        } else {
            ttsStatus = null
            handler?.postDelayed(onInitTimeoutRunnable, kTtsInitTimeOutMs)
            tts = TextToSpeech(context, onInitListenerWithoutCallback, selectedEngine)
            false
        }
    }

    private fun stopImpl() {
        if (awaitSynthCompletion) synth = false
        if (awaitSpeakCompletion) speaking = false
        tts!!.stop()
    }

    private val maxSpeechInputLength: Int
        get() = TextToSpeech.getMaxSpeechInputLength()

    private fun closeParcelFileDescriptor(isError: Boolean) {
        if (this.parcelFileDescriptor != null) {
            if (isError) {
                this.parcelFileDescriptor!!.closeWithError("Error synthesizing TTS to file")
            } else {
                this.parcelFileDescriptor!!.close()
            }
        }
    }

    private fun synthesizeToFileImpl(text: String, fileName: String, isFullPath: Boolean) {
        val fullPath: String
        val uuid: String = UUID.randomUUID().toString()
        bundle!!.putString(
            TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, SYNTHESIZE_TO_FILE_PREFIX + uuid
        )

        val result: Int = if (isFullPath) {
            val file = File(fileName)
            fullPath = file.path

            tts!!.synthesizeToFile(text, bundle!!, file, SYNTHESIZE_TO_FILE_PREFIX + uuid)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val resolver = this.context?.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "audio/wav")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_MUSIC)
            }
            val uri = resolver?.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, contentValues)
            this.parcelFileDescriptor = resolver?.openFileDescriptor(uri!!, "rw")
            fullPath = uri?.path + File.separatorChar + fileName

            tts!!.synthesizeToFile(
                text, bundle!!, parcelFileDescriptor!!, SYNTHESIZE_TO_FILE_PREFIX + uuid
            )
        } else {
            val musicDir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
            val file = File(musicDir, fileName)
            fullPath = file.path

            tts!!.synthesizeToFile(text, bundle!!, file, SYNTHESIZE_TO_FILE_PREFIX + uuid)
        }

        if (result == TextToSpeech.SUCCESS) {
            Log.d(tag, "Successfully created file : $fullPath")
        } else {
            Log.d(tag, "Failed creating file : $fullPath")
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

    // Method to set AudioAttributes for navigation usage
    private fun setAudioAttributesForNavigationImpl() {
        if (tts != null) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
            tts!!.setAudioAttributes(audioAttributes)
        }
    }

    private fun requestAudioFocus() {
        audioManager = context?.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest =
                AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setOnAudioFocusChangeListener { /* opcional para monitorar mudanças de foco */ }
                    .build()
            audioManager?.requestAudioFocus(audioFocusRequest!!)
        } else {
            audioManager?.requestAudioFocus(
                null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            )
        }
    }

    private fun releaseAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            audioManager?.abandonAudioFocus(null)
        }
    }

    override fun speak(
        text: String, forceFocus: Boolean, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { speak(text, forceFocus, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(
                    FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult()
                )
                return
            }
        }

        if (pauseText == null) {
            pauseText = text
            currentText = pauseText!!
        }

        if (isPaused) {
            // Ensure the text hasn't changed
            if (currentText != text) {
                pauseText = text
                currentText = pauseText!!
                lastProgress = 0
            }
        }
        if (speaking) {
            // If TTS is set to queue mode, allow the utterance to be queued up rather than discarded
            if (queueMode == TextToSpeech.QUEUE_FLUSH) {
                callback(Result.success(TtsResult(false)))
                return
            }
        }
        val b = speakImpl(text, forceFocus)
        if (!b) {
            synchronized(this@FlutterTtsPlugin) {
                speak(text, forceFocus, callback)
            }
            return
        }
        // Only use await speak completion if queueMode is set to QUEUE_FLUSH
        if (awaitSpeakCompletion && queueMode == TextToSpeech.QUEUE_FLUSH) {
            speaking = true
            speakResult = callback
        } else {
            callback(Result.success(TtsResult(true)))
        }

    }

    override fun pause(callback: (Result<TtsResult>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { pause(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(
                    FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult()
                )
                return
            }
        }

        isPaused = true
        if (pauseText != null) {
            pauseText = pauseText!!.substring(lastProgress)
        }
        stopImpl()
        callback(Result.success(TtsResult(true)))
        if (speakResult != null) {
            speakResult?.invoke(Result.success(TtsResult(false)))
            speakResult = null
        }
    }

    override fun stop(callback: (Result<TtsResult>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { stop(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(
                    FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult()
                )
                return
            }
        }

        isPaused = false
        pauseText = null
        stopImpl()
        lastProgress = 0
        callback(Result.success(TtsResult(true)))
        if (speakResult != null) {
            speakResult?.invoke(Result.success(TtsResult(false)))
            speakResult = null
        }
    }

    override fun setSpeechRate(
        rate: Double, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setSpeechRate(rate, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        // To make the FlutterTts API consistent across platforms,
        // Android 1.0 is mapped to flutter 0.5.
        setSpeechRateImpl(rate.toFloat() * 2.0f)
        callback(Result.success(TtsResult(true)))
    }

    override fun setVolume(
        volume: Double, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setVolume(volume, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        setVolumeImpl(volume.toFloat(), callback)
    }

    override fun setPitch(
        pitch: Double, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setPitch(pitch, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        setPitchImpl(pitch.toFloat(), callback)
    }

    override fun setVoice(
        voice: com.tundralabs.fluttertts.Voice, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setVoice(voice, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        setVoiceImpl(voice, callback)
    }

    override fun clearVoice(callback: (Result<TtsResult>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { clearVoice(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        clearVoiceImpl(callback)
    }

    override fun awaitSpeakCompletion(
        awaitCompletion: Boolean, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { awaitSpeakCompletion(awaitCompletion, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            }
        }

        awaitSpeakCompletion = awaitCompletion
        callback(Result.success(TtsResult(true)))
    }

    override fun getLanguages(callback: (Result<List<String>>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { getLanguages(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        getLanguagesImpl(callback)
    }

    override fun getVoices(callback: (Result<List<com.tundralabs.fluttertts.Voice>>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { getVoices(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        getVoicesImpl(callback)
    }

    override fun awaitSynthCompletion(
        awaitCompletion: Boolean, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { awaitSynthCompletion(awaitCompletion, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            }
        }

        awaitSynthCompletion = awaitCompletion
        callback(Result.success(TtsResult(true)))
    }

    override fun getMaxSpeechInputLength(callback: (Result<Long?>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { getMaxSpeechInputLength(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            }
        }

        callback(Result.success(maxSpeechInputLength.toLong()))
    }

    override fun setEngine(
        engine: String, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setEngine(engine, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            }
        }

        setEngineImpl(engine, callback)
    }

    override fun getEngines(callback: (Result<List<String>>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { getEngines(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            }
        }

        getEnginesImpl(callback)
    }

    override fun getDefaultEngine(callback: (Result<String?>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { getDefaultEngine(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        getDefaultEngineImpl(callback)
    }

    override fun getDefaultVoice(callback: (Result<com.tundralabs.fluttertts.Voice?>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { getDefaultVoice(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        getDefaultVoiceImpl(callback)
    }

    override fun synthesizeToFile(
        text: String, fileName: String, isFullPath: Boolean, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall =
                    Runnable { synthesizeToFile(text, fileName, isFullPath, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        if (synth) {
            callback(Result.success(TtsResult(false)))
            return
        }
        synthesizeToFileImpl(text, fileName, isFullPath)
        if (awaitSynthCompletion) {
            synth = true
            synthResult = callback
        } else {
            callback(Result.success(TtsResult(true)))
        }
    }

    override fun isLanguageInstalled(
        language: String, callback: (Result<Boolean>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { isLanguageInstalled(language, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        callback(Result.success(isLanguageInstalledImpl(language)))
    }

    override fun isLanguageAvailable(
        language: String, callback: (Result<Boolean>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { isLanguageAvailable(language, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        val locale: Locale = Locale.forLanguageTag(language)
        callback(Result.success(isLanguageAvailableImpl(locale)))
    }

    override fun areLanguagesInstalled(
        languages: List<String>, callback: (Result<Map<String, Boolean>>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { areLanguagesInstalled(languages, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        callback(Result.success(areLanguagesInstalledImpl(languages)))
    }

    override fun getSpeechRateValidRange(callback: (Result<TtsRateValidRange>) -> Unit) {
        getSpeechRateValidRangeImpl(callback)
    }

    override fun setSilence(
        timems: Long, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setSilence(timems, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            }
        }

        this.silenceMs = timems.toInt()
    }

    override fun setQueueMode(
        queueMode: Long, callback: (Result<TtsResult>) -> Unit
    ) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setQueueMode(queueMode, callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            }
        }

        this.queueMode = queueMode.toInt()
        callback(Result.success(TtsResult(true)))
    }

    override fun setAudioAttributesForNavigation(callback: (Result<TtsResult>) -> Unit) {
        synchronized(this@FlutterTtsPlugin) {
            if (ttsStatus == null) {
                // Suspend method call until the TTS engine is ready
                val suspendedCall = Runnable { setAudioAttributesForNavigation(callback); }
                pendingMethodCalls.add(suspendedCall)
                return
            } else if (ttsStatus != TextToSpeech.SUCCESS) {
                callback(FlutterTtsErrorCode.TTS_NOT_AVAILABLE.toKtResult())
                return
            }
        }

        setAudioAttributesForNavigationImpl()
        callback(Result.success(TtsResult(true)))
    }
}
