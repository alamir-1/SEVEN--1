# SEVEN1 WebView App

تطبيق Flutter بسيط يعرض الموقع:
https://alamir-1.github.io/SEVEN1/

## المشروع جاهز بالكامل ✅

جميع الملفات التالية جاهزة ولا تحتاج أي كتابة كود إضافية:
- `lib/main.dart` — الكود الكامل لعرض WebView
- `pubspec.yaml` — يحتوي على حزمة `webview_flutter`
- `android/app/src/main/AndroidManifest.xml` — يحتوي على صلاحية الإنترنت
- ملفات Gradle والأيقونات جاهزة أيضاً

## خطوات التشغيل على جهازك (3 أوامر فقط)

**المتطلبات:** يجب تثبيت Flutter SDK على جهازك أولاً (هذه الخطوة الوحيدة التي لا يمكنني القيام بها نيابة عنك، لأنني أعمل داخل بيئة سحابية بدون اتصال إنترنت ولا أستطيع تثبيت برامج على جهازك).
تثبيت Flutter من هنا: https://docs.flutter.dev/get-started/install

بعد فك ضغط المجلد وتثبيت Flutter، افتح الطرفية (Terminal / CMD) داخل مجلد المشروع ونفّذ:

```bash
# 1. تحميل الحزم المطلوبة
flutter pub get

# 2. تشغيل التطبيق على جهاز متصل أو محاكي
flutter run

# 3. أو بناء ملف APK جاهز للتثبيت مباشرة
flutter build apk --release
```

بعد الأمر الثالث ستجد ملف الـ APK هنا:
```
build/app/outputs/flutter-apk/app-release.apk
```
انسخه إلى هاتفك وثبّته مباشرة.

## ملاحظات

- اسم الحزمة (Package Name) الحالي هو: `com.example.seven1_webview` — يمكنك تغييره لاحقاً إذا أردت نشر التطبيق على متجر Google Play.
- الأيقونة الحالية دائرة بيضاء على خلفية زرقاء (بسيطة مؤقتة) — يمكنك استبدالها بسهولة عبر أداة:
  https://pub.dev/packages/flutter_launcher_icons
- يدعم الكود زر الرجوع (Back) للتنقل داخل صفحات الموقع بدل إغلاق التطبيق مباشرة.
