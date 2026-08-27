"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";

// تایپ یادداشت مشتری
type CustomerNote = {
  id: number;
  author: string;
  note: string;
  date_created: string;
};

export default function EditUserPage() {
  const params = useParams();
  const router = useRouter();
  const id = String(params.id || "");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // اطلاعات کاربر
  const [user, setUser] = useState<any>(null);
  const [orders, setOrders] = useState<any[]>([]);

  // فرم اطلاعات
  const [first_name, setFirstName] = useState("");
  const [last_name, setLastName] = useState("");
  const [company, setCompany] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("customer");
  const [password, setPassword] = useState("");
  const [avatarUrl, setAvatarUrl] = useState("");

  // آدرس
  const [state, setState] = useState("");
  const [address1, setAddress1] = useState("");
  const [city, setCity] = useState("");
  const [postcode, setPostcode] = useState("");

  // ✅ این دو خط رو اضافه کردم (همونجا که مشکل داشتی)
  const [internalNote, setInternalNote] = useState("");

  // یادداشت‌های داخلی
  const [notes, setNotes] = useState<CustomerNote[]>([]);
  const [newNote, setNewNote] = useState("");
  const [notesLoading, setNotesLoading] = useState(false);
  const [noteSubmitting, setNoteSubmitting] = useState(false);

  useEffect(() => {
    let alive = true;
    async function load() {
      if (!id || id === "new") return;
      setLoading(true);
      try {
        const res = await fetch(`/api/users/${id}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || "خطا در دریافت کاربر");
        if (!alive) return;

        setUser(data);
        setFirstName(data.first_name || "");
        setLastName(data.last_name || "");
        setCompany(data.billing?.company || "");
        setPhone(data.billing?.phone || data.username || "");
        setEmail(data.email || "");
        setRole(data.role || "customer");
        setState(data.billing?.state || "");
        setAddress1(data.billing?.address_1 || "");
        setCity(data.billing?.city || "");
        setPostcode(data.billing?.postcode || "");

        // آواتار
        const avatarMeta = data.meta_data?.find((m: any) => m.key === "_ezlens_avatar_url");
        setAvatarUrl(avatarMeta?.value || data.avatar_url || "");

        // دریافت سفارشات اخیر (با محافظت)
        try {
          const ordersRes = await fetch(`/api/orders?customer=${id}`);
          if (ordersRes.ok) {
            const ordersData = await ordersRes.json();
            if (Array.isArray(ordersData)) {
              setOrders(ordersData);
            } else {
              setOrders([]);
            }
          }
        } catch (e) {
          if (alive) setOrders([]);
        }

        // دریافت یادداشت‌ها
        loadNotes();
      } catch (e: any) {
        if (alive) setError(e?.message || "خطای ناشناخته");
      } finally {
        if (alive) setLoading(false);
      }
    }
    load();
    return () => { alive = false; };
  }, [id]);

  // دریافت یادداشت‌ها با AJAX
  async function loadNotes() {
    if (!id) return;
    setNotesLoading(true);
    try {
      const res = await fetch(`/api/users/${id}/notes`);
      const data = await res.json();
      if (Array.isArray(data)) {
        setNotes(data);
      } else {
        setNotes([]);
      }
    } catch (e) {
      setNotes([]);
    } finally {
      setNotesLoading(false);
    }
  }

  // افزودن یادداشت با AJAX
  async function submitNote() {
    if (!newNote.trim()) return;
    setNoteSubmitting(true);
    setError("");
    try {
      const res = await fetch(`/api/users/${id}/notes`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ note: newNote.trim(), author: "مدیر سیستم" }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در ثبت یادداشت");
      setNotes(prev => [data, ...prev]);
      setNewNote("");
    } catch (e: any) {
      setError(e?.message || "خطا در ثبت یادداشت");
    } finally {
      setNoteSubmitting(false);
    }
  }

  // ذخیره تغییرات اصلی
  async function saveUser() {
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const billing = { first_name, last_name, company, phone, state, address_1: address1, city, postcode };
      const meta_data = [
        { key: "internal_note", value: internalNote },
        ...(avatarUrl ? [{ key: "_ezlens_avatar_url", value: avatarUrl }] : [])
      ];

      const res = await fetch(`/api/users/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          first_name, last_name, email, role, password, phone, billing, shipping: billing, meta_data, avatar_url: avatarUrl
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ذخیره ناموفق");
      setMessage("تغییرات با موفقیت ذخیره شد");
      setPassword("");
    } catch (e: any) {
      setError(e?.message || "خطا در ذخیره");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 py-10">
        <div className="max-w-4xl mx-auto p-6 animate-pulse space-y-6">
          <div className="h-10 bg-slate-200 rounded-xl w-1/3"></div>
          <div className="h-40 bg-slate-200 rounded-2xl"></div>
          <div className="h-64 bg-slate-200 rounded-2xl"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 py-10">
      <main className="max-w-4xl mx-auto p-4 md:p-6 space-y-8 pb-12">
        
        {/* هدر صفحه */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 tracking-tight">ویرایش مخاطب</h1>
            <p className="text-sm text-slate-500 mt-1">آخرین به‌روزرسانی: اخیرا</p>
          </div>
          <Link href="/users" className="inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-900 transition">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
            بازگشت به لیست
          </Link>
        </div>

        {error && <div className="rounded-xl px-4 py-3 text-sm text-white bg-red-500 shadow-sm">{error}</div>}
        {message && <div className="rounded-xl px-4 py-3 text-sm text-white bg-emerald-500 shadow-sm">{message}</div>}

        {/* کارت آمار */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
            <div className="text-xs text-slate-500 mb-1">مجموع خرید</div>
            <div className="text-2xl font-bold text-slate-900">{user?.total_spent ? Number(user.total_spent).toLocaleString("fa-IR") : "۰"} <span className="text-sm text-slate-400 font-normal">تومان</span></div>
          </div>
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
            <div className="text-xs text-slate-500 mb-1">تعداد سفارش</div>
            <div className="text-2xl font-bold text-slate-900">{user?.orders_count || 0}</div>
          </div>
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
            <div className="text-xs text-slate-500 mb-1">تاریخ عضویت</div>
            <div className="text-sm font-bold text-slate-900">
              {user?.date_created ? new Intl.DateTimeFormat('fa-IR-u-ca-persian', { year: 'numeric', month: 'long', day: 'numeric' }).format(new Date(user.date_created)) : "—"}
            </div>
          </div>
        </section>

        {/* کارت اطلاعات هویتی و پروفایل */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 className="text-sm font-semibold text-slate-800">اطلاعات هویتی و پروفایل</h2>
          </div>
          <div className="p-6">
            <div className="flex flex-col sm:flex-row items-center gap-6 mb-8">
              <div className="w-24 h-24 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 border-2 border-dashed border-slate-300 overflow-hidden">
                {avatarUrl ? (
                  <img src={avatarUrl} alt="پروفایل" className="w-full h-full object-cover" />
                ) : (
                  <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                )}
              </div>
              <div className="flex-1 w-full">
                <label className="block text-xs font-medium text-slate-500 mb-1">لینک تصویر پروفایل</label>
                <input 
                  value={avatarUrl} 
                  onChange={(e) => setAvatarUrl(e.target.value)} 
                  dir="ltr"
                  className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" 
                  placeholder="https://example.com/avatar.jpg"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div><label className="block text-xs font-medium text-slate-500 mb-1.5">نام</label><input value={first_name} onChange={(e) => setFirstName(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" /></div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1.5">نام خانوادگی</label><input value={last_name} onChange={(e) => setLastName(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" /></div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1.5">شماره موبایل</label><input value={phone} onChange={(e) => setPhone(e.target.value.replace(/[^0-9]/g, ''))} dir="ltr" className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" /></div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1.5">ایمیل</label><input type="email" value={email} onChange={(e) => setEmail(e.target.value)} dir="ltr" className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" /></div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1.5">نام شرکت</label><input value={company} onChange={(e) => setCompany(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" /></div>
              <div>
                <label className="block text-xs font-medium text-slate-500 mb-1.5">نقش</label>
                <select value={role} onChange={(e) => setRole(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none bg-white focus:ring-2 focus:ring-blue-500">
                  <option value="customer">مشتری</option>
                  <option value="subscriber">کاربر</option>
                </select>
              </div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1.5">رمز عبور جدید</label><input type="password" value={password} onChange={(e) => setPassword(e.target.value)} dir="ltr" placeholder="اختیاری" className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 text-left" /></div>
            </div>
          </div>
        </section>

        {/* کارت سفارشات اخیر */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-800">خریدهای اخیر</h2>
            <span className="text-xs text-slate-400">{orders.length} سفارش</span>
          </div>
          <div className="p-6 space-y-3">
            {orders.length === 0 ? (
              <div className="text-center py-8 text-slate-400 text-sm">سفارشی برای این کاربر یافت نشد</div>
            ) : (
              orders.map((order: any) => (
                <div key={order.id} className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-100">
                  <div>
                    <div className="text-sm font-medium">سفارش #{order.id}</div>
                    <div className="text-xs text-slate-500">{new Intl.DateTimeFormat('fa-IR-u-ca-persian').format(new Date(order.date_created))}</div>
                  </div>
                  <div className="text-sm font-bold text-slate-800">{Number(order.total).toLocaleString("fa-IR")} تومان</div>
                  <Link href={`/orders/${order.id}`} className="text-blue-600 text-xs hover:underline">مشاهده</Link>
                </div>
              ))
            )}
          </div>
        </section>

        {/* کارت یادداشت‌های داخلی - حالا با AJAX و کامل */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 className="text-sm font-semibold text-slate-800">یادداشت‌های داخلی</h2>
            <p className="text-xs text-slate-400 mt-1">این یادداشت‌ها فقط برای مدیران قابل مشاهده است.</p>
          </div>
          <div className="p-6">
            {/* لیست یادداشت‌ها */}
            <div className="space-y-3 mb-5 max-h-72 overflow-y-auto">
              {notesLoading && <div className="text-center py-4 text-slate-400 text-sm">در حال بارگذاری...</div>}
              {!notesLoading && notes.length === 0 && (
                <div className="text-center py-6 text-slate-400 text-sm">هنوز یادداشتی ثبت نشده است.</div>
              )}
              {notes.map((note) => (
                <div key={note.id} className="bg-slate-50 rounded-xl p-4 border border-slate-100">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-semibold text-slate-600 flex items-center gap-1">
                      <svg className="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                      {note.author}
                    </span>
                    <span className="text-[11px] text-slate-400">
                      {new Intl.DateTimeFormat('fa-IR-u-ca-persian', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' }).format(new Date(note.date_created))}
                    </span>
                  </div>
                  <p className="text-sm text-slate-700">{note.note}</p>
                </div>
              ))}
            </div>

            {/* فرم افزودن یادداشت */}
            <div className="flex gap-2">
              <input
                value={newNote}
                onChange={(e) => setNewNote(e.target.value)}
                onKeyDown={(e) => { if (e.key === "Enter" && !noteSubmitting) submitNote(); }}
                placeholder="یادداشت جدید برای این مخاطب..."
                className="flex-1 border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
              />
              <button
                onClick={submitNote}
                disabled={noteSubmitting || !newNote.trim()}
                className="px-4 py-2.5 rounded-xl text-sm text-white disabled:opacity-50 transition"
                style={{ background: "var(--primary)" }}
              >
                {noteSubmitting ? "..." : "افزودن"}
              </button>
            </div>
          </div>
        </section>

        {/* کارت فایل‌های آپلودی */}
        <section className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 className="text-sm font-semibold text-slate-800">فایل‌های آپلودی</h2>
          </div>
          <div className="p-6">
            <div className="text-center py-6 text-slate-400 text-sm">فایل آپلودی برای این کاربر یافت نشد</div>
          </div>
        </section>

        {/* کارت آدرس و یادداشت داخلی قدیمی */}
        <section className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="p-5 border-b border-slate-100 bg-slate-50/50">
              <h2 className="text-sm font-semibold text-slate-800">آدرس صورت‌حساب</h2>
            </div>
            <div className="p-5 space-y-4">
              <div><label className="block text-xs font-medium text-slate-500 mb-1">استان</label><input value={state} onChange={(e) => setState(e.target.value)} className="w-full border rounded-lg px-3 py-2 text-sm outline-none" /></div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1">شهر</label><input value={city} onChange={(e) => setCity(e.target.value)} className="w-full border rounded-lg px-3 py-2 text-sm outline-none" /></div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1">آدرس</label><input value={address1} onChange={(e) => setAddress1(e.target.value)} className="w-full border rounded-lg px-3 py-2 text-sm outline-none" /></div>
              <div><label className="block text-xs font-medium text-slate-500 mb-1">کد پستی</label><input value={postcode} onChange={(e) => setPostcode(e.target.value)} className="w-full border rounded-lg px-3 py-2 text-sm outline-none" /></div>
            </div>
          </div>
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="p-5 border-b border-slate-100 bg-slate-50/50">
              <h2 className="text-sm font-semibold text-slate-800">یادداشت داخلی (قدیمی)</h2>
            </div>
            <div className="p-5">
              <textarea 
                value={internalNote} 
                onChange={(e) => setInternalNote(e.target.value)} 
                rows={6} 
                className="w-full border rounded-lg px-3 py-2 text-sm outline-none" 
                placeholder="یادداشت داخلی برای این کاربر..."
              />
            </div>
          </div>
        </section>

        {/* دکمه ذخیره */}
        <button onClick={saveUser} disabled={saving} className="w-full py-4 rounded-xl text-white text-sm font-bold shadow-md hover:shadow-lg transition disabled:opacity-50" style={{ background: "var(--primary)" }}>
          {saving ? "در حال ذخیره..." : "ذخیره تغییرات"}
        </button>
      </main>
    </div>
  );
}