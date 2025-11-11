#include "include/flutter_tts/flutter_tts_plugin.h"

#include <Windows.h>
// This must be included before many other Windows headers.

#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <ppltasks.h>

#include <map>
#include <memory>
#include <sstream>

#include "messages.g.h"

using namespace flutter_tts;

// #define FORCE_NON_DESKTOP

typedef std::function<void(ErrorOr<TtsResult> reply)> FlutterResult;

#if defined(WINAPI_FAMILY) && (WINAPI_FAMILY == WINAPI_FAMILY_DESKTOP_APP) && \
    !defined(FORCE_NON_DESKTOP)
#include <winrt/Windows.Media.Core.h>
#include <winrt/Windows.Media.Playback.h>
#include <winrt/Windows.Media.SpeechSynthesis.h>
using namespace winrt;
using namespace Windows::Media::SpeechSynthesis;
using namespace Concurrency;
using namespace std::chrono_literals;
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>

#else

#include <atlstr.h>
#include <sapi.h>

#include <array>
#include <string>
#pragma warning(disable : 4996)
#include <sphelper.h>
#pragma warning(default : 4996)

#endif

namespace {
class FlutterTtsPlugin : public flutter::Plugin, TtsHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
  FlutterTtsPlugin(flutter::BinaryMessenger* binary_messenger);
  virtual ~FlutterTtsPlugin();

  // override TTSHostApi
  virtual void Speak(
      const std::string& text, bool force_focus,
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void Pause(
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void Stop(
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void SetSpeechRate(
      double rate,
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void SetVolume(
      double volume,
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void SetPitch(
      double pitch,
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void SetVoice(
      const Voice& voice,
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void ClearVoice(
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void AwaitSpeakCompletion(
      bool await_completion,
      std::function<void(ErrorOr<TtsResult> reply)> result) override;
  virtual void GetLanguages(
      std::function<void(ErrorOr<flutter::EncodableList> reply)> result)
      override;
  virtual void GetVoices(
      std::function<void(ErrorOr<flutter::EncodableList> reply)> result)
      override;

#if defined(WINAPI_FAMILY) && (WINAPI_FAMILY == WINAPI_FAMILY_DESKTOP_APP) && \
    !defined(FORCE_NON_DESKTOP)
 private:
  void speak(const std::string, FlutterResult);
  void pause();
  void continuePlay();
  void stop();
  void setVolume(const double);
  void setPitch(const double);
  void setRate(const double);
  void getVoices(flutter::EncodableList&);
  void setVoice(const std::string&, const std::string&, FlutterResult&);
  void getLanguages(flutter::EncodableList&);
  void addMplayer();
  winrt::Windows::Foundation::IAsyncAction asyncSpeak(const std::string);
  bool speaking();
  bool paused();

  SpeechSynthesizer synth;
  winrt::Windows::Media::Playback::MediaPlayer mPlayer;
  bool isPaused;
  bool isSpeaking;
  bool awaitSpeakCompletion;
  FlutterResult speakResult;
  TtsFlutterApi flutterApi;

#else

  void speak(const std::string, FlutterResult);
  void pause();
  void continuePlay();
  void stop();
  void setVolume(const double);
  void setPitch(const double);
  void setRate(const double);
  void getVoices(flutter::EncodableList&);
  void setVoice(const std::string, const std::string, FlutterResult&);
  void getLanguages(flutter::EncodableList&);
  bool speaking();
  bool paused();

  ISpVoice* pVoice;
  bool awaitSpeakCompletion = false;
  bool isPaused;
  double pitch;
  FlutterResult speakResult;
  HANDLE addWaitHandle;

  TtsFlutterApi flutterApi;
#endif
};

void FlutterTtsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<FlutterTtsPlugin>(registrar->messenger());
  TtsHostApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

void FlutterTtsPlugin::Speak(
    const std::string& text, bool force_focus,
    std::function<void(ErrorOr<TtsResult> reply)> result) {
  if (isPaused) {
    continuePlay();
    result(std::move(TtsResult(true)));
    return;
  }

  if (!speaking()) {
    speak(text, std::move(result));
  } else {
    result(std::move(TtsResult(false)));
  }
}

void FlutterTtsPlugin::Pause(
    std::function<void(ErrorOr<TtsResult> reply)> result) {
  pause();
  result(std::move(TtsResult(true)));
}

void FlutterTtsPlugin::Stop(
    std::function<void(ErrorOr<TtsResult> reply)> result) {
  stop();
  result(std::move(TtsResult(true)));
}

void FlutterTtsPlugin::SetSpeechRate(
    double rate, std::function<void(ErrorOr<TtsResult> reply)> result) {
  setRate(rate);
  result(std::move(TtsResult(true)));
}

void FlutterTtsPlugin::SetVolume(
    double volume, std::function<void(ErrorOr<TtsResult> reply)> result) {
  setVolume(volume);
  result(std::move(TtsResult(true)));
}

void FlutterTtsPlugin::SetPitch(
    double newPitch, std::function<void(ErrorOr<TtsResult> reply)> result) {
  setPitch(newPitch);
  result(std::move(TtsResult(true)));
}

void FlutterTtsPlugin::SetVoice(
    const Voice& voice, std::function<void(ErrorOr<TtsResult> reply)> result) {
  setVoice(voice.locale(), voice.name(), result);
}

void FlutterTtsPlugin::ClearVoice(
    std::function<void(ErrorOr<TtsResult> reply)> result) {
  result(TtsResult(true));
}

void FlutterTtsPlugin::AwaitSpeakCompletion(
    bool await_completion,
    std::function<void(ErrorOr<TtsResult> reply)> result) {
  awaitSpeakCompletion = await_completion;
  result(std::move(TtsResult(true)));
}

void FlutterTtsPlugin::GetLanguages(
    std::function<void(ErrorOr<flutter::EncodableList> reply)> result) {
  flutter::EncodableList l;
  getLanguages(l);
  result(l);
}

void FlutterTtsPlugin::GetVoices(
    std::function<void(ErrorOr<flutter::EncodableList> reply)> result) {
  flutter::EncodableList l;
  getVoices(l);
  result(l);
}

#if defined(WINAPI_FAMILY) && (WINAPI_FAMILY == WINAPI_FAMILY_DESKTOP_APP) && \
    !defined(FORCE_NON_DESKTOP)

void FlutterTtsPlugin::addMplayer() {
  mPlayer = winrt::Windows::Media::Playback::MediaPlayer::MediaPlayer();
  auto mEndedToken = mPlayer.MediaEnded(
      [=](Windows::Media::Playback::MediaPlayer const& sender,
          Windows::Foundation::IInspectable const& args) {
        flutterApi.OnSpeakCompleteCb([]() {}, [](const FlutterError&) {});
        if (awaitSpeakCompletion) {
          speakResult(std::move(TtsResult(true)));
        }
        isSpeaking = false;
      });
}

bool FlutterTtsPlugin::speaking() { return isSpeaking; }

bool FlutterTtsPlugin::paused() { return isPaused; }

winrt::Windows::Foundation::IAsyncAction FlutterTtsPlugin::asyncSpeak(
    const std::string text) {
  SpeechSynthesisStream speechStream{
      co_await synth.SynthesizeTextToStreamAsync(to_hstring(text))};
  winrt::param::hstring cType = L"Audio";
  winrt::Windows::Media::Core::MediaSource source =
      winrt::Windows::Media::Core::MediaSource::CreateFromStream(speechStream,
                                                                 cType);
  mPlayer.Source(source);
  mPlayer.Play();
}

void FlutterTtsPlugin::speak(const std::string text, FlutterResult result) {
  isSpeaking = true;
  auto my_task{asyncSpeak(text)};
  flutterApi.OnSpeakStartCb([]() {}, [](const FlutterError&) {});
  if (awaitSpeakCompletion)
    speakResult = std::move(result);
  else {
    result(std::move(TtsResult(true)));
    // result(std::move(TtsResult(true)));
  }
}

void FlutterTtsPlugin::pause() {
  mPlayer.Pause();
  isPaused = true;
  flutterApi.OnSpeakPauseCb([]() {}, [](const FlutterError&) {});
}

void FlutterTtsPlugin::continuePlay() {
  mPlayer.Play();
  isPaused = false;
  flutterApi.OnSpeakResumeCb([]() {}, [](const FlutterError&) {});
}

void FlutterTtsPlugin::stop() {
  flutterApi.OnSpeakCancelCb([]() {}, [](const FlutterError&) {});
  if (awaitSpeakCompletion) {
    speakResult(std::move(TtsResult(true)));
  }

  mPlayer.Close();
  addMplayer();
  isSpeaking = false;
  isPaused = false;
}
void FlutterTtsPlugin::setVolume(const double newVolume) {
  synth.Options().AudioVolume(newVolume);
}

void FlutterTtsPlugin::setPitch(const double newPitch) {
  synth.Options().AudioPitch(newPitch);
}

void FlutterTtsPlugin::setRate(const double newRate) {
  synth.Options().SpeakingRate(newRate + 0.5);
}

void FlutterTtsPlugin::getVoices(flutter::EncodableList& voices) {
  auto synthVoices = synth.AllVoices();
  for (auto voice : synthVoices) {
    auto voiceInfo = Voice(to_string(voice.DisplayName()), to_string(voice.Language()));
    //  Convert VoiceGender to string
    std::string gender;
    switch (voice.Gender()) {
      case VoiceGender::Male:
        gender = "male";
        break;
      case VoiceGender::Female:
        gender = "female";
        break;
      default:
        gender = "unknown";
        break;
    }
    voiceInfo.set_gender(gender);
    // Identifier example
    // "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens\MSTTS_V110_enUS_MarkM"
    voiceInfo.set_identifier(to_string(voice.Id()));
    voices.push_back(flutter::CustomEncodableValue(voiceInfo));
  }
}

void FlutterTtsPlugin::setVoice(const std::string& voiceLanguage,
                                const std::string& voiceName,
                                FlutterResult& result) {
  bool found = false;
  auto voices = synth.AllVoices();
  VoiceInformation newVoice = synth.Voice();
  std::for_each(begin(voices), end(voices),
                [&voiceLanguage, &voiceName, &found,
                 &newVoice](const VoiceInformation& voice) {
                  if (to_string(voice.Language()) == voiceLanguage &&
                      to_string(voice.DisplayName()) == voiceName) {
                    newVoice = voice;
                    found = true;
                  }
                });
  synth.Voice(newVoice);
  if (found) {
    result(std::move(TtsResult(true)));
  } else {
    result(std::move(TtsResult(false)));
  }
}

void FlutterTtsPlugin::getLanguages(flutter::EncodableList& languages) {
  auto synthVoices = synth.AllVoices();
  std::set<flutter::EncodableValue> languagesSet = {};
  std::for_each(begin(synthVoices), end(synthVoices),
                [&languagesSet](const VoiceInformation& voice) {
                  languagesSet.insert(
                      flutter::EncodableValue(to_string(voice.Language())));
                });
  std::for_each(begin(languagesSet), end(languagesSet),
                [&languages](const flutter::EncodableValue value) {
                  languages.push_back(value);
                });
}

FlutterTtsPlugin::FlutterTtsPlugin(flutter::BinaryMessenger* binary_messenger)
    : flutterApi(TtsFlutterApi(binary_messenger)) {
  synth = SpeechSynthesizer();
  addMplayer();
  isPaused = false;
  isSpeaking = false;
  awaitSpeakCompletion = false;
  speakResult = FlutterResult();
}

FlutterTtsPlugin::~FlutterTtsPlugin() { mPlayer.Close(); }
#else

FlutterTtsPlugin::FlutterTtsPlugin(flutter::BinaryMessenger* binary_messenger)
    : flutterApi(TtsFlutterApi(binary_messenger)) {
  addWaitHandle = NULL;
  isPaused = false;
  speakResult = NULL;
  pVoice = NULL;
  HRESULT hr;
  hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
  if (FAILED(hr)) {
    throw std::exception("TTS init failed");
  }

  hr = CoCreateInstance(CLSID_SpVoice, NULL, CLSCTX_ALL, IID_ISpVoice,
                        (void**)&pVoice);
  if (FAILED(hr)) {
    throw std::exception("TTS create instance failed");
  }
  pitch = 0;
}

FlutterTtsPlugin::~FlutterTtsPlugin() { ::CoUninitialize(); }

void CALLBACK setResult(PVOID lpParam, BOOLEAN TimerOrWaitFired) {
  flutter::MethodResult<flutter::EncodableValue>* p =
      (flutter::MethodResult<flutter::EncodableValue>*)lpParam;
  p->Success(1);
}

void CALLBACK onCompletion(PVOID lpParam, BOOLEAN TimerOrWaitFired) {
  auto thisPointer = static_cast<FlutterTtsPlugin*>(lpParam);
  thisPointer->speakResult(TtsResult(true));
  thisPointer->flutterApi.OnSpeakCompleteCb([]() {},
                                            [](const FlutterError&) {});
}

bool FlutterTtsPlugin::speaking() {
  SPVOICESTATUS status;
  pVoice->GetStatus(&status, NULL);
  if (status.dwRunningState == SPRS_IS_SPEAKING) return true;
  return false;
}
bool FlutterTtsPlugin::paused() { return isPaused; }

void FlutterTtsPlugin::speak(const std::string text, FlutterResult result) {
  HRESULT hr;
  const std::string arg =
      "<PITCH MIDDLE = '" +
      std::to_string(int((pitch - 1) * 10 * (1 + (pitch < 1)))) + "'/>" + text;

  int wchars_num = MultiByteToWideChar(CP_UTF8, 0, arg.c_str(), -1, NULL, 0);
  wchar_t* wstr = new wchar_t[wchars_num];
  MultiByteToWideChar(CP_UTF8, 0, arg.c_str(), -1, wstr, wchars_num);
  hr = pVoice->Speak(wstr, 1, NULL);
  delete[] wstr;
  HANDLE speakCompletionHandle = pVoice->SpeakCompleteEvent();
  flutterApi.OnSpeakStartCb([]() {}, [](const FlutterError&) {});
  RegisterWaitForSingleObject(&addWaitHandle, speakCompletionHandle,
                              (WAITORTIMERCALLBACK)&onCompletion, this,
                              INFINITE, WT_EXECUTEONLYONCE);
  if (awaitSpeakCompletion) {
    speakResult = std::move(result);
    RegisterWaitForSingleObject(&addWaitHandle, speakCompletionHandle,
                                (WAITORTIMERCALLBACK)&setResult, this, INFINITE,
                                WT_EXECUTEONLYONCE);
  } else
    result(std::move(TtsResult(true)));
}
void FlutterTtsPlugin::pause() {
  if (isPaused == false) {
    pVoice->Pause();
    isPaused = true;
  }
  flutterApi.OnSpeakPauseCb([]() {}, [](const FlutterError&) {});
}
void FlutterTtsPlugin::continuePlay() {
  isPaused = false;
  pVoice->Resume();
  flutterApi.OnSpeakResumeCb([]() {}, [](const FlutterError&) {});
}
void FlutterTtsPlugin::stop() {
  pVoice->Speak(L"", 2, NULL);
  pVoice->Resume();
  isPaused = false;
  flutterApi.OnSpeakCancelCb([]() {}, [](const FlutterError&) {});
}
void FlutterTtsPlugin::setVolume(const double newVolume) {
  const USHORT volume = (short)(100 * newVolume);
  pVoice->SetVolume(volume);
}
void FlutterTtsPlugin::setPitch(const double newPitch) { pitch = newPitch; }
void FlutterTtsPlugin::setRate(const double newRate) {
  const long speechRate = (long)((newRate - 0.5) * 15);
  pVoice->SetRate(speechRate);
}
void FlutterTtsPlugin::getVoices(flutter::EncodableList& voices) {
  HRESULT hr;
  IEnumSpObjectTokens* cpEnum = NULL;
  hr = SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum);
  if (FAILED(hr)) return;

  ULONG ulCount = 0;
  // Get the number of voices.
  hr = cpEnum->GetCount(&ulCount);
  if (FAILED(hr)) return;
  ISpObjectToken* cpVoiceToken = NULL;
  while (ulCount--) {
    cpVoiceToken = NULL;
    hr = cpEnum->Next(1, &cpVoiceToken, NULL);
    if (FAILED(hr)) return;
    CComPtr<ISpDataKey> cpAttribKey;
    hr = cpVoiceToken->OpenKey(L"Attributes", &cpAttribKey);
    if (FAILED(hr)) return;
    WCHAR* psz = NULL;
    hr = cpAttribKey->GetStringValue(L"Language", &psz);
    wchar_t locale[25];
    LCIDToLocaleName((LCID)std::strtol(CW2A(psz), NULL, 16), locale, 25, 0);
    ::CoTaskMemFree(psz);
    std::string language = CW2A(locale);
    psz = NULL;
    cpAttribKey->GetStringValue(L"Name", &psz);
    std::string name = CW2A(psz);
    ::CoTaskMemFree(psz);
    auto voiceInfo = Voice (name, language);
    voices.push_back(flutter::CustomEncodableValue(voiceInfo));
    cpVoiceToken->Release();
  }
}
void FlutterTtsPlugin::setVoice(const std::string voiceLanguage,
                                const std::string voiceName,
                                FlutterResult& result) {
  HRESULT hr;
  IEnumSpObjectTokens* cpEnum = NULL;
  hr = SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum);
  if (FAILED(hr)) {
    result(std::move(TtsResult(false)));
    return;
  }
  ULONG ulCount = 0;
  hr = cpEnum->GetCount(&ulCount);
  if (FAILED(hr)) {
    result(std::move(TtsResult(false)));
    return;
  }
  ISpObjectToken* cpVoiceToken = NULL;
  bool success = false;
  while (ulCount--) {
    cpVoiceToken = NULL;
    hr = cpEnum->Next(1, &cpVoiceToken, NULL);
    if (FAILED(hr)) {
      result(std::move(TtsResult(false)));
      return;
    }
    CComPtr<ISpDataKey> cpAttribKey;
    hr = cpVoiceToken->OpenKey(L"Attributes", &cpAttribKey);
    if (FAILED(hr)) {
      result(std::move(TtsResult(false)));
      return;
    }
    WCHAR* psz = NULL;
    hr = cpAttribKey->GetStringValue(L"Name", &psz);
    if (FAILED(hr)) {
      result(std::move(TtsResult(false)));
      return;
    }
    std::string name = CW2A(psz);
    ::CoTaskMemFree(psz);
    psz = NULL;
    hr = cpAttribKey->GetStringValue(L"Language", &psz);
    wchar_t locale[25];
    LCIDToLocaleName((LCID)std::strtol(CW2A(psz), NULL, 16), locale, 25, 0);
    ::CoTaskMemFree(psz);
    std::string language = CW2A(locale);
    if (name == voiceName && language == voiceLanguage) {
      pVoice->SetVoice(cpVoiceToken);
      success = true;
    }
    cpVoiceToken->Release();
  }
  result(TtsResult(success));
}
void FlutterTtsPlugin::getLanguages(flutter::EncodableList& languages) {
  HRESULT hr;
  IEnumSpObjectTokens* cpEnum = NULL;
  hr = SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum);
  if (FAILED(hr)) return;

  ULONG ulCount = 0;
  // Get the number of voices.
  hr = cpEnum->GetCount(&ulCount);
  if (FAILED(hr)) return;
  ISpObjectToken* cpVoiceToken = NULL;
  std::set<flutter::EncodableValue> languagesSet = {};
  while (ulCount--) {
    cpVoiceToken = NULL;
    hr = cpEnum->Next(1, &cpVoiceToken, NULL);
    if (FAILED(hr)) return;
    CComPtr<ISpDataKey> cpAttribKey;
    hr = cpVoiceToken->OpenKey(L"Attributes", &cpAttribKey);
    if (FAILED(hr)) return;

    WCHAR* psz = NULL;
    hr = cpAttribKey->GetStringValue(L"Language", &psz);
    wchar_t locale[25];
    LCIDToLocaleName((LCID)std::strtol(CW2A(psz), NULL, 16), locale, 25, 0);
    std::string language = CW2A(locale);
    languagesSet.insert(flutter::EncodableValue(language));
    ::CoTaskMemFree(psz);
    cpVoiceToken->Release();
  }
  std::for_each(begin(languagesSet), end(languagesSet),
                [&languages](const flutter::EncodableValue value) {
                  languages.push_back(value);
                });
}
#endif

}  // namespace

void FlutterTtsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FlutterTtsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
