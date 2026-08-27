import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone", // برای استقرار روی Vercel
  images: { unoptimized: true },
};

export default nextConfig;