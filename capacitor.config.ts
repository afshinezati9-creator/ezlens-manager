import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "ir.ezlens.manager",
  appName: "EzLens Manager",
  webDir: "www",
  server: {
    // بعد از دیپلوی Vercel، آدرس واقعی را بگذار
    url: "https://YOUR_VERCEL_URL.vercel.app",
    cleartext: false,
  },
  android: {
    allowMixedContent: false,
  },
};

export default config;