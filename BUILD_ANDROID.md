# ساخت اپ اندروید — EzLens Manager

## پیش‌نیاز (یک‌بار)

1. نصب [Flutter](https://docs.flutter.dev/get-started/install) (Stable)
2. نصب Android Studio + SDK (API 34+)
3. پذیرش لایسنس‌ها:
```bash
flutter doctor --android-licenses
flutter doctor
```
باید ردیف Android toolchain تیک سبز داشته باشد.

---

## آماده‌سازی پروژه

```bash
cd C:\wamp64\www\ezlens-manager-flutter
# یا مسیر پروژه شما

# وابستگی‌های امنیتی/اعلان (اگر هنوز اضافه نشده)
# در pubspec.yaml:
#   local_auth: ^2.3.0
#   flutter_local_notifications: ^18.0.1

flutter pub get
```

### AndroidManifest — مجوزها

فایل: `android/app/src/main/AndroidManifest.xml`

داخل تگ `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### MainActivity — برای اثرانگشت

`android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
package ir.ezlens.manager   // مطابق applicationId خودتان

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

### applicationId

`android/app/build.gradle` (یا `.kts`):

```gradle
defaultConfig {
    applicationId "ir.ezlens.manager"
    minSdkVersion 24
    targetSdkVersion 34
    versionCode 1
    versionName "1.1.0"
}
```

---

## بیلد Debug (تست سریع)

```bash
flutter build apk --debug
```

خروجی:
`build/app/outputs/flutter-apk/app-debug.apk`

نصب روی گوشی:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## بیلد Release (انتشار)

### ۱) ساخت Keystore (یک‌بار)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

فایل را **خارج از گیت** نگه دارید.

### ۲) `android/key.properties` (در .gitignore است)

```properties
storePassword=***
keyPassword=***
keyAlias=upload
storeFile=../upload-keystore.jks
```

### ۳) اتصال signing در `android/app/build.gradle`

قبل از `android {`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

داخل `android {`:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled false
        shrinkResources false
    }
}
```

### ۴) ساخت APK یا App Bundle

```bash
# APK مستقیم برای نصب دستی / سایت
flutter build apk --release

# یا برای Google Play (توصیه)
flutter build appbundle --release
```

خروجی‌ها:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## کاهش حجم (اختیاری)

```bash
flutter build apk --release --split-per-abi
```

سه فایل جدا برای `armeabi-v7a` / `arm64-v8a` / `x86_64`.

---

## تست قبل از انتشار

- [ ] لاگین با Application Password واقعی
- [ ] لیست محصولات / سفارش‌ها / مشتریان
- [ ] ذخیره مقاله و اعمال محتوا
- [ ] اثرانگشت روی گوشی واقعی
- [ ] اعلان سفارش (برنامه باز)
- [ ] بدون کرش روی Android 12+

---

## انتشار

| کانال | فایل |
|--------|------|
| نصب مستقیم / سایت | `app-release.apk` |
| Google Play | `app-release.aab` + امضای Play App Signing |

برای GitHub Releases می‌توانید APK را ضمیمه کنید (بدون keystore و بدون secret).
