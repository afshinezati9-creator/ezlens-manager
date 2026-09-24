# ورود یوزر/رمز + OTP داخل پلاگین EzLens

## پلاگین (اجباری)
آپلود و فعال‌سازی:
`EzLens-Secure-Login-manager-auth.zip`

سپس: تنظیمات → پیوندهای یکتا → ذخیره

Endpointهای جدید:
- POST `/wp-json/ezlens/v1/manager/login` — یوزر + رمز عادی پیشخوان
- POST `/wp-json/ezlens/v1/manager/otp/send`
- POST `/wp-json/ezlens/v1/manager/otp/verify`

پشت‌صحنه Application Password برای REST ساخته می‌شود؛ کاربر فقط یوزر/رمز یا پیامک می‌زند.

## اپ Flutter
محتویات این zip را روی پروژه کپی کنید و در pubspec:

```yaml
flutter:
  assets:
    - assets/images/logo_ez.png
```

سپس push برای بیلد APK.
