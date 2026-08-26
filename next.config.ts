import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export", // مهم: برای ساخت APK باید استاتیک باشد
  images: {
    unoptimized: true, // چون خروجی استاتیک است، تصاویر بهینه‌سازی نشوند
  },
};

export default nextConfig;