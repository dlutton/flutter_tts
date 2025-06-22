
  <!---
  This document provides a detailed description of a contribution to modernize the Android plugin of the `flutter_tts` library.
  It describes the goals, the components that will be modified, and the changes to be made.
  It also provides information about the testing plan and the expected results.
  -->
## 📄 وصف دقيق لمساهمة تعديل مكتبة `flutter_tts`

````markdown
# 📦 Flutter TTS – Android Plugin Modernization

## 🧠 الفكرة العامة
هدفي هو تحديث الكود الخاص بمنصة Android في مكتبة `flutter_tts`، وذلك للتخلص من استخدام واجهات برمجة التطبيقات (APIs) القديمة مثل `PluginRegistry.Registrar`، والتي أصبحت مهملة (deprecated) رسميًا من قِبل Flutter.

سأقوم بترحيل الكود إلى استخدام واجهات حديثة مثل:
- `FlutterPlugin`
- `onAttachedToEngine`
- `ActivityAware`

---

## 🎯 الهدف من التعديل
- إزالة التحذيرات أثناء بناء التطبيق (build warnings)
- جعل المكتبة متوافقة مع بنية Flutter Plugin الحديثة
- تحسين قابلية الصيانة
- تمهيد الطريق لتطوير مستقبلية (مثل إضافة دعم لأنظمة Android الجديدة)

---

## 🧱 المكونات التي سيتم تعديلها
```text
android/src/main/kotlin/com/tundralabs/fluttertts/FlutterTtsPlugin.kt
````

### التعديلات:

1. إزالة الاعتماد على:

   ```kotlin
   registrar: PluginRegistry.Registrar
   ```

2. إضافة الكلاس التالي:

   ```kotlin
   class FlutterTtsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware
   ```

3. تنفيذ:

   * `onAttachedToEngine`
   * `onDetachedFromEngine`
   * `onAttachedToActivity`
   * `onDetachedFromActivity`
   * `onReattachedToActivityForConfigChanges`
   * `onDetachedFromActivityForConfigChanges`

4. التأكد من دعم جميع الدوال الأساسية الموجودة مسبقًا مثل:

   * speak()
   * stop()
   * setLanguage()
   * setPitch()
   * setSpeechRate()

---
## ✅ خطوات العمل

2. تعديل الكود كما في الأعلى
3. اختبار المكتبة على مشروع Flutter حقيقي
4. رفع التعديلات على GitHub
5. فتح Pull Request موثّق يحتوي:

   * وصف المشكلة
   * الفروقات
   * خطوات الاختبار

---

## ⚠️ الأمور التي لن يتم تعديلها

* **كود iOS** لن يتم المساس به.
* **وظائف TTS نفسها** ستبقى كما هي (الهدف فقط هو تغيير بنية الربط).

---

## 🧪 خطة الاختبار

* اختبار على محاكي Android (API 30 و 33)
* اختبار على جهاز حقيقي
* التحقق من:

  * نطق الجمل (speak)
  * تغيير اللغة والصوت
  * سرعة ونغمة الصوت

---

## 👤 الخبرة

أنا مطوّر Flutter بخبرة ضعيفة  في تطوير تطبيقات Android وiOS، وأعمل على تحسين البنية التحتية لمكتبة `flutter_tts` لتتوافق مع معايير Flutter الحديثة، وتحسين تجربة المطورين والمستخدمين.

---

## 📂 موقع الملف داخل المشروع

```text
📁 flutter_tts/
 └── 📁 docs/
      └── 📄 PluginMigrationContext.md
```

---