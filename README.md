# EzLens Manager

اپلیکیشن مدیریت فروشگاه **EzLens** (Flutter) — اتصال مستقیم به وردپرس / ووکامرس سایت [ezlens.ir](https://ezlens.ir).

نسخه هدف: **1.1.0** · پلتفرم: Android / iOS / Web (Chrome) · UI: RTL · فارسی

---

## خلاصه

پنل موبایل/وب برای مدیر فروشگاه لنز و عینک. عملیات اصلی بدون ورود به wp-admin انجام می‌شود و به REST وردپرس، ووکامرس و ماژول‌های پلاگین **EzLens Secure Login** وصل است.

| لایه | فناوری |
|------|--------|
| UI | Flutter 3 · Material · RTL |
| State | Riverpod |
| Routing | go_router |
| HTTP | Dio + Application Password |
| امنیت محلی | flutter_secure_storage · local_auth (اثرانگشت) |
| اعلان | flutter_local_notifications (poll سفارش / نظر / تیکت) |

---

## ماژول‌های فعال

### فروشگاه
- **محصولات** — لیست، افزودن/ویرایش، موجودی، ویژگی‌های محصول (Product Options)، ویرایشگر کد
- **سفارش‌ها** — جزئیات، نسخه بیمار، ویژگی‌های ثبت‌شده، برچسب کیف پول، اطلاع‌رسانی وضعیت
- **فرآیند خرید** — اسکریپت‌های صفحه محصول/سبد (هم‌تراز ماژول Purchase Process پلاگین)

### محتوا
- **مقالات** — لیست، ویرایش، ویرایشگر یکپارچه HTML/CSS/JS، اعمال محتوا بدون تداخل Elementor
- **نظرات** — مدیریت نظرات مقالات (REST)
- **رسانه** — مرور و جزئیات فایل‌های رسانه

### کاربران و پشتیبانی
- **مشتریان** — لیست صفحه‌بندی‌شده، پرونده مشتری، کیف پول، نسخه‌ها، سبد
- **پشتیبانی** — تیکت‌ها، پاسخ، پیوست، تغییر وضعیت
- **درخواست‌ها** — اتصال به EI Form Builder (`/ei/v1/...`)

### ارتباطات
- **پیام تکی** — SMS / ایمیل به یک مشتری
- **پیام گروهی (Mass)**
- **کمپین** — دفترچه مخاطب، ارسال گروهی
- **صندوق ایمیل (Inbox)** — خواندن/پاسخ info@

### مالی
- **شارژ کیف پول** — بررسی و تأیید واریزها
- **تخفیف و هدیه**
- **همیاری بینایی (Charity)**

### سیستم
- **داشبورد** — کارت‌های آماری، آخرین ورودها، بازدید محصولات و مقالات جدید، میانبر بخش‌ها
- **آمار** — بازه روزانه / هفتگی / ماهانه / کل
- **تنظیمات** — ترجیحات UI، امنیت (اثرانگشت)، اعلان‌ها
- **امنیت نشست** — ماندگاری لاگین تا خروج صریح + قفل بیومتریک اختیاری

---

## داشبورد (وضعیت فعلی)

1. **وضعیت کلی** — بازدید محصولات، فروش، تعداد محصولات، تعداد مقالات (کارت گرادیانت انیمیشنی)
2. **آخرین ورودها** — نام کاربر + تاریخ/ساعت
3. **بازدید محصولات جدید** — جدیدترین/پربازدیدترین محصولات با شمارنده بازدید
4. **بازدید مقالات جدید** — آخرین پست‌ها با `post_views_count` / meta
5. **دسترسی سریع** — شبکه آیکون‌ها به تمام بخش‌ها

منبع بازدید محصول: متای `post_views_count` + endpoint آمار Manager.  
منبع بازدید مقاله: REST `wp/v2/posts` + meta در صورت ثبت در REST.

---

## احراز هویت

- ورود با **نام کاربری وردپرس + Application Password**
- اعتبارسنجی از `GET /wp-json/wp/v2/users/me`
- ذخیره امن در `flutter_secure_storage`
- خروج فقط با اقدام کاربر (پاک شدن session)
- اختیاری: باز کردن مجدد با اثرانگشت / Face ID (`/lock`)

> توصیه: رمز Application Password را در سورس hard-code نکنید؛ پس از لاگین از Secure Storage خوانده شود.

---

## APIهای اصلی

پایه سایت: `https://ezlens.ir`

| مسیر | کاربرد |
|------|--------|
| `/wp-json/wp/v2/*` | پست، نظر، رسانه، کاربر |
| `/wp-json/wc/v3/*` | محصول، سفارش، مشتری |
| `/wp-json/ezlens/v1/manager/*` | مشتریان، آمار، پشتیبانی، اینباکس، … |
| `/wp-json/ei/v1/requests` | درخواست‌های فرم‌ساز EI |

پس از افزودن routeهای Manager در پلاگین: **پیوندهای یکتا → ذخیره**.

---

## ساختار پوشه `lib/`

```
lib/
  main.dart / app.dart
  core/
    config/          # ApiConfig
    constants/
    network/         # ApiClient, providers
    storage/         # Secure + local
    security/        # BiometricService
    notifications/   # Local notifications + poller
    router/
    theme/
    widgets/
  features/
    auth/            # login, splash, lock
    dashboard/
    products/ product_features/
    orders/ articles/ comments/ media/
    users/ support/ requests/
    messaging/ mass/ campaign/ inbox/
    wallet/ discounts/ charity/
    purchase/ stats/ settings/
    shell/           # bottom nav + more
```

---

## اجرا

```bash
flutter pub get
flutter run -d chrome          # وب
flutter run -d windows         # دسکتاپ
flutter run                    # دستگاه/امولاتور
```

وابستگی‌های امنیتی/اعلان (در صورت استفاده از بسته security):

```yaml
local_auth: ^2.3.0
flutter_local_notifications: ^18.0.1
```

Android: `USE_BIOMETRIC`, `POST_NOTIFICATIONS` و `MainActivity extends FlutterFragmentActivity`.  
iOS: `NSFaceIDUsageDescription`.

---

## پلاگین وردپرس همراه

**EzLens Secure Login** (نسخه حدود 5.4.x) ماژول‌های زیر را روی سایت فراهم می‌کند:

- OTP / ورود مشتری
- Customer Dashboard
- Product Options
- Purchase Process
- Support / Campaign / Inbox / Wallet
- Manager REST (`modules/manager-api/`)

سایت فروشگاهی: Woodmart Child · WooCommerce · Elementor · Rank Math · LiteSpeed · ZarinPal · SMS.ir

---

## نقشه راه کوتاه (پس از انتشار داخلی)

- [ ] FCM برای پوش پس‌زمینه واقعی
- [ ] حذف کامل credential از `ApiConfig` و خواندن فقط از Secure Storage
- [ ] تست یکپارچه روی هاست production + purge کش پس از apply-content مقالات
- [ ] بهبود endpoint آمار برای views مقالات در Manager API

---

## مجوز و مالکیت

پروژه اختصاصی فروشگاه EzLens · توسعه برای استفاده داخلی مدیریت.  
مستندات مرتبط در ریپوی artifacts: `ARCHITECTURE.md`, `EzLens Project OS.docx`, بسته‌های `ezlens-manager-*.zip`.

---

## GitHub و بیلد اندروید

جزئیات کامل در:

- [`GITHUB.md`](GITHUB.md) — ارسال ریپو، حذف secret، تگ نسخه
- [`BUILD_ANDROID.md`](BUILD_ANDROID.md) — APK / AAB، keystore، مجوزها

خلاصه سریع:

```bash
# ۱) secret را از api_config بردارید
# ۲) git push (ترجیحاً Private)
# ۳) بیلد:
flutter build apk --release
# خروجی: build/app/outputs/flutter-apk/app-release.apk
```
