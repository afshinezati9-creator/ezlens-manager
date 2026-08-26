"use client";

import { useEffect, useState } from "react";
import { 
  Settings, Type, Bell, Shield, Database, Save, 
  Link2, Moon, Sun, CheckCircle2, XCircle, Palette, Image,
  Download, FileJson, FileSpreadsheet, Package, Users, ImageIcon, MessageSquare, FileText, NotebookPen
} from "lucide-react";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

type NotificationSettings = {
  orders: boolean;
  comments: boolean;
  notes: boolean;
};

type SettingsData = {
  siteName: string;
  siteLogo: string;
  fontFamily: string;
  theme: string;
  apiBaseUrl: string;
  notifications: NotificationSettings;
  dateFormat: string;
  currency: string;
};

const EXPORT_TYPES = [
  { key: "orders", label: "سفارش‌ها", icon: Package, color: "text-blue-600 bg-blue-50" },
  { key: "users", label: "کاربران", icon: Users, color: "text-emerald-600 bg-emerald-50" },
  { key: "media", label: "رسانه‌ها", icon: ImageIcon, color: "text-purple-600 bg-purple-50" },
  { key: "comments", label: "نظرات", icon: MessageSquare, color: "text-amber-600 bg-amber-50" },
  { key: "requests", label: "درخواست‌ها", icon: FileText, color: "text-rose-600 bg-rose-50" },
  { key: "notes", label: "یادداشت‌ها", icon: NotebookPen, color: "text-indigo-600 bg-indigo-50" },
];

export default function SettingsPage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [exporting, setExporting] = useState<string | null>(null);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  
  // State برای فیلتر تاریخ
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  
  const [form, setForm] = useState<SettingsData>({
    siteName: "EzLens Manager",
    siteLogo: "",
    fontFamily: "vazirmatn",
    theme: "light",
    apiBaseUrl: "https://ezlens.ir",
    notifications: { orders: true, comments: true, notes: false },
    dateFormat: "fa-IR",
    currency: "تومان"
  });

  useEffect(() => {
    async function loadSettings() {
      try {
        const res = await fetch("/api/settings");
        const data = await res.json();
        if (res.ok) setForm(data);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    }
    loadSettings();
  }, []);

  async function saveSettings() {
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch("/api/settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form)
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "خطا در ذخیره");
      setMessage("تنظیمات با موفقیت ذخیره شد");
    } catch (e: any) {
      setError(e.message || "خطا در ذخیره");
    } finally {
      setSaving(false);
    }
  }

  // تابع خروجی‌گیری با فرمت و تاریخ
  async function exportData(type: string, format: "json" | "csv") {
    setExporting(type + format);
    setError("");
    setMessage("");
    try {
      const params = new URLSearchParams({ type, format });
      if (dateFrom) params.set("from", new Date(dateFrom).toISOString());
      if (dateTo) params.set("to", new Date(dateTo).toISOString());

      const res = await fetch(`/api/export?${params.toString()}`);
      if (!res.ok) throw new Error("خطا در خروجی‌گیری");
      
      // اگر CSV بود
      if (format === "csv") {
        const blob = await res.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `backup-${type}-${new Date().toISOString().split("T")[0]}.csv`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
      } else {
        // اگر JSON بود
        const data = await res.json();
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `backup-${type}-${new Date().toISOString().split("T")[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
      }
      
      setMessage("فایل با موفقیت دانلود شد");
    } catch (e: any) {
      setError(e.message || "خطا در خروجی‌گیری");
    } finally {
      setExporting(null);
    }
  }

  useEffect(() => {
    if (form.fontFamily === "vazirmatn") {
      document.documentElement.style.setProperty('--font-app', 'Vazirmatn, sans-serif');
    } else if (form.fontFamily === "iransans") {
      document.documentElement.style.setProperty('--font-app', 'IRANSans, sans-serif');
    } else {
      document.documentElement.style.setProperty('--font-app', 'Inter, sans-serif');
    }
    
    if (form.theme === "dark") {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }, [form.fontFamily, form.theme]);

  if (loading) {
    return <div className="flex justify-center items-center h-64 text-slate-400">در حال بارگذاری تنظیمات...</div>;
  }

  return (
    <main className="min-h-screen bg-slate-50 py-6">
      <div className="max-w-4xl mx-auto px-4 space-y-6">
        
        {/* هدر صفحه */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
              <Settings className="w-6 h-6 text-blue-600" />
              تنظیمات
            </h1>
            <p className="text-sm text-slate-500 mt-1">مدیریت تنظیمات کلی و ظاهری برنامه</p>
          </div>
          <button
            onClick={saveSettings}
            disabled={saving}
            className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition"
          >
            <Save className="w-4 h-4" />
            {saving ? "در حال ذخیره..." : "ذخیره تغییرات"}
          </button>
        </div>

        {message && <div className="flex items-center gap-2 bg-emerald-50 text-emerald-700 px-4 py-3 rounded-xl text-sm"><CheckCircle2 className="w-5 h-5" /> {message}</div>}
        {error && <div className="flex items-center gap-2 bg-red-50 text-red-700 px-4 py-3 rounded-xl text-sm"><XCircle className="w-5 h-5" /> {error}</div>}

        {/* کارت تنظیمات عمومی */}
        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <Type className="w-5 h-5 text-blue-600" />
            عمومی
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">نام سایت</label>
              <input
                type="text"
                value={form.siteName}
                onChange={(e) => setForm({ ...form, siteName: e.target.value })}
                className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">آدرس لوگو</label>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={form.siteLogo}
                  onChange={(e) => setForm({ ...form, siteLogo: e.target.value })}
                  placeholder="https://..."
                  className="flex-1 border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
                />
                <div className="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center text-slate-400">
                  <Image className="w-5 h-5" />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* کارت ظاهر و فونت */}
        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <Palette className="w-5 h-5 text-purple-600" />
            ظاهر و فونت
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">فونت برنامه</label>
              <div className="grid grid-cols-1 gap-2">
                <button
                  onClick={() => setForm({ ...form, fontFamily: "vazirmatn" })}
                  className={`text-right px-4 py-3 rounded-xl border transition ${form.fontFamily === "vazirmatn" ? "border-blue-500 bg-blue-50" : "border-slate-200 hover:bg-slate-50"}`}
                >
                  <span className="block text-slate-800 font-bold">وزیرمتن (Vazirmatn)</span>
                  <span className="text-xs text-slate-400">فونت پیش‌فرض و خوانا</span>
                </button>
                <button
                  onClick={() => setForm({ ...form, fontFamily: "iransans" })}
                  className={`text-right px-4 py-3 rounded-xl border transition ${form.fontFamily === "iransans" ? "border-blue-500 bg-blue-50" : "border-slate-200 hover:bg-slate-50"}`}
                >
                  <span className="block text-slate-800 font-bold">ایران‌سنس (IRANSans)</span>
                  <span className="text-xs text-slate-400">فونت مدرن و نرم</span>
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">حالت نمایش (تم)</label>
              <div className="flex gap-2">
                <button
                  onClick={() => setForm({ ...form, theme: "light" })}
                  className={`flex items-center gap-2 flex-1 justify-center px-4 py-3 rounded-xl border transition ${form.theme === "light" ? "border-blue-500 bg-blue-50 text-blue-700" : "border-slate-200 text-slate-600 hover:bg-slate-50"}`}
                >
                  <Sun className="w-5 h-5" />
                  روشن
                </button>
                <button
                  onClick={() => setForm({ ...form, theme: "dark" })}
                  className={`flex items-center gap-2 flex-1 justify-center px-4 py-3 rounded-xl border transition ${form.theme === "dark" ? "border-blue-500 bg-blue-50 text-blue-700" : "border-slate-200 text-slate-600 hover:bg-slate-50"}`}
                >
                  <Moon className="w-5 h-5" />
                  تیره
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* کارت API و اتصال */}
        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <Database className="w-5 h-5 text-emerald-600" />
            اتصال به وردپرس
          </h2>
          
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">آدرس پایه API</label>
            <div className="flex items-center gap-2 border border-slate-200 rounded-xl px-3 py-2.5">
              <Link2 className="w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={form.apiBaseUrl}
                onChange={(e) => setForm({ ...form, apiBaseUrl: e.target.value })}
                className="flex-1 bg-transparent text-sm outline-none"
                dir="ltr"
              />
            </div>
          </div>
        </section>

        {/* کارت اعلان‌ها */}
        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <Bell className="w-5 h-5 text-amber-600" />
            اعلان‌ها
          </h2>
          
          <div className="space-y-3">
            <div className="flex items-center justify-between bg-slate-50 rounded-xl p-4">
              <div>
                <div className="font-medium text-slate-800">اعلان سفارش‌ها</div>
                <div className="text-xs text-slate-400">اعلان در مورد سفارش‌های جدید</div>
              </div>
              <button
                onClick={() => setForm({ ...form, notifications: { ...form.notifications, orders: !form.notifications.orders } })}
                className={`w-12 h-6 rounded-full transition relative ${form.notifications.orders ? "bg-blue-600" : "bg-slate-300"}`}
              >
                <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full transition-all ${form.notifications.orders ? "left-0.5" : "left-6"}`} />
              </button>
            </div>
            <div className="flex items-center justify-between bg-slate-50 rounded-xl p-4">
              <div>
                <div className="font-medium text-slate-800">اعلان نظرات</div>
                <div className="text-xs text-slate-400">اعلان در مورد نظرات جدید</div>
              </div>
              <button
                onClick={() => setForm({ ...form, notifications: { ...form.notifications, comments: !form.notifications.comments } })}
                className={`w-12 h-6 rounded-full transition relative ${form.notifications.comments ? "bg-blue-600" : "bg-slate-300"}`}
              >
                <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full transition-all ${form.notifications.comments ? "left-0.5" : "left-6"}`} />
              </button>
            </div>
            <div className="flex items-center justify-between bg-slate-50 rounded-xl p-4">
              <div>
                <div className="font-medium text-slate-800">اعلان یادداشت‌ها</div>
                <div className="text-xs text-slate-400">اعلان در مورد یادداشت‌ها</div>
              </div>
              <button
                onClick={() => setForm({ ...form, notifications: { ...form.notifications, notes: !form.notifications.notes } })}
                className={`w-12 h-6 rounded-full transition relative ${form.notifications.notes ? "bg-blue-600" : "bg-slate-300"}`}
              >
                <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full transition-all ${form.notifications.notes ? "left-0.5" : "left-6"}`} />
              </button>
            </div>
          </div>
        </section>

        {/* کارت امنیتی و اطلاعات */}
        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <Shield className="w-5 h-5 text-red-600" />
            امنیت و اطلاعات
          </h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">فرمت تاریخ</label>
              <select
                value={form.dateFormat}
                onChange={(e) => setForm({ ...form, dateFormat: e.target.value })}
                className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
              >
                <option value="fa-IR">شمسی (fa-IR)</option>
                <option value="en-US">میلادی (en-US)</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">واحد پول</label>
              <input
                type="text"
                value={form.currency}
                onChange={(e) => setForm({ ...form, currency: e.target.value })}
                className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </section>

        {/* 🎯 کارت خروجی‌گیری و بکاپ با فیلتر تاریخ */}
        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <Download className="w-5 h-5 text-emerald-600" />
            خروجی‌گیری و بکاپ
          </h2>
          <p className="text-sm text-slate-500">بازه تاریخی را انتخاب کنید و داده‌ها را به صورت JSON یا اکسل (CSV) دانلود کنید.</p>

          {/* فیلتر تاریخ */}
          <div className="flex flex-col md:flex-row gap-4 items-end bg-slate-50 p-4 rounded-xl">
            <div className="flex-1">
              <label className="block text-xs font-medium text-slate-500 mb-1">از تاریخ</label>
              <DatePicker
                value={dateFrom}
                onChange={(d) => setDateFrom(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="انتخاب تاریخ شروع"
              />
            </div>
            <div className="flex-1">
              <label className="block text-xs font-medium text-slate-500 mb-1">تا تاریخ</label>
              <DatePicker
                value={dateTo}
                onChange={(d) => setDateTo(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="انتخاب تاریخ پایان"
              />
            </div>
            {(dateFrom || dateTo) && (
              <button
                onClick={() => { setDateFrom(""); setDateTo(""); }}
                className="px-3 py-2.5 text-xs text-red-600 border border-red-200 rounded-xl hover:bg-red-50"
              >
                پاک کردن تاریخ
              </button>
            )}
          </div>

          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            {/* دکمه بکاپ کامل JSON */}
            <button
              onClick={() => exportData("all", "json")}
              disabled={exporting !== null}
              className="flex flex-col items-center gap-2 p-4 rounded-xl border border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition disabled:opacity-50"
            >
              <FileJson className="w-8 h-8" />
              <span className="text-sm font-bold">بکاپ کامل (JSON)</span>
            </button>
            
            {/* دکمه بکاپ کامل اکسل */}
            <button
              onClick={() => exportData("all", "csv")}
              disabled={exporting !== null}
              className="flex flex-col items-center gap-2 p-4 rounded-xl border border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100 transition disabled:opacity-50"
            >
              <FileSpreadsheet className="w-8 h-8" />
              <span className="text-sm font-bold">بکاپ کامل (اکسل)</span>
            </button>

            {EXPORT_TYPES.map((item) => (
              <div key={item.key} className="flex flex-col gap-2 p-4 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 transition">
                <div className="flex items-center gap-2">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${item.color}`}>
                    <item.icon className="w-5 h-5" />
                  </div>
                  <span className="text-sm font-bold text-slate-700">{item.label}</span>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => exportData(item.key, "json")}
                    disabled={exporting !== null}
                    className="flex-1 py-1.5 rounded-lg text-xs bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition disabled:opacity-50"
                  >
                    JSON
                  </button>
                  <button
                    onClick={() => exportData(item.key, "csv")}
                    disabled={exporting !== null}
                    className="flex-1 py-1.5 rounded-lg text-xs bg-blue-50 text-blue-600 hover:bg-blue-100 transition disabled:opacity-50"
                  >
                    اکسل
                  </button>
                </div>
              </div>
            ))}
          </div>

          {exporting && (
            <div className="text-sm text-slate-500 flex items-center gap-2">
              <span className="animate-spin">⏳</span>
              در حال خروجی‌گیری...
            </div>
          )}
        </section>

      </div>
    </main>
  );
}