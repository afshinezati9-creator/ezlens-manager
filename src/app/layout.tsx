import type { Metadata } from "next";
import { Vazirmatn } from "next/font/google";
import "./globals.css";

const vazirmatn = Vazirmatn({ 
  subsets: ["arabic", "latin"],
  display: "swap",
  variable: "--font-app",
});

export const metadata: Metadata = {
  title: "EzLens Manager",
  description: "پنل مدیریت اکوسیستم بینایی EzLens",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fa" dir="rtl">
      <body className={`${vazirmatn.variable} font-[family-name:var(--font-app)] min-h-screen bg-white text-slate-900 antialiased`}>
        {children}
      </body>
    </html>
  );
}