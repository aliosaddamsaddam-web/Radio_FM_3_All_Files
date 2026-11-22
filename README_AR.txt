Radio FM 3 — الملفات الأساسية

المشروع يتضمن:
- واجهة عربية.
- البحث عن محطات عبر Radio Browser وتشغيل بث الإنترنت.
- شاشة FM بترددات 87.5–108 MHz (واجهة توضيحية فقط).
- MainActivity.kt باستخدام Android Embedding V2 لتفادي خطأ Android v1 embedding.
- صلاحية الإنترنت.

طريقة التركيب في مشروع Klencod الحالي:
1. فك ضغط ZIP.
2. انسخ lib/main.dart إلى lib/main.dart في مشروعك.
3. استبدل pubspec.yaml.
4. انسخ MainActivity.kt إلى android/app/src/main/kotlin/com/radio/fm3/MainActivity.kt.
   إذا كان package name مختلفاً، عدّل سطر package ومسار المجلد ليطابقا اسم الحزمة في مشروعك.
5. استبدل android/app/src/main/AndroidManifest.xml بهذا الملف مع الحفاظ على أي إعدادات خاصة بقالبك عند الحاجة.
6. نفّذ Flutter Pub Get ثم Build APK أو:
   flutter build apk --release
7. الناتج عادة في build/app/outputs/flutter-apk/app-release.apk

تنبيه:
هذه الملفات تشغّل راديو الإنترنت عند وجود اتصال. وضع FM الحقيقي غير مفعّل؛ يحتاج مستقبل FM فعلياً مدعوماً وواجهة خاصة بالشركة المصنّعة. السماعة وحدها لا تكفي.
لم يتم إنشاء APK داخل ZIP؛ يجب بناؤه عبر Flutter/Klencod.
