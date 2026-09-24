# ارسال به GitHub — EzLens Manager

## هشدار امنیتی (اجباری)

قبل از `git push` این‌ها را از ریپو حذف کنید:

| فایل | دلیل |
|------|------|
| `lib/core/config/api_config.dart` | ممکن است Application Password و WC keys داشته باشد |
| `android/key.properties` | رمز keystore |
| `*.jks` / `*.keystore` | کلید امضا |
| `google-services.json` | اگر FCM اضافه کردید |

به‌جای `api_config.dart` از نمونه استفاده کنید:

```bash
cp lib/core/config/api_config.example.dart lib/core/config/api_config.dart
# مقادیر را فقط روی سیستم خودتان پر کنید
```

فایل واقعی در `.gitignore` است.

---

## دستورات Git (اولین بار)

```bash
cd C:\wamp64\www\ezlens-manager-flutter

# اگر هنوز git init نشده
git init
git branch -M main

# فایل‌های راهنما را از بسته github-android کپی کنید:
#   .gitignore
#   lib/core/config/api_config.example.dart
#   BUILD_ANDROID.md
#   GITHUB.md

# پاک‌سازی secret از api_config قبل از add
# (مقادیر خالی یا example)

git add .
git status
# مطمئن شوید api_config.dart با پسورد واقعی stage نشده

git commit -m "Initial commit: EzLens Manager Flutter app"

# ریپوی خالی در GitHub بسازید (مثلاً ezlens-manager)
git remote add origin https://github.com/YOUR_USER/ezlens-manager.git
git push -u origin main
```

اگر ریپو **خصوصی (Private)** باشد امن‌تر است تا وقتی secretها کامل جدا شوند.

---

## آپدیت‌های بعدی

```bash
git add .
git commit -m "Describe change"
git push
```

---

## تگ نسخه + Release

```bash
git tag v1.1.0
git push origin v1.1.0
```

در GitHub → Releases → Draft a release → ضمیمه کردن `app-release.apk` (بدون keystore).

---

## ترتیب پیشنهادی امروز

1. پاک کردن secret از `api_config.dart`
2. کپی `.gitignore` و example config
3. `git init` + commit + push (Private)
4. `flutter build apk --release` روی ویندوز
5. تست APK روی گوشی
6. (اختیاری) ساخت AAB برای Play Console
