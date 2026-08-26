"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";

export default function EditMediaPage() {
  const params = useParams();
  const router = useRouter();
  const id = String(params.id || "");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [title, setTitle] = useState("");
  const [altText, setAltText] = useState("");
  const [media, setMedia] = useState<any>(null);

  useEffect(() => {
    async function load() {
      if (!id) return;
      setLoading(true);
      try {
        const res = await fetch(`/api/media/${id}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || "خطا در دریافت اطلاعات");
        setMedia(data);
        setTitle(data.title?.rendered || "");
        setAltText(data.alt_text || "");
      } catch (e: any) {
        setError(e?.message || "خطای ناشناخته");
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [id]);

  async function save() {
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/media/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title, alt_text: altText }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ذخیره ناموفق");
      setMessage("تغییرات با موفقیت ذخیره شد");
      router.push("/media");
    } catch (e: any) {
      setError(e?.message || "خطا در ذخیره");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div className="p-6 animate-pulse max-w-4xl mx-auto">در حال دریافت اطلاعات...</div>;

  return (
    <div className="min-h-screen bg-slate-50 py-10">
      <main className="max-w-4xl mx-auto p-4 md:p-6 space-y-6 pb-12">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-slate-900">ویرایش رسانه</h1>
          <Link href="/media" className="text-sm text-slate-600 hover:text-slate-900">← بازگشت به لیست</Link>
        </div>

        {error && <div className="bg-red-50 text-red-600 rounded-xl p-3 text-sm">{error}</div>}
        {message && <div className="bg-emerald-50 text-emerald-600 rounded-xl p-3 text-sm">{message}</div>}

        <div className="bg-white border rounded-2xl p-6 space-y-4" style={{ borderColor: "var(--border)" }}>
          <div className="flex justify-center bg-slate-50 rounded-xl overflow-hidden max-h-96">
            {media?.type === "image" ? (
              <img src={media.source_url} alt={media.alt_text} className="object-contain max-h-96" />
            ) : (
              <video src={media.source_url} controls className="max-h-96" />
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1">عنوان</label>
              <input value={title} onChange={(e) => setTitle(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1">متن جایگزین (Alt Text)</label>
              <input value={altText} onChange={(e) => setAltText(e.target.value)} className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
          </div>

          <div className="border-t pt-4 text-sm text-slate-500" style={{ borderColor: "var(--border)" }}>
            <div>حجم: {media?.media_details?.filesize ? (media.media_details.filesize / 1024).toFixed(1) + " KB" : "—"}</div>
            <div>ابعاد: {media?.media_details?.width || "—"} × {media?.media_details?.height || "—"}</div>
            <div>تاریخ ایجاد: {media?.date ? new Intl.DateTimeFormat('fa-IR-u-ca-persian').format(new Date(media.date)) : "—"}</div>
          </div>

          <button onClick={save} disabled={saving} className="w-full py-3 rounded-xl text-white text-sm font-bold shadow-md hover:shadow-lg transition disabled:opacity-50" style={{ background: "var(--primary)" }}>
            {saving ? "در حال ذخیره..." : "ذخیره تغییرات"}
          </button>
        </div>
      </main>
    </div>
  );
}