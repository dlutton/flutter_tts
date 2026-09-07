package com.eyedeadevelopment.fluttertts

import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Locale
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.*

@RunWith(Parameterized::class)
class FlutterTtsInitializationTest(private val listenerName: String) {
    private lateinit var plugin: FlutterTtsPlugin
    private lateinit var engine: TextToSpeech
    private lateinit var engineResult: Result

    @Before
    fun setUp() {
        plugin = FlutterTtsPlugin()
        engine = mock(TextToSpeech::class.java)
        engineResult = mock(Result::class.java)
        val defaultVoice = mock(Voice::class.java)
        `when`(defaultVoice.locale).thenReturn(Locale.US)
        `when`(engine.defaultVoice).thenReturn(defaultVoice)
        field("tts").set(plugin, engine)
        field("engineResult").set(plugin, engineResult)
    }

    @Test
    fun initializesWithoutQueryingOrResettingTheEngineDefaultVoice() {
        initialize()

        verify(engine).setOnUtteranceProgressListener(any(UtteranceProgressListener::class.java))
        verifyNoMoreInteractions(engine)
        if (listenerName == "onInitListenerWithCallback") {
            verify(engineResult).success(1)
        } else {
            verifyNoInteractions(engineResult)
        }
    }

    @Test
    fun preservesAnExplicitLanguageRequestQueuedBeforeInitialization() {
        val result = mock(Result::class.java)
        `when`(engine.isLanguageAvailable(Locale.FRANCE)).thenReturn(TextToSpeech.LANG_COUNTRY_AVAILABLE)
        plugin.onMethodCall(MethodCall("setLanguage", "fr-FR"), result)
        verifyNoInteractions(result)

        initialize()

        verify(engine).isLanguageAvailable(Locale.FRANCE)
        verify(engine).setLanguage(Locale.FRANCE)
        verify(engine).setOnUtteranceProgressListener(any(UtteranceProgressListener::class.java))
        verifyNoMoreInteractions(engine)
        verify(result).success(1)
    }

    private fun initialize() {
        val listener = field(listenerName).get(plugin) as TextToSpeech.OnInitListener
        listener.onInit(TextToSpeech.SUCCESS)
    }

    private fun field(name: String) = FlutterTtsPlugin::class.java.getDeclaredField(name).apply {
        isAccessible = true
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun listeners() = listOf(
            arrayOf("onInitListenerWithoutCallback"),
            arrayOf("onInitListenerWithCallback"),
        )
    }
}
