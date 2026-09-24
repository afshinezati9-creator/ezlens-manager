# گزارش فازهای توسعه — EzLens Manager (Flutter)

**پروژه:** EzLens Manager  
**مسیر پروژه:** `C:\wamp64\www\ezlens-manager-flutter`  
**تاریخ شروع:** ۲۷ اوت ۲۰۲۶  
**توسعه‌دهنده اصلی:** افشین عزتی + هوش مصنوعی  

> این فایل تاریخچه واقعی تصمیم‌ها، خطاها و راه‌حل‌ها را ثبت می‌کند تا هر توسعه‌دهنده بعدی بداند دقیقاً چه اتفاقی افتاده است.

---

## فاز ۰ — آماده‌سازی محیط توسعه  
**تاریخ اجرا:** ۲۷–۲۸ اوت ۲۰۲۶  
**وضعیت:** تکمیل‌شده با تصمیم استراتژیک

### هدف فاز
آماده‌سازی محیط توسعه، رفع مشکلات پایه و ایجاد پروژه Flutter تمیز برای شروع مهاجرت از نسخه Next.js.

### کارهای انجام‌شده

1. **بررسی ابزارهای پایه**
   - Git نسخه `2.55.0.windows.4` → سالم
   - OpenJDK `17.0.20` (Temurin) → سالم و مناسب برای Flutter
   - Flutter `3.44.9` (channel stable) → سالم
   - مسیر Flutter: `C:\flutter`
   - مسیر Android SDK: `C:\Android\Sdk`

2. **تنظیم متغیرهای محیطی**
   - `ANDROID_HOME` روی `C:\Android\Sdk` تنظیم شد (`setx` موفق).
   - `ANDROID_SDK_ROOT` نیز با `setx` تنظیم شد.
   - توجه: `setx` فقط روی پنجره‌های CMD جدید اثر می‌گذارد. در همان نشست قبلی هنوز `%ANDROID_SDK_ROOT%` نمایش داده نمی‌شد (رفتار طبیعی ویندوز).

3. **ایجاد پروژه Flutter**
   - دستور اجرا شده:
     ```cmd
     flutter create --org ir.ezlens --project-name ezlens_manager ezlens-manager-flutter
     ```
   - مسیر نهایی پروژه: `C:\wamp64\www\ezlens-manager-flutter`
   - ۱۳۱ فایل ایجاد شد.
   - `flutter pub get` بدون خطا اجرا شد.

### مشکلات و خطاهای واقعی که با آن‌ها روبه‌رو شدیم

#### ۱. Android Toolchain Timeout (مشکل اصلی)
- خروجی `flutter doctor -v` همیشه با خطای زیر متوقف می‌شد:
  ```
  [☠] Android toolchain - develop for Android devices (the doctor check crashed)
  X Exception: Android toolchain - develop for Android devices exceeded maximum allowed duration of 0:04:30.000000
  ```
- علت ریشه‌ای: تحریم ایران + عدم دسترسی پایدار به سرورهای گوگل (حتی با فیلترشکن و آینه‌های چینی).

#### ۲. شکست کامل `flutter doctor --android-licenses`
- پیام‌های مکرر:
  ```
  Warning: Failed to download any source lists!
  Warning: IO exception while downloading manifest
  Warning: Still waiting for package manifests to be fetched remotely.
  ```
- `sdkmanager` قادر به دانلود لیست پکیج‌ها از گوگل نبود.
- این مشکل طی چند هفته قبل از شروع فاز ۰ نیز وجود داشته و حل نشده بود.

#### ۳. خطای اجرای اولیه روی Chrome
- دستور `flutter run -d chrome` با خطاهای زیر مواجه شد:
  - عدم توانایی در دانلود فونت Roboto از `fonts.gstatic.com`
  - عدم توانایی در بارگذاری CanvasKit از `gstatic.com`
- علت: همان محدودیت‌های تحریمی گوگل.

### تصمیم استراتژیک گرفته‌شده در فاز ۰

به دلیل غیرقابل‌حل بودن پایدار مشکل Android SDK محلی در شرایط تحریم:

- **تصمیم قطعی:** دیگر زمان و انرژی روی درست کردن بیلد محلی اندروید هدر داده نمی‌شود.
- توسعه و تست UI و منطق اپ روی **Chrome** (با `--web-renderer html`) و در صورت امکان Windows انجام می‌شود.
- بیلد نهایی APK منحصراً از طریق **GitHub Actions** انجام خواهد شد.
- متغیرهای محیطی Android همچنان تنظیم شدند تا در آینده (یا روی ماشین دیگر) قابل استفاده باشند، اما به عنوان پیش‌نیاز فازهای بعدی در نظر گرفته نمی‌شوند.

### خروجی نهایی فاز ۰

| مورد | وضعیت |
|------|--------|
| پروژه Flutter تمیز | ایجاد شد |
| مسیر پروژه | `C:\wamp64\www\ezlens-manager-flutter` |
| وابستگی‌های پایه | نصب شد |
| امکان توسعه روی وب (Chrome) | فراهم شد (با renderer html) |
| بیلد محلی اندروید | فعلاً غیرفعال (عمدی) |
| آمادگی برای فاز ۱ | کامل |

### نکات مهم برای توسعه‌دهنده بعدی

- اگر روی ماشین دیگری کار می‌کنید که به گوگل دسترسی دارد، می‌توانید Android Toolchain را دوباره فعال و لایسنس‌ها را بپذیرید.
- در شرایط ایران، همیشه فرض کنید که `flutter doctor` در بخش Android ممکن است Timeout بدهد. این به معنای خراب بودن پروژه نیست.
- برای اجرای وب از دستور زیر استفاده کنید:
  ```cmd
  flutter run -d chrome --web-renderer html
  ```
- ساختار پروژه از فاز ۱ به بعد Feature-first خواهد بود و Design System قبل از ساخت صفحات پیاده‌سازی می‌شود.

### وضعیت فاز
**تکمیل‌شده** — آماده ورود به فاز ۱ (معماری پایه و ساختار پوشه‌ها)

---

*گزارش نوشته‌شده در تاریخ ۲۸ اوت ۲۰۲۶*
