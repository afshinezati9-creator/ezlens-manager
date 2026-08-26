"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";

const COLORS = {
  yellow: { label: "زرد", bg: "#fef9c3", border: "#fde047" },
  blue: { label: "آبی", bg: "#dbeafe", border: "#60a5fa" },
  green: { label: "سبز", bg: "#dcfce7", border: "#4ade80" },
  red: { label: "قرمز", bg: "#fee2e2", border: "#f87171" },
  purple: { label: "بنفش", bg: "#f3e8ff", border: "#c084fc" },
} as const;

export default function EditNotePage() {
  const params = useParams();
  const router = useRouter();
  const id = String(params.id || "");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [color, setColor] = useState("yellow");
  const [priority, setPriority] = useState("low");
  const [checklist, setChecklist] = useState<{ id: number; text: string; done: boolean }[]>([]);
  const [files, setFiles] = useState<{ url: string; name: string }[]>([]);

  useEffect(() => {
    async function load() {
      if (!id) return;
      setLoading(true);
      try {
        const res = await fetch(`/api/notes/${id}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || "خطا در دریافت یادداشت");
        setTitle(data.title || "");
        setContent(data.content || "");
        setColor(data.color || "yellow");
        setPriority(data.priority || "low");
        setChecklist(data.checklist || []);
        setFiles(data.files || []);
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
      const res = await fetch(`/api/notes/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title, content, color, priority, checklist, files }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ذخیره ناموفق");
      setMessage("تغییرات ذخیره شد");
      router.push("/notes");
    } catch (e: any) {
      setError(e?.message || "خطا در ذخیره");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div className="p-6 animate-pulse">در حال دریافت...</div>;

  return (
    <div className="min-h-screen bg-slate-50 py-10">
      <main className="max-w-4xl mx-auto p-6 space-y-6 pb-12">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-slate-900">ویرایش یادداشت</h1>
          <Link href="/notes" className="text-sm text-slate-600 hover:text-slate-900">← بازگشت</Link>
        </div>

        {error && <div className="bg-red-50 text-red-600 rounded-xl p-3 text-sm">{error}</div>}
        {message && <div className="bg-emerald-50 text-emerald-600 rounded-xl p-3 text-sm">{message}</div>}

        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">عنوان</label>
            <input value={title} onChange={(e) => setTitle(e.target.value)} className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none" />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">توضیحات</label>
            <textarea value={content} onChange={(e) => setContent(e.target.value)} rows={5} className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">رنگ</label>
              <div className="flex gap-2">
                {Object.entries(COLORS).map(([key, val]) => (
                  <button key={key} onClick={() => setColor(key)} className={`w-8 h-8 rounded-full border-2 ${color === key ? "border-blue-500" : "border-transparent"}`} style={{ background: val.border }} />
                ))}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">اولویت</label>
              <select value={priority} onChange={(e) => setPriority(e.target.value)} className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white">
                <option value="low">کم</option>
                <option value="medium">متوسط</option>
                <option value="high">بحرانی</option>
              </select>
            </div>
          </div>

          {/* چک‌لیست */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="block text-sm font-medium text-slate-700">چک‌لیست</label>
              <button onClick={() => setChecklist(prev => [...prev, { id: Date.now(), text: "", done: false }])} className="px-2 py-1 rounded-lg text-xs bg-blue-50 text-blue-600">+ افزودن</button>
            </div>
            <div className="space-y-2">
              {checklist.map((item) => (
                <div key={item.id} className="flex items-center gap-2">
                  <input type="checkbox" checked={item.done} onChange={(e) => setChecklist(prev => prev.map(i => i.id === item.id ? { ...i, done: e.target.checked } : i))} />
                  <input value={item.text} onChange={(e) => setChecklist(prev => prev.map(i => i.id === item.id ? { ...i, text: e.target.value } : i))} className="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-sm" />
                  <button onClick={() => setChecklist(prev => prev.filter(i => i.id !== item.id))} className="text-red-500">✕</button>
                </div>
              ))}
            </div>
          </div>

          {/* فایل‌ها */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">فایل‌ها</label>
            <div className="space-y-2">
              {files.map((file, idx) => (
                <div key={idx} className="flex items-center gap-2 bg-slate-50 p-2 rounded-lg">
                  <span className="text-sm">📎</span>
                  <span className="flex-1 text-sm truncate">{file.name}</span>
                  <a href={file.url} target="_blank" className="text-xs text-blue-600">مشاهده</a>
                  <button onClick={() => setFiles(prev => prev.filter((_, i) => i !== idx))} className="text-red-500">✕</button>
                </div>
              ))}
            </div>
          </div>

          <button onClick={save} disabled={saving} className="w-full py-3 rounded-xl text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50">
            {saving ? "در حال ذخیره..." : "ذخیره تغییرات"}
          </button>
        </div>
      </main>
    </div>
  );
}