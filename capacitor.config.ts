import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "ir.ezlens.manager",
  appName: "EzLens Manager",
  webDir: "out",   // <-- این رو به "out" تغییر بده (چون Next.js export توی out می‌ریزه)
  server: {
    // این خط رو کامنت کن یا حذف کن تا از فایل‌های محلی استفاده کنه
    // url: "https://YOUR_VERCEL_URL.vercel.app",
    // cleartext: false,
  },
  android: {
    allowMixedContent: true, // برای تست روی گوشی
  },
};

export default config;