"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { 
  LayoutDashboard, ShoppingCart, Users, Image, MessageSquare, 
  NotebookPen, Settings, LogOut, Menu, X, Package
} from "lucide-react";

export default function PanelLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  useEffect(() => {
    setIsMobileMenuOpen(false);
    setIsSidebarOpen(false);
  }, [pathname]);

  function handleLogout() {
    // پاک کردن کوکی توکن
    document.cookie = "token=; path=/; max-age=0";
    // هدایت به صفحه لاگین
    router.push("/login");
  }

  const menuItems = [
    { title: "داشبورد", href: "/dashboard", icon: LayoutDashboard },
    { title: "سفارش‌ها", href: "/orders", icon: ShoppingCart },
    { title: "کاربران", href: "/users", icon: Users },
    { title: "رسانه‌ها", href: "/media", icon: Image },
    { title: "نظرات", href: "/comments", icon: MessageSquare },
    { title: "درخواست‌ها", href: "/requests", icon: Package },
    { title: "یادداشت‌ها", href: "/notes", icon: NotebookPen },
    { title: "تنظیمات", href: "/settings", icon: Settings },
  ];

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      
      {/* ====== هدر مدرن ====== */}
      <header className="sticky top-0 z-40 bg-white/80 backdrop-blur-md border-b border-slate-200">
        <div className="flex items-center justify-between px-4 md:px-6 py-3 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            {/* دکمه منوی موبایل */}
            <button
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="md:hidden p-2 rounded-lg hover:bg-slate-100"
            >
              {isMobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>

            {/* لوگو */}
            <Link href="/dashboard" className="flex items-center gap-2">
              <img
                src="https://ezlens.ir/wp-content/uploads/2026/07/logo-500x500-1.webp"
                alt="Logo"
                className="w-8 h-8 rounded-full object-cover"
              />
              <span className="font-bold text-slate-800">EzLens</span>
            </Link>
          </div>

          <div className="hidden md:flex flex-1 justify-center">
            <span className="text-sm font-medium text-slate-500">مدیریت فروشگاه</span>
          </div>

          <div className="flex items-center gap-2">
            {/* دکمه خروج */}
            <button
              onClick={handleLogout}
              className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm text-red-600 hover:bg-red-50 transition"
            >
              <LogOut className="w-4 h-4" />
              <span className="hidden sm:inline">خروج</span>
            </button>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* ====== سایدبار دسکتاپ ====== */}
        <aside className="hidden md:block w-60 bg-white border-r border-slate-200 min-h-screen">
          <nav className="p-4 space-y-1">
            {menuItems.map((item) => {
              const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition ${
                    isActive
                      ? "bg-blue-50 text-blue-600"
                      : "text-slate-600 hover:bg-slate-50"
                  }`}
                >
                  <item.icon className="w-5 h-5" />
                  {item.title}
                </Link>
              );
            })}
          </nav>
        </aside>

        {/* ====== محتوای اصلی ====== */}
        <main className="flex-1 p-4 md:p-6 pb-20 md:pb-6">
          {children}
        </main>
      </div>

      {/* ====== منوی پایین موبایل ====== */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white border-t border-slate-200 md:hidden">
        <div className="grid grid-cols-4 h-16">
          {menuItems.slice(0, 4).map((item) => {
            const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex flex-col items-center justify-center gap-1 text-[11px] font-medium transition ${
                  isActive ? "text-blue-600" : "text-slate-500"
                }`}
              >
                <item.icon className="w-5 h-5" />
                {item.title}
              </Link>
            );
          })}
        </div>

        {/* دکمه «بیشتر» برای بقیه منوها */}
        <button
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          className="absolute top-0 left-0 h-16 w-12 flex items-center justify-center border-r border-slate-200 md:hidden"
        >
          {isMobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </nav>

      {/* ====== منوی کشویی موبایل (برای بقیه آیتم‌ها) ====== */}
      {isMobileMenuOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <div className="absolute inset-0 bg-black/30" onClick={() => setIsMobileMenuOpen(false)} />
          <nav className="absolute bottom-16 left-0 right-0 bg-white rounded-t-2xl shadow-xl p-4">
            <div className="grid grid-cols-4 gap-4">
              {menuItems.slice(4).map((item) => {
                const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setIsMobileMenuOpen(false)}
                    className={`flex flex-col items-center justify-center gap-1 p-3 rounded-xl text-[11px] font-medium transition ${
                      isActive ? "bg-blue-50 text-blue-600" : "text-slate-600"
                    }`}
                  >
                    <item.icon className="w-5 h-5" />
                    {item.title}
                  </Link>
                );
              })}
            </div>
          </nav>
        </div>
      )}
    </div>
  );
}