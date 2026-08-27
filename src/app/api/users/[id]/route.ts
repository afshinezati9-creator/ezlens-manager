"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";

export default function EditUserPage() {
  const params = useParams();
  const router = useRouter();
  const id = String(params.id || "");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [first_name, setFirstName] = useState("");
  const [last_name, setLastName] = useState("");
  const [company, setCompany] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("customer");
  const [password, setPassword] = useState("");
  const [avatarUrl, setAvatarUrl] = useState("");

  const [state, setState] = useState("");
  const [address1, setAddress1] = useState("");
  const [city, setCity] = useState("");
  const [postcode, setPostcode] = useState("");
  
  // ✅ خط اضافه شده برای رفع خطا
  const [internalNote, setInternalNote] = useState("");

  useEffect(() => {
    async function load() {
      if (!id || id === "new") return;
      setLoading(true);
      try {
        const res = await fetch(`/api/users/${id}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || "خطا در دریافت کاربر");

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

        const avatarMeta = data.meta_data?.find((m: any) => m.key === "_ezlens_avatar_url");
        setAvatarUrl(avatarMeta?.value || data.avatar_url || "");

        const note = data.meta_data?.find((m: any) => m.key === "internal_note");
        setInternalNote(note?.value || "");
      } catch (e: any) {
        setError(e?.message || "خطای ناشناخته");
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [id]);

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
          first_name, last_name, email, role, password, phone,
          billing, shipping: billing, meta_data, avatar_url: avatarUrl
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

  if (loading) return <div className="p-6 animate-pulse">در حال دریافت اطلاعات...</div>;

  return (
    <main className="min-h-screen bg-slate-50 py-10">
      <div className="max-w-4xl mx-auto p-4 md:p-6 space-y-6 pb-12">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-slate-900">ویرایش مخاطب</h1>
          <Link href="/users" className="text-sm text-slate-600 hover:text-slate-900">← بازگشت به لیست</Link>
        </div>

        {error && <div className="rounded-xl px-4 py-3 text-sm text-white bg-red-500 shadow-sm">{error}</div>}
        {message && <div className="rounded-xl px-4 py-3 text-sm text-white bg-emerald-500 shadow-sm">{message}</div>}

        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-sm font-semibold text-slate-800">اطلاعات هویتی و پروفایل</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div><label className="block text-xs font-medium text-slate-500 mb-1.5">نام</label><input value={first_name} onChange={(e) => setFirstName(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium text-slate-500 mb-1.5">نام خانوادگی</label><input value={last_name} onChange={(e) => setLastName(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium text-slate-500 mb-1.5">شماره موبایل</label><input value={phone} onChange={(e) => setPhone(e.target.value.replace(/[^0-9]/g, ''))} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium text-slate-500 mb-1.5">ایمیل</label><input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium text-slate-500 mb-1.5">نقش</label><select value={role} onChange={(e) => setRole(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none bg-white"><option value="customer">مشتری</option><option value="subscriber">کاربر</option></select></div>
          </div>
        </section>

        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-sm font-semibold text-slate-800">آدرس</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div><label className="block text-xs font-medium text-slate-500 mb-1">استان</label><input value={state} onChange={(e) => setState(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium text-slate-500 mb-1">شهر</label><input value={city} onChange={(e) => setCity(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
            <div className="md:col-span-2"><label className="block text-xs font-medium text-slate-500 mb-1">آدرس</label><input value={address1} onChange={(e) => setAddress1(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium text-slate-500 mb-1">کد پستی</label><input value={postcode} onChange={(e) => setPostcode(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" /></div>
          </div>
        </section>

        <section className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
          <h2 className="text-sm font-semibold text-slate-800">یادداشت داخلی</h2>
          <textarea value={internalNote} onChange={(e) => setInternalNote(e.target.value)} rows={4} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none" />
        </section>

        <button onClick={saveUser} disabled={saving} className="w-full py-3 rounded-xl text-white text-sm font-bold shadow-md hover:shadow-lg transition disabled:opacity-50" style={{ background: "var(--primary)" }}>
          {saving ? "در حال ذخیره..." : "ذخیره تغییرات"}
        </button>
      </div>
    </main>
  );
}