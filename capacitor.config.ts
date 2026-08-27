import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "ir.ezlens.manager",
  appName: "EzLens Manager",
  webDir: "www",   // ✅ برگشت به حالت اول
  server: {
    // این خط رو کامنت نگه دار تا از فایل‌های محلی استفاده کنه
    // url: "https://YOUR_VERCEL_URL.vercel.app",
    // cleartext: false,
  },
  android: {
    allowMixedContent: true,
  },
};

export default config;