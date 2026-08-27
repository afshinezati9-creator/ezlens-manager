import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",  // <-- این خط رو اضافه کن
  images: {
    unoptimized: true,
  },
  trailingSlash: true, // برای سازگاری با Capacitor
};

export default nextConfig;