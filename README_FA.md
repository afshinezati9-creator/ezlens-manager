# آیکون + ورود دوقسمتی + رفع Application Password

## ۱) آیکون برنامه
فایل‌های `android/app/src/main/res/mipmap-*/ic_launcher.png` جایگزین شده‌اند.

برای آیکون اختصاصی خودتان:
1. یک PNG مربعی حداقل ۵۱۲×۵۱۲ بسازید
2. فایل‌ها را در همین پوشه‌های mipmap با نام `ic_launcher.png` بگذارید
   - mdpi 48 · hdpi 72 · xhdpi 96 · xxhdpi 144 · xxxhdpi 192
3. یا در پروژه: `flutter pub add flutter_launcher_icons` و در pubspec تنظیم کنید

بعد از تعویض آیکون حتماً APK را دوباره بیلد کنید.

## ۲) ورود
- تب **رمز برنامه**: نام کاربری + Application Password (چپ‌چین LTR)
- تب **کد پیامک**: وصل به `ezlens_otp_send` / `ezlens_otp_verify` پلاگین

### علت خطای Application Password
رمز عادی وردپرس قبول نیست. باید:
پیشخوان → کاربران → شناسنامه → **Application Passwords** → ساخت رمز جدید
همان رشته (با فاصله‌ها) را در اپ وارد کنید.

### باگ مهم اصلاح‌شده
بعد از ورود، API هنوز از `ApiConfig` ثابت استفاده می‌کرد؛ الان از credentials ذخیره‌شده در SecureStorage استفاده می‌کند.

## فایل‌ها
```
lib/features/auth/data/auth_repository.dart
lib/features/auth/presentation/auth_provider.dart
lib/features/auth/presentation/login_page.dart
lib/core/network/api_client.dart
android/app/src/main/res/mipmap-*/ic_launcher.png
web/icons/Icon-192.png
web/icons/Icon-512.png
```
