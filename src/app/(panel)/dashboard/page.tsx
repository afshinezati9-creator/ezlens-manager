"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  Package, ShoppingCart, Users, Image, MessageSquare,
  FileText, NotebookPen, Plus, LayoutDashboard, X, Sparkles,
  Eye, BarChart3, ArrowUpRight, Clock, Flame
} from "lucide-react";

interface Stats {
  products: number;
  orders: number;
  users: number;
  media: number;
  comments: number;
  notes: number;
  requests: number;
  totalRevenue: number;
  dailyRevenue: number;
  monthlyRevenue: number;
  visitsToday: number;
  visitsMonth: number;
  visitsAll: number;
  latestProducts: { id: number; title: string; href: string; image: string }[];
  latestOrders: { id: number; title: string; total: number; href: string }[];
  latestNotes: { id: number; title: string; href: string }[];
  latestPosts: { id: number; title: string; href: string }[];
  mostViewedProducts: { id: number; title: string; total_sales: number; href: string; image: string }[];
  mostViewedPosts: { id: number; title: string; comments: number; href: string }[];
}

const EMPTY_STATS: Stats = {
  products: 0,
  orders: 0,
  users: 0,
  media: 0,
  comments: 0,
  notes: 0,
  requests: 0,
  totalRevenue: 0,
  dailyRevenue: 0,
  monthlyRevenue: 0,
  visitsToday: 0,
  visitsMonth: 0,
  visitsAll: 0,
  latestProducts: [],
  latestOrders: [],
  latestNotes: [],
  latestPosts: [],
  mostViewedProducts: [],
  mostViewedPosts: [],
};

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats>(EMPTY_STATS);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [fabOpen, setFabOpen] = useState(false);

  useEffect(() => {
    async function loadStats() {
      try {
        const res = await fetch("/api/dashboard/stats", { cache: "no-store" });
        const data = await res.json();
        if (res.ok && data) {
          setStats({ ...EMPTY_STATS, ...data });
        } else {
          setError(data?.error || "خطا در دریافت آمار");
        }
      } catch {
        setError("خطا در دریافت آمار");
      } finally {
        setLoading(false);
      }
    }
    loadStats();
  }, []);

  const statCards = [
    { title: "محصولات", value: stats.products, icon: Package, color: "text-blue-600 bg-blue-50", href: "/products" },
    { title: "سفارش‌ها", value: stats.orders, icon: ShoppingCart, color: "text-emerald-600 bg-emerald-50", href: "/orders" },
    { title: "کاربران", value: stats.users, icon: Users, color: "text-purple-600 bg-purple-50", href: "/users" },
    { title: "رسانه‌ها", value: stats.media, icon: Image, color: "text-amber-600 bg-amber-50", href: "/media" },
    { title: "نظرات", value: stats.comments, icon: MessageSquare, color: "text-rose-600 bg-rose-50", href: "/comments" },
    { title: "درخواست‌ها", value: stats.requests, icon: FileText, color: "text-indigo-600 bg-indigo-50", href: "/requests" },
    { title: "یادداشت‌ها", value: stats.notes, icon: NotebookPen, color: "text-teal-600 bg-teal-50", href: "/notes" },
  ];

  const quickActions = [
    { label: "محصول جدید", icon: Package, href: "/products/new", color: "text-blue-600" },
    { label: "مقاله جدید", icon: FileText, href: "/articles/new", color: "text-purple-600" },
    { label: "یادداشت جدید", icon: NotebookPen, href: "/notes", color: "text-teal-600" },
  ];

  return (
    <main className="min-h-screen bg-slate-50 py-6">
      <div className="max-w-7xl mx-auto px-4 space-y-6 pb-32">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
              <LayoutDashboard className="w-6 h-6 text-blue-600" />
              داشبورد
            </h1>
            <p className="text-sm text-slate-500 mt-1">نمای کلی مدیریت فروشگاه</p>
          </div>
        </div>

        {error && !loading && (
          <div className="bg-amber-50 text-amber-700 px-4 py-3 rounded-xl text-sm flex items-center gap-2">
            <span>⚠️</span>
            <span>{error}</span>
          </div>
        )}

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {statCards.map((card) => (
            <Link key={card.title} href={card.href} className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm hover:shadow-md transition group">
              <div className="flex items-center justify-between">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${card.color}`}>
                  <card.icon className="w-6 h-6" />
                </div>
                <ArrowUpRight className="w-4 h-4 text-slate-300 group-hover:text-slate-500" />
              </div>
              <div className="mt-4">
                <div className="text-2xl font-bold text-slate-900">
                  {loading ? <span className="animate-pulse text-slate-300">۰</span> : card.value}
                </div>
                <div className="text-sm text-slate-500">{card.title}</div>
              </div>
            </Link>
          ))}
        </div>

        <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
            <h2 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
              <BarChart3 className="w-5 h-5 text-blue-600" />
              آمار فروش
            </h2>
            <div className="space-y-3">
              <div className="flex items-center justify-between bg-slate-50 rounded-xl p-3">
                <span className="text-sm text-slate-500">امروز</span>
                <span className="font-bold text-slate-900">{loading ? "—" : (stats.dailyRevenue ? Number(stats.dailyRevenue).toLocaleString("fa-IR") : "۰") + " تومان"}</span>
              </div>
              <div className="flex items-center justify-between bg-slate-50 rounded-xl p-3">
                <span className="text-sm text-slate-500">این ماه</span>
                <span className="font-bold text-slate-900">{loading ? "—" : (stats.monthlyRevenue ? Number(stats.monthlyRevenue).toLocaleString("fa-IR") : "۰") + " تومان"}</span>
              </div>
              <div className="flex items-center justify-between bg-slate-50 rounded-xl p-3">
                <span className="text-sm text-slate-500">کل</span>
                <span className="font-bold text-slate-900">{loading ? "—" : (stats.totalRevenue ? Number(stats.totalRevenue).toLocaleString("fa-IR") : "۰") + " تومان"}</span>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
            <h2 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
              <Eye className="w-5 h-5 text-purple-600" />
              بازدید
            </h2>
            <div className="space-y-3">
              <div className="flex items-center justify-between bg-slate-50 rounded-xl p-3">
                <span className="text-sm text-slate-500">امروز</span>
                <span className="font-bold text-slate-900">{loading ? "—" : (stats.visitsToday || 0)}</span>
              </div>
              <div className="flex items-center justify-between bg-slate-50 rounded-xl p-3">
                <span className="text-sm text-slate-500">این ماه</span>
                <span className="font-bold text-slate-900">{loading ? "—" : (stats.visitsMonth || 0)}</span>
              </div>
              <div className="flex items-center justify-between bg-slate-50 rounded-xl p-3">
                <span className="text-sm text-slate-500">کل</span>
                <span className="font-bold text-slate-900">{loading ? "—" : (stats.visitsAll || 0)}</span>
              </div>
            </div>
          </div>
        </section>

        {/* جدیدترین‌ها و پربازدیدترین‌ها (ریسپانسیو و بدون سرریز) */}
        <section className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm overflow-hidden">
            <h2 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
              <Clock className="w-5 h-5 text-emerald-600" />
              جدیدترین‌ها
            </h2>
            <div className="space-y-3 min-w-0">
              {loading ? (
                <div className="space-y-3 animate-pulse">
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                </div>
              ) : (
                <div className="space-y-2">
                  {/* جدیدترین محصولات */}
                  {stats.latestProducts.slice(0, 3).map((p) => (
                    <Link key={p.id} href={p.href} className="group flex items-center gap-3 p-2 rounded-lg hover:bg-slate-50 transition">
                      <div className="w-10 h-10 rounded-lg bg-slate-100 shrink-0 overflow-hidden flex items-center justify-center">
                        {p.image ? (
                          <img src={p.image} alt={p.title} className="w-full h-full object-cover" />
                        ) : (
                          <Package className="w-5 h-5 text-slate-400" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-700 truncate group-hover:text-blue-600 transition">
                          {p.title}
                        </p>
                        <p className="text-xs text-slate-400">محصول</p>
                      </div>
                    </Link>
                  ))}

                  {/* جدیدترین مقالات */}
                  {stats.latestPosts.slice(0, 2).map((p) => (
                    <Link key={p.id} href={p.href} className="group flex items-center gap-3 p-2 rounded-lg hover:bg-slate-50 transition">
                      <div className="w-10 h-10 rounded-lg bg-slate-100 shrink-0 flex items-center justify-center">
                        <FileText className="w-5 h-5 text-slate-400" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-700 truncate group-hover:text-blue-600 transition">
                          {p.title}
                        </p>
                        <p className="text-xs text-slate-400">مقاله</p>
                      </div>
                    </Link>
                  ))}

                  {/* جدیدترین سفارش‌ها */}
                  {stats.latestOrders.slice(0, 2).map((o) => (
                    <Link key={o.id} href={o.href} className="group flex items-center gap-3 p-2 rounded-lg hover:bg-slate-50 transition">
                      <div className="w-10 h-10 rounded-lg bg-slate-100 shrink-0 flex items-center justify-center">
                        <ShoppingCart className="w-5 h-5 text-slate-400" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-700 truncate group-hover:text-blue-600 transition">
                          {o.title}
                        </p>
                        <p className="text-xs text-slate-400">سفارش</p>
                      </div>
                    </Link>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm overflow-hidden">
            <h2 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
              <Flame className="w-5 h-5 text-orange-600" />
              پربازدیدترین‌ها
            </h2>
            <div className="space-y-3 min-w-0">
              {loading ? (
                <div className="space-y-3 animate-pulse">
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                  <div className="h-12 bg-slate-100 rounded-xl"></div>
                </div>
              ) : (
                <div className="space-y-2">
                  {/* پربازدیدترین محصولات */}
                  {stats.mostViewedProducts.slice(0, 3).map((p, index) => (
                    <Link key={p.id} href={p.href} className="group flex items-center gap-3 p-2 rounded-lg hover:bg-slate-50 transition">
                      <span className="w-6 text-center text-lg font-bold text-slate-400 shrink-0">#{index + 1}</span>
                      <div className="w-10 h-10 rounded-lg bg-slate-100 shrink-0 overflow-hidden flex items-center justify-center">
                        {p.image ? (
                          <img src={p.image} alt={p.title} className="w-full h-full object-cover" />
                        ) : (
                          <Package className="w-5 h-5 text-slate-400" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-700 truncate group-hover:text-blue-600 transition">
                          {p.title}
                        </p>
                        <p className="text-xs text-slate-400">فروش: {p.total_sales}</p>
                      </div>
                    </Link>
                  ))}

                  {/* پربازدیدترین مقالات */}
                  {stats.mostViewedPosts.slice(0, 2).map((p, index) => (
                    <Link key={p.id} href={p.href} className="group flex items-center gap-3 p-2 rounded-lg hover:bg-slate-50 transition">
                      <span className="w-6 text-center text-lg font-bold text-slate-400 shrink-0">#{index + 4}</span>
                      <div className="w-10 h-10 rounded-lg bg-slate-100 shrink-0 flex items-center justify-center">
                        <FileText className="w-5 h-5 text-slate-400" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-700 truncate group-hover:text-blue-600 transition">
                          {p.title}
                        </p>
                        <p className="text-xs text-slate-400">نظرات: {p.comments}</p>
                      </div>
                    </Link>
                  ))}
                </div>
              )}
            </div>
          </div>
        </section>

        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
          <h2 className="text-lg font-bold text-slate-800 mb-4">دسترسی سریع</h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
            <Link href="/products" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-blue-50 transition min-w-0">
              <Package className="w-5 h-5 text-blue-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">محصولات</span>
            </Link>
            <Link href="/orders" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-emerald-50 transition min-w-0">
              <ShoppingCart className="w-5 h-5 text-emerald-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">سفارش‌ها</span>
            </Link>
            <Link href="/users" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-purple-50 transition min-w-0">
              <Users className="w-5 h-5 text-purple-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">کاربران</span>
            </Link>
            <Link href="/media" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-amber-50 transition min-w-0">
              <Image className="w-5 h-5 text-amber-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">رسانه‌ها</span>
            </Link>
            <Link href="/comments" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-rose-50 transition min-w-0">
              <MessageSquare className="w-5 h-5 text-rose-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">نظرات</span>
            </Link>
            <Link href="/requests" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-indigo-50 transition min-w-0">
              <FileText className="w-5 h-5 text-indigo-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">درخواست‌ها</span>
            </Link>
            <Link href="/notes" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-teal-50 transition min-w-0">
              <NotebookPen className="w-5 h-5 text-teal-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">یادداشت‌ها</span>
            </Link>
            <Link href="/settings" className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-gray-100 transition min-w-0">
              <Sparkles className="w-5 h-5 text-gray-600 shrink-0" />
              <span className="text-sm font-medium text-slate-700 truncate">تنظیمات</span>
            </Link>
          </div>
        </section>
      </div>

      {/* دکمه شناور وسط صفحه، ارتفاع 140px */}
      <div className="fixed left-1/2 -translate-x-1/2 bottom-[140px] z-50 flex flex-col items-center">
        {fabOpen && (
          <div className="mb-3 flex flex-col gap-2 w-48 bg-white rounded-2xl p-3 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-slate-500">اقدام سریع</span>
              <button onClick={() => setFabOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>
            {quickActions.map((action) => (
              <Link key={action.label} href={action.href} onClick={() => setFabOpen(false)} className="flex items-center gap-3 p-2 rounded-xl hover:bg-slate-50 transition">
                <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center shrink-0">
                  <action.icon className={`w-4 h-4 ${action.color}`} />
                </div>
                <span className="text-sm text-slate-700 truncate">{action.label}</span>
              </Link>
            ))}
          </div>
        )}
        <button
          onClick={() => setFabOpen(!fabOpen)}
          className="w-14 h-14 rounded-full bg-blue-600 text-white shadow-lg hover:bg-blue-700 hover:shadow-xl transition flex items-center justify-center"
        >
          <Plus className={`w-6 h-6 transition-transform ${fabOpen ? "rotate-45" : ""}`} />
        </button>
      </div>
    </main>
  );
}