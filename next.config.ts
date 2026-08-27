import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // ❌ خط زیر رو کامنت کردم تا API routes درست کار کنن
  // output: "export",
  
  images: {
    unoptimized: true,
  },
  
  // ❌ این رو هم کامنت کردم
  // trailingSlash: true,
};

export default nextConfig;