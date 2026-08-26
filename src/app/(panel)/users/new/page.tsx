"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function NewUserPage() {
  const router = useRouter();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [first_name, setFirstName] = useState("");
  const [last_name, setLastName] = useState("");
  const [company, setCompany] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("customer"); // پیش‌فرض مشتری
  const [password, setPassword] = useState("");
  const [avatarUrl, setAvatarUrl] = useState("");

  const [state, setState] = useState("");
  const [address1, setAddress1] = useState("");
  const [city, setCity] = useState("");
  const [postcode, setPostcode] = useState("");

  // یادداشت داخلی (اختیاری در هنگام ساخت)
  const [internalNote, setInternalNote] = useState("");

  async function submitUser() {
    setSaving(true);
    setError("");
    setMessage("");

    const phoneRegex = /^09\d{9}$/;
    if (!first_name.trim() || !last_name.trim()) return setError("نام و نام خانوادگی الزامی است."), setSaving(false);
    if (!phoneRegex.test(phone)) return setError("شماره موبایل معتبر نیست. مثال: 09123456789"), setSaving(false);
    if (!email.trim() || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return setError("ایمیل معتبر وارد کنید."), setSaving(false);

    const billing = { first_name, last_name, company, phone, state, address_1: address1, city, postcode };
    const meta_data = [
      ...(internalNote ? [{ key: "_customer_notes", value: JSON.stringify([{ id: Date.now(), author: "مدیر سیستم", note: internalNote, date_created: new Date().toISOString() }]) }] : []),
      ...(avatarUrl ? [{ key: "_ezlens_avatar_url", value: avatarUrl }] : [])
    ];

    try {
      const res = await fetch("/api/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          first_name, last_name, phone, email, role, password, billing, shipping: billing, meta_data
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ذخیره ناموفق");
      
      setMessage("کاربر با موفقیت ایجاد شد!");
      setTimeout(() => router.push(`/users/${data.id}`), 1000);
    } catch (e: any) {
      setError(e?.message || "خطا در ذخیره");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="min-h-screen bg-slate-50 py-10">
      <main className="max-w-4xl mx-auto p-4 md:p-6 space-y-8 pb-12">
        
        {/* هدر مدرن */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 tracking-tight">افزودن مخاطب جدید</h1>
            <p className="text-sm text-slate-500 mt-1">پروفایل کامل مشتری را برای مدیریت بهتر ایجاد کنید.</p>
          </div>
          <Link href="/users" className="inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-900 transition">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
            بازگشت به لیست
          </Link>
        </div>

        {error && <div className="rounded-xl px-4 py-3 text-sm text-white bg-red-500 shadow-sm">{error}</div>}
        {message && <div className="rounded-xl px-4 py-3 text-sm text-white bg-emerald-500 shadow-sm">{message}</div>}

        {/* کارت پروفایل و آواتار */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 className="text-sm font-semibold text-slate-800">پروفایل و تصویر</h2>
          </div>
          <div className="p-6">
            <div className="flex flex-col sm:flex-row items-center gap-6 mb-8">
              <div className="relative group">
                <div className="w-28 h-28 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 border-2 border-dashed border-slate-300 overflow-hidden transition-all group-hover:border-blue-400">
                  {avatarUrl ? (
                    <img src={avatarUrl} alt="پیش‌نمایش" className="w-full h-full object-cover" />
                  ) : (
                    <svg className="w-14 h-14" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                  )}
                </div>
              </div>
              <div className="flex-1 w-full">
                <label className="block text-xs font-medium text-slate-500 mb-1.5">لینک تصویر پروفایل (URL)</label>
                <input 
                  value={avatarUrl} 
                  onChange={(e) => setAvatarUrl(e.target.value)} 
                  placeholder="https://example.com/avatar.jpg"
                  dir="ltr"
                  className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" 
                />
                <p className="text-[11px] text-slate-400 mt-1.5">لینک عکس را وارد کنید تا پیش‌نمایش آن به صورت زنده نمایش داده شود.</p>
              </div>
            </div>
          </div>
        </section>

        {/* کارت اطلاعات هویتی */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 className="text-sm font-semibold text-slate-800">اطلاعات هویتی و تماس</h2>
          </div>
          <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">نام</label>
              <input value={first_name} onChange={(e) => setFirstName(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">نام خانوادگی</label>
              <input value={last_name} onChange={(e) => setLastName(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">شماره موبایل (نام کاربری)</label>
              <input value={phone} onChange={(e) => setPhone(e.target.value.replace(/[^0-9]/g, ''))} dir="ltr" placeholder="09123456789" className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">ایمیل</label>
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} dir="ltr" className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">نام شرکت</label>
              <input value={company} onChange={(e) => setCompany(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">نقش کاربری</label>
              {/* فقط مشتری و کاربر */}
              <select value={role} onChange={(e) => setRole(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none bg-white focus:ring-2 focus:ring-blue-500">
                <option value="customer">مشتری</option>
                <option value="subscriber">کاربر</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">رمز عبور اولیه</label>
              <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} dir="ltr" placeholder="اختیاری" className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" />
            </div>
          </div>
        </section>

        {/* کارت آدرس */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 className="text-sm font-semibold text-slate-800">آدرس صورت‌حساب</h2>
          </div>
          <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">استان</label>
              <input value={state} onChange={(e) => setState(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">شهر</label>
              <input value={city} onChange={(e) => setCity(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-xs font-medium text-slate-500 mb-1.5">آدرس کامل</label>
              <input value={address1} onChange={(e) => setAddress1(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1.5">کد پستی</label>
              <input value={postcode} onChange={(e) => setPostcode(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
          </div>
        </section>

        {/* کارت یادداشت داخلی (اختیاری در ساخت) */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 className="text-sm font-semibold text-slate-800">یادداشت داخلی (اختیاری)</h2>
          </div>
          <div className="p-6">
            <textarea value={internalNote} onChange={(e) => setInternalNote(e.target.value)} rows={3} placeholder="توضیحات خصوصی درباره این مخاطب..." className="w-full border rounded-xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
        </section>

        {/* دکمه ذخیره */}
        <div className="sticky bottom-4 bg-white/80 backdrop-blur-sm border border-slate-200 rounded-2xl p-4 shadow-lg">
          <button onClick={submitUser} disabled={saving} className="w-full py-3.5 rounded-xl text-white text-sm font-bold shadow-md hover:shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed" style={{ background: "var(--primary)" }}>
            {saving ? "در حال ذخیره..." : "افزودن مخاطب به فروشگاه"}
          </button>
        </div>
      </main>
    </div>
  );
}