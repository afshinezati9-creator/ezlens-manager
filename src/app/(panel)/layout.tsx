"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Package,
  FileText,
  ShoppingCart,
  Users,
  Image,
  MessageSquare,
  NotebookPen,
  Settings,
  LogOut,
  MoreHorizontal,
  X,
  Menu,
  ChevronLeft,
} from "lucide-react";

export default function PanelLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [isMoreOpen, setIsMoreOpen] = useState(false);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // بستن منوها در تغییر مسیر
  useEffect(() => {
    setIsMoreOpen(false);
    setIsMobileMenuOpen(false);
    setIsSidebarOpen(false);
  }, [pathname]);

  // آیتم‌های اصلی (نمایش در نویگیشن پایین)
  const mainItems = [
    { title: "داشبورد", href: "/dashboard", icon: LayoutDashboard },
    { title: "محصولات", href: "/products", icon: Package },
    { title: "مقالات", href: "/articles", icon: FileText },
    { title: "سفارش‌ها", href: "/orders", icon: ShoppingCart },
  ];

  // آیتم‌های فرعی (نمایش در منوی «بیشتر» و سایدبار)
  const moreItems = [
    { title: "کاربران", href: "/users", icon: Users },
    { title: "رسانه‌ها", href: "/media", icon: Image },
    { title: "نظرات", href: "/comments", icon: MessageSquare },
    { title: "یادداشت‌ها", href: "/notes", icon: NotebookPen },
    { title: "تنظیمات", href: "/settings", icon: Settings },
  ];

  const allItems = [...mainItems, ...moreItems];

  // تشخیص آیتم فعال
  const isActive = (href: string) => {
    if (href === "/dashboard") return pathname === "/dashboard";
    return pathname.startsWith(href);
  };

  // خروج
  const handleLogout = () => {
    document.cookie = "token=; path=/; max-age=0";
    router.push("/login");
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans" dir="rtl">

      {/* =========================== هدر =========================== */}
      <header className="sticky top-0 z-50 bg-white/90 backdrop-blur-md border-b border-slate-200/80 shadow-sm">
        <div className="flex items-center justify-between px-4 py-3 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            {/* دکمه منوی همبرگری */}
            <button
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="p-2 rounded-xl hover:bg-slate-100 transition-colors active:scale-95"
              aria-label="منو"
            >
              {isMobileMenuOpen ? (
                <X className="w-6 h-6 text-slate-700" />
              ) : (
                <Menu className="w-6 h-6 text-slate-700" />
              )}
            </button>

            {/* ========== لوگو با تصویر واقعی (از سایت) ========== */}
            <Link href="/dashboard" className="flex items-center gap-2 group" prefetch={true}>
              <img
                src="https://ezlens.ir/wp-content/uploads/2026/07/cropped-logo-500x500-1.webp"
                alt="EzLens Logo"
                className="w-9 h-9 rounded-full object-cover shadow-md ring-2 ring-blue-100/50 group-hover:ring-blue-300 transition-all"
                width={36}
                height={36}
              />
              <span className="font-bold text-slate-800 text-lg tracking-tight">
                EzLens
                <span className="text-xs font-normal text-slate-400 mr-1">Manager</span>
              </span>
            </Link>
          </div>

          <button
            onClick={handleLogout}
            className="flex items-center gap-2 px-3 py-2 rounded-xl text-sm text-red-600 hover:bg-red-50 active:scale-95 transition-all"
          >
            <LogOut className="w-5 h-5" />
            <span className="hidden sm:inline font-medium">خروج</span>
          </button>
        </div>
      </header>

      {/* =========================== بدنه =========================== */}
      <div className="flex relative">

        {/* ================ سایدبار (تبلت و دسکتاپ) ================ */}
        <aside
          className={`
            hidden md:block
            fixed md:sticky top-0
            h-screen
            bg-white border-l border-slate-200/80
            transition-all duration-300 ease-in-out
            ${isSidebarOpen ? 'w-64' : 'w-20'}
            shrink-0
            overflow-y-auto
            z-40
            shadow-lg
          `}
          style={{ top: '73px' }}
        >
          <nav className="p-3 space-y-1">
            {allItems.map((item) => {
              const active = isActive(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  prefetch={true}
                  scroll={false}
                  className={`
                    flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200
                    ${active
                      ? "bg-blue-50 text-blue-700 shadow-sm ring-1 ring-blue-200/50"
                      : "text-slate-600 hover:bg-slate-100"
                    }
                    ${!isSidebarOpen && 'justify-center'}
                  `}
                  title={!isSidebarOpen ? item.title : ''}
                >
                  <item.icon className={`w-5 h-5 ${active ? 'text-blue-600' : 'text-slate-500'}`} />
                  {isSidebarOpen && <span className="truncate">{item.title}</span>}
                </Link>
              );
            })}
          </nav>

          {/* دکمه جمع/باز کردن سایدبار */}
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="absolute -right-3 top-1/2 -translate-y-1/2 bg-white border border-slate-200 rounded-full p-1 shadow-md hover:shadow-lg transition-all"
          >
            <ChevronLeft className={`w-4 h-4 text-slate-500 transition-transform duration-300 ${isSidebarOpen ? 'rotate-0' : 'rotate-180'}`} />
          </button>
        </aside>

        {/* ================ محتوای اصلی ================ */}
        <main className="flex-1 p-4 md:p-6 pb-28 md:pb-6 max-w-7xl mx-auto w-full min-h-[calc(100vh-73px)]">
          <div key={pathname} className="animate-fade-in">
            {children}
          </div>
        </main>
      </div>

      {/* =================== منوی کشویی موبایل =================== */}
      {isMobileMenuOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <div
            className="absolute inset-0 bg-black/30 backdrop-blur-sm"
            onClick={() => setIsMobileMenuOpen(false)}
          />
          <div className="absolute bottom-0 left-0 right-0 bg-white rounded-t-3xl shadow-2xl p-4 pb-8 max-h-[70vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <span className="text-lg font-bold text-slate-800">منو</span>
              <button onClick={() => setIsMobileMenuOpen(false)} className="p-2 rounded-full hover:bg-slate-100">
                <X className="w-6 h-6 text-slate-500" />
              </button>
            </div>
            <div className="grid grid-cols-3 gap-3">
              {allItems.map((item) => {
                const active = isActive(item.href);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    prefetch={true}
                    scroll={false}
                    onClick={() => setIsMobileMenuOpen(false)}
                    className={`
                      flex flex-col items-center justify-center gap-1 p-4 rounded-2xl text-sm font-medium transition-all
                      ${active
                        ? "bg-blue-50 text-blue-600 ring-1 ring-blue-200/50"
                        : "text-slate-600 hover:bg-slate-50"
                      }
                    `}
                  >
                    <item.icon className={`w-6 h-6 ${active ? 'text-blue-600' : 'text-slate-500'}`} />
                    <span>{item.title}</span>
                  </Link>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* =================== منوی پایین (موبایل) =================== */}
      <nav className="fixed bottom-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-md border-t border-slate-200/80 md:hidden shadow-lg">
        <div className="grid grid-cols-5 h-16">
          {mainItems.map((item) => {
            const active = isActive(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                prefetch={true}
                scroll={false}
                className={`
                  relative flex flex-col items-center justify-center gap-0.5 text-xs font-medium transition-all
                  ${active ? 'text-blue-600' : 'text-slate-500'}
                `}
              >
                <item.icon
                  className={`w-5 h-5 transition-transform ${active ? 'scale-110' : ''}`}
                  strokeWidth={active ? 2.5 : 2}
                />
                <span>{item.title}</span>
                {active && (
                  <span className="absolute -top-0.5 w-8 h-0.5 bg-blue-600 rounded-full shadow-sm shadow-blue-200" />
                )}
              </Link>
            );
          })}

          {/* دکمه بیشتر */}
          <button
            onClick={() => setIsMoreOpen(!isMoreOpen)}
            className={`
              relative flex flex-col items-center justify-center gap-0.5 text-xs font-medium transition-all
              ${isMoreOpen ? 'text-blue-600' : 'text-slate-500'}
            `}
          >
            <MoreHorizontal
              className={`w-5 h-5 transition-transform ${isMoreOpen ? 'scale-110' : ''}`}
              strokeWidth={isMoreOpen ? 2.5 : 2}
            />
            <span>بیشتر</span>
            {isMoreOpen && (
              <span className="absolute -top-0.5 w-8 h-0.5 bg-blue-600 rounded-full shadow-sm shadow-blue-200" />
            )}
          </button>
        </div>
      </nav>

      {/* =================== منوی «بیشتر» کشویی (موبایل) =================== */}
      {isMoreOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <div
            className="absolute inset-0 bg-black/30 backdrop-blur-sm"
            onClick={() => setIsMoreOpen(false)}
          />
          <div className="absolute bottom-16 left-0 right-0 bg-white rounded-t-3xl shadow-2xl p-4 pb-6">
            <div className="flex justify-between items-center mb-4">
              <span className="text-sm font-bold text-slate-700">بیشتر</span>
              <button onClick={() => setIsMoreOpen(false)} className="p-1 rounded-full hover:bg-slate-100">
                <X className="w-5 h-5 text-slate-500" />
              </button>
            </div>
            <div className="grid grid-cols-4 gap-3">
              {moreItems.map((item) => {
                const active = isActive(item.href);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    prefetch={true}
                    scroll={false}
                    onClick={() => setIsMoreOpen(false)}
                    className={`
                      flex flex-col items-center justify-center gap-1 p-3 rounded-xl text-[11px] font-medium transition-all
                      ${active
                        ? "bg-blue-50 text-blue-600 ring-1 ring-blue-200/50"
                        : "text-slate-600 hover:bg-slate-50"
                      }
                    `}
                  >
                    <item.icon className={`w-5 h-5 ${active ? 'text-blue-600' : 'text-slate-500'}`} />
                    <span>{item.title}</span>
                  </Link>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* =================== استایل انیمیشن =================== */}
      <style jsx>{`
        @keyframes fade-in {
          from { opacity: 0; transform: translateY(6px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .animate-fade-in {
          animation: fade-in 0.2s ease-out forwards;
        }
      `}</style>
    </div>
  );
}