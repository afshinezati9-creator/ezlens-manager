const config = {
  appId: 'ir.ezlens.manager',
  appName: 'EzLens Manager',
  webDir: 'www', // پوشه خالی برای بیلد Capacitor
  server: {
    url: 'https://YOUR_VERCEL_URL.vercel.app', // ⚠️ آدرس سایت واقعی بعد از دیپلوی
    cleartext: false, // اگر https باشد، false بگذار
  },
};

export default config;