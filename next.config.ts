/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', // برای اجرا روی Vercel و سرورهای Node
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**' }, // اجازه لود تصاویر از هر دامنه‌ای
    ],
  },
};

module.exports = nextConfig;