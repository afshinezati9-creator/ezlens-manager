"use client";

import { useEffect, useMemo, useState } from "react";
import Pagination from "@/components/ui/Pagination";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

type NoteItem = {
  id: number;
  title: string;
  content: string;
  color: string;
  priority: string;
  checklist: { id: number; text: string; done: boolean }[];
  files: { url: string; name: string }[];
  date: string;
  modified: string;
  pinned: boolean;
  author_name: string;
};

const COLORS = {
  yellow: { label: "زرد", bg: "#fef9c3", border: "#fde047", text: "#854d0e" },
  blue: { label: "آبی", bg: "#dbeafe", border: "#60a5fa", text: "#1e40af" },
  green: { label: "سبز", bg: "#dcfce7", border: "#4ade80", text: "#166534" },
  red: { label: "قرمز", bg: "#fee2e2", border: "#f87171", text: "#991b1b" },
  purple: { label: "بنفش", bg: "#f3e8ff", border: "#c084fc", text: "#6b21a8" },
} as const;

const PRIORITIES = {
  low: { label: "کم", color: "bg-slate-100 text-slate-600" },
  medium: { label: "متوسط", color: "bg-amber-100 text-amber-700" },
  high: { label: "بحرانی", color: "bg-red-100 text-red-700" },
} as const;

function toFaDate(iso?: string) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleString("fa-IR-u-ca-persian", {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    });
  } catch { return iso; }
}

export default function NotesPage() {
  const [items, setItems] = useState<NoteItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [viewMode, setViewMode] = useState<"list" | "grid">("grid");

  const [q, setQ] = useState("");
  const [colorFilter, setColorFilter] = useState("all");
  const [priorityFilter, setPriorityFilter] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");

  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(9);
  const [totalPages, setTotalPages] = useState(1);

  const [modalOpen, setModalOpen] = useState(false);
  const [editingNote, setEditingNote] = useState<NoteItem | null>(null);
  const [viewItem, setViewItem] = useState<NoteItem | null>(null);
  const [deleteItem, setDeleteItem] = useState<NoteItem | null>(null);
  const [deleting, setDeleting] = useState(false);

  const [formTitle, setFormTitle] = useState("");
  const [formContent, setFormContent] = useState("");
  const [formColor, setFormColor] = useState("yellow");
  const [formPriority, setFormPriority] = useState("low");
  const [formChecklist, setFormChecklist] = useState<{ id: number; text: string; done: boolean }[]>([]);
  const [formFiles, setFormFiles] = useState<{ url: string; name: string }[]>([]);
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  async function load() {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`/api/notes`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در دریافت یادداشت‌ها");

      let list: NoteItem[] = data || [];

      if (q.trim()) {
        const term = q.trim().toLowerCase();
        list = list.filter((note) =>
          note.title.toLowerCase().includes(term) ||
          note.content.toLowerCase().includes(term)
        );
      }
      if (colorFilter !== "all") list = list.filter((note) => note.color === colorFilter);
      if (priorityFilter !== "all") list = list.filter((note) => note.priority === priorityFilter);
      if (dateFrom) {
        const from = new Date(dateFrom).getTime();
        list = list.filter((note) => new Date(note.date).getTime() >= from);
      }
      if (dateTo) {
        const to = new Date(dateTo).getTime() + 86400000;
        list = list.filter((note) => new Date(note.date).getTime() <= to);
      }

      setItems(list);
      setTotalPages(Math.max(1, Math.ceil(list.length / perPage)));
    } catch (e: any) {
      setError(e?.message || "خطای ناشناخته");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, perPage]);

  useEffect(() => {
    const t = setTimeout(() => { setPage(1); load(); }, 350);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, colorFilter, priorityFilter, dateFrom, dateTo]);

  function openCreate() {
    setEditingNote(null);
    setFormTitle("");
    setFormContent("");
    setFormColor("yellow");
    setFormPriority("low");
    setFormChecklist([]);
    setFormFiles([]);
    setModalOpen(true);
  }

  function openEdit(note: NoteItem) {
    setEditingNote(note);
    setFormTitle(note.title);
    setFormContent(note.content);
    setFormColor(note.color);
    setFormPriority(note.priority);
    setFormChecklist(note.checklist || []);
    setFormFiles(note.files || []);
    setModalOpen(true);
  }

  function addChecklistItem() {
    const newItem = { id: Date.now(), text: "", done: false };
    setFormChecklist(prev => [...prev, newItem]);
  }

  function updateChecklistItem(id: number, field: "text" | "done", value: string | boolean) {
    setFormChecklist(prev => prev.map(item => item.id === id ? { ...item, [field]: value } : item));
  }

  function removeChecklistItem(id: number) {
    setFormChecklist(prev => prev.filter(item => item.id !== id));
  }

  async function handleUpload(file: File) {
    setUploading(true);
    setError("");
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await fetch("/api/notes/upload", { method: "POST", body: fd });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "آپلود ناموفق");
      setFormFiles(prev => [...prev, { url: data.url, name: data.name }]);
    } catch (e: any) {
      setError(e?.message || "خطا در آپلود");
    } finally {
      setUploading(false);
    }
  }

  async function saveNote() {
    if (!formTitle.trim()) {
      setError("عنوان الزامی است");
      return;
    }
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const payload = {
        title: formTitle,
        content: formContent,
        color: formColor,
        priority: formPriority,
        checklist: formChecklist,
        files: formFiles,
      };
      const url = editingNote ? `/api/notes/${editingNote.id}` : "/api/notes";
      const method = editingNote ? "PUT" : "POST";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ذخیره ناموفق");
      setMessage("یادداشت با موفقیت ذخیره شد");
      setModalOpen(false);
      await load();
    } catch (e: any) {
      setError(e?.message || "خطا در ذخیره");
    } finally {
      setSaving(false);
    }
  }

  async function confirmDelete() {
    if (!deleteItem) return;
    setDeleting(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/notes/${deleteItem.id}`, { method: "DELETE" });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "حذف ناموفق");
      setItems(prev => prev.filter(item => item.id !== deleteItem.id));
      setMessage("یادداشت حذف شد");
      setDeleteItem(null);
    } catch (e: any) {
      setError(e?.message || "خطا در حذف");
    } finally {
      setDeleting(false);
    }
  }

  const pagedItems = items.slice((page - 1) * perPage, page * perPage);

  return (
    <main className="min-h-screen bg-slate-50 py-6">
      <div className="max-w-7xl mx-auto px-4 space-y-6">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-slate-900">دفترچه یادداشت</h1>
            <p className="text-sm text-slate-500 mt-1">مدیریت یادداشت‌ها، چک‌لیست‌ها و فایل‌های شما</p>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex border rounded-lg overflow-hidden bg-white">
              <button
                onClick={() => setViewMode("list")}
                className={`px-3 py-2 text-xs font-medium transition ${viewMode === "list" ? "bg-slate-100 text-slate-800" : "text-slate-500"}`}
              >
                لیستی
              </button>
              <button
                onClick={() => setViewMode("grid")}
                className={`px-3 py-2 text-xs font-medium transition ${viewMode === "grid" ? "bg-slate-100 text-slate-800" : "text-slate-500"}`}
              >
                دو ستونه
              </button>
            </div>
            <button
              onClick={openCreate}
              className="px-4 py-2.5 rounded-xl text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 transition shadow-sm"
            >
              + یادداشت جدید
            </button>
          </div>
        </div>

        {error && <div className="rounded-xl px-4 py-3 text-sm text-white bg-red-500 shadow-sm">{error}</div>}
        {message && <div className="rounded-xl px-4 py-3 text-sm text-white bg-emerald-500 shadow-sm">{message}</div>}

        <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="جستجو در یادداشت‌ها..."
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
            />
            <select
              value={colorFilter}
              onChange={(e) => { setColorFilter(e.target.value); setPage(1); }}
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
            >
              <option value="all">همه رنگ‌ها</option>
              {Object.entries(COLORS).map(([key, val]) => (
                <option key={key} value={key}>{val.label}</option>
              ))}
            </select>
            <select
              value={priorityFilter}
              onChange={(e) => { setPriorityFilter(e.target.value); setPage(1); }}
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
            >
              <option value="all">همه اولویت‌ها</option>
              {Object.entries(PRIORITIES).map(([key, val]) => (
                <option key={key} value={key}>{val.label}</option>
              ))}
            </select>
            <div className="grid grid-cols-2 gap-2">
              <DatePicker
                value={dateFrom}
                onChange={(d) => setDateFrom(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="از تاریخ"
              />
              <DatePicker
                value={dateTo}
                onChange={(d) => setDateTo(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="تا تاریخ"
              />
            </div>
          </div>
          <div className="flex items-center justify-between pt-3 border-t text-sm text-slate-500" style={{ borderColor: "var(--border)" }}>
            <div className="flex items-center gap-2">
              <span>تعداد در صفحه:</span>
              <select
                value={perPage}
                onChange={(e) => { setPerPage(Number(e.target.value)); setPage(1); }}
                className="border border-slate-200 rounded-lg px-2 py-1.5 text-sm outline-none bg-white"
              >
                <option value={6}>۶</option>
                <option value={9}>۹</option>
                <option value={12}>۱۲</option>
                <option value={18}>۱۸</option>
              </select>
            </div>
            <span>تعداد کل: {items.length.toLocaleString("fa-IR")} یادداشت</span>
          </div>
        </div>

        {loading && <div className="text-center py-10 text-slate-400">در حال بارگذاری...</div>}
        {!loading && pagedItems.length === 0 && !error && (
          <div className="bg-white border border-slate-200 rounded-2xl p-10 text-center text-slate-400">یادداشتی یافت نشد</div>
        )}

        {!loading && viewMode === "list" && pagedItems.length > 0 && (
          <div className="space-y-3">
            {pagedItems.map((note) => {
              const colorMeta = COLORS[note.color as keyof typeof COLORS] || COLORS.yellow;
              const priorityMeta = PRIORITIES[note.priority as keyof typeof PRIORITIES] || PRIORITIES.low;
              return (
                <div key={note.id} className="bg-white border border-slate-200 rounded-2xl p-4 hover:shadow-md transition" style={{ borderLeft: `4px solid ${colorMeta.border}` }}>
                  <div className="flex flex-col md:flex-row md:items-start gap-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <h3 className="font-bold text-slate-900 truncate">{note.title}</h3>
                        <span className={`text-[10px] px-2 py-0.5 rounded-full ${priorityMeta.color}`}>{priorityMeta.label}</span>
                      </div>
                      {note.content && <p className="mt-2 text-sm text-slate-600 line-clamp-2">{note.content}</p>}
                      <div className="mt-2 flex flex-wrap gap-2 text-xs text-slate-400">
                        <span>✍️ {note.author_name || "نامشخص"}</span>
                        <span>🕒 {toFaDate(note.modified || note.date)}</span>
                      </div>
                    </div>
                    <div className="flex gap-2 md:flex-col md:w-32 shrink-0">
                      <button onClick={() => setViewItem(note)} className="flex-1 py-1.5 rounded-lg text-xs bg-blue-50 text-blue-600 hover:bg-blue-100 transition">مشاهده</button>
                      <button onClick={() => openEdit(note)} className="flex-1 py-1.5 rounded-lg text-xs bg-amber-50 text-amber-600 hover:bg-amber-100 transition">ویرایش</button>
                      <button onClick={() => setDeleteItem(note)} className="flex-1 py-1.5 rounded-lg text-xs bg-red-50 text-red-600 hover:bg-red-100 transition">حذف</button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {!loading && viewMode === "grid" && pagedItems.length > 0 && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {pagedItems.map((note) => {
              const colorMeta = COLORS[note.color as keyof typeof COLORS] || COLORS.yellow;
              const priorityMeta = PRIORITIES[note.priority as keyof typeof PRIORITIES] || PRIORITIES.low;
              return (
                <div key={note.id} className="bg-white border border-slate-200 rounded-2xl overflow-hidden hover:shadow-md transition" style={{ borderTop: `4px solid ${colorMeta.border}` }}>
                  <div className="p-4">
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="font-bold text-slate-900 line-clamp-1">{note.title}</h3>
                      <span className={`text-[10px] px-2 py-0.5 rounded-full ${priorityMeta.color}`}>{priorityMeta.label}</span>
                    </div>
                    {note.content && <p className="mt-2 text-sm text-slate-600 line-clamp-3">{note.content}</p>}
                    {note.checklist && note.checklist.length > 0 && (
                      <div className="mt-3 space-y-1">
                        {note.checklist.slice(0, 3).map((item) => (
                          <div key={item.id} className="flex items-center gap-2 text-xs">
                            <span className={`w-3 h-3 rounded-full border ${item.done ? "bg-green-500 border-green-500" : "border-slate-300"}`} />
                            <span className={item.done ? "line-through text-slate-400" : "text-slate-600"}>{item.text || "..."}</span>
                          </div>
                        ))}
                        {note.checklist.length > 3 && <div className="text-xs text-slate-400">+ {note.checklist.length - 3} مورد دیگر</div>}
                      </div>
                    )}
                    {note.files && note.files.length > 0 && (
                      <div className="mt-3 flex gap-1">
                        {note.files.slice(0, 3).map((file, idx) => (
                          <span key={idx} className="text-xs bg-slate-100 px-2 py-1 rounded">📎 {file.name}</span>
                        ))}
                      </div>
                    )}
                    <div className="mt-3 flex items-center justify-between text-[10px] text-slate-400">
                      <span>✍️ {note.author_name || "نامشخص"}</span>
                      <span>🕒 {toFaDate(note.modified || note.date)}</span>
                    </div>
                  </div>
                  <div className="flex gap-1 p-3 pt-0">
                    <button onClick={() => setViewItem(note)} className="flex-1 py-1.5 rounded-lg text-xs bg-blue-50 text-blue-600 hover:bg-blue-100 transition">مشاهده</button>
                    <button onClick={() => openEdit(note)} className="flex-1 py-1.5 rounded-lg text-xs bg-amber-50 text-amber-600 hover:bg-amber-100 transition">ویرایش</button>
                    <button onClick={() => setDeleteItem(note)} className="flex-1 py-1.5 rounded-lg text-xs bg-red-50 text-red-600 hover:bg-red-100 transition">حذف</button>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <Pagination page={page} totalPages={totalPages} onChange={setPage} />
      </div>

      {modalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4" onClick={() => setModalOpen(false)}>
          <div className="bg-white w-full max-w-2xl rounded-2xl p-6 space-y-4 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg text-slate-900">{editingNote ? "ویرایش یادداشت" : "یادداشت جدید"}</h3>
              <button onClick={() => setModalOpen(false)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">عنوان *</label>
              <input value={formTitle} onChange={(e) => setFormTitle(e.target.value)} placeholder="مثلاً پیگیری سفارش..." className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">توضیحات</label>
              <textarea value={formContent} onChange={(e) => setFormContent(e.target.value)} rows={4} placeholder="توضیحات کامل یادداشت..." className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">رنگ</label>
                <div className="flex gap-2">
                  {Object.entries(COLORS).map(([key, val]) => (
                    <button key={key} onClick={() => setFormColor(key)} className={`w-8 h-8 rounded-full border-2 ${formColor === key ? "border-blue-500" : "border-transparent"}`} style={{ background: val.border }} title={val.label} />
                  ))}
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">اولویت</label>
                <select value={formPriority} onChange={(e) => setFormPriority(e.target.value)} className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white">
                  <option value="low">کم</option>
                  <option value="medium">متوسط</option>
                  <option value="high">بحرانی</option>
                </select>
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="block text-sm font-medium text-slate-700">چک‌لیست</label>
                <button onClick={addChecklistItem} className="px-2 py-1 rounded-lg text-xs bg-blue-50 text-blue-600 hover:bg-blue-100 transition">+ افزودن مورد</button>
              </div>
              <div className="space-y-2">
                {formChecklist.map((item) => (
                  <div key={item.id} className="flex items-center gap-2">
                    <input type="checkbox" checked={item.done} onChange={(e) => updateChecklistItem(item.id, "done", e.target.checked)} className="w-4 h-4 rounded" />
                    <input value={item.text} onChange={(e) => updateChecklistItem(item.id, "text", e.target.value)} placeholder="مورد چک‌لیست..." className="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
                    <button onClick={() => removeChecklistItem(item.id)} className="text-red-500 hover:text-red-700">✕</button>
                  </div>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">فایل‌های پیوست</label>
              <div className="space-y-2">
                {formFiles.map((file, idx) => (
                  <div key={idx} className="flex items-center gap-2 bg-slate-50 p-2 rounded-lg">
                    <span className="text-sm">📎</span>
                    <span className="flex-1 text-sm text-slate-600 truncate">{file.name}</span>
                    <a href={file.url} target="_blank" rel="noreferrer" className="text-xs text-blue-600 hover:underline">مشاهده</a>
                    <button onClick={() => setFormFiles(prev => prev.filter((_, i) => i !== idx))} className="text-red-500 hover:text-red-700">✕</button>
                  </div>
                ))}
              </div>
              <label className="block mt-2">
                <span className="text-sm text-blue-600 cursor-pointer hover:underline">{uploading ? "در حال آپلود..." : "+ آپلود فایل"}</span>
                <input type="file" className="hidden" disabled={uploading} onChange={(e) => { if (e.target.files?.[0]) handleUpload(e.target.files[0]); e.currentTarget.value = ""; }} />
              </label>
            </div>

            <div className="flex gap-2 pt-4 border-t border-slate-100">
              <button onClick={saveNote} disabled={saving} className="flex-1 py-2.5 rounded-xl text-sm text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition">{saving ? "در حال ذخیره..." : "ذخیره"}</button>
              <button onClick={() => setModalOpen(false)} className="px-4 py-2.5 rounded-xl text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 transition">انصراف</button>
            </div>
          </div>
        </div>
      )}

      {viewItem && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4" onClick={() => setViewItem(null)}>
          <div className="bg-white w-full max-w-2xl rounded-2xl p-6 space-y-4 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg text-slate-900">{viewItem.title}</h3>
              <button onClick={() => setViewItem(null)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <span>✍️ {viewItem.author_name || "نامشخص"}</span>
              <span>🕒 {toFaDate(viewItem.modified || viewItem.date)}</span>
            </div>
            {viewItem.content && <div className="text-sm text-slate-700 whitespace-pre-wrap">{viewItem.content}</div>}
            {viewItem.checklist && viewItem.checklist.length > 0 && (
              <div className="bg-slate-50 rounded-xl p-4 space-y-2">
                {viewItem.checklist.map((item) => (
                  <div key={item.id} className="flex items-center gap-2 text-sm">
                    <span className={`w-4 h-4 rounded-full border ${item.done ? "bg-green-500 border-green-500" : "border-slate-300"}`} />
                    <span className={item.done ? "line-through text-slate-400" : "text-slate-700"}>{item.text}</span>
                  </div>
                ))}
              </div>
            )}
            {viewItem.files && viewItem.files.length > 0 && (
              <div className="space-y-2">
                {viewItem.files.map((file, idx) => (
                  <a key={idx} href={file.url} target="_blank" rel="noreferrer" className="flex items-center gap-2 bg-slate-50 p-2 rounded-lg hover:bg-slate-100 transition">
                    <span className="text-sm">📎</span>
                    <span className="flex-1 text-sm text-slate-600 truncate">{file.name}</span>
                    <span className="text-xs text-blue-600">مشاهده</span>
                  </a>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {deleteItem && (
        <div className="fixed inset-0 z-[60] bg-black/60 flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-sm rounded-2xl p-6 space-y-4 text-center shadow-2xl">
            <div className="text-4xl">🗑️</div>
            <h3 className="font-bold text-lg text-slate-900">حذف یادداشت</h3>
            <p className="text-sm text-slate-500">آیا از حذف «{deleteItem.title}» مطمئن هستید؟</p>
            <div className="flex gap-2 pt-2">
              <button onClick={confirmDelete} disabled={deleting} className="flex-1 py-2.5 rounded-xl text-sm text-white bg-red-600 hover:bg-red-700 disabled:opacity-50 transition">{deleting ? "در حال حذف..." : "بله، حذف کن"}</button>
              <button onClick={() => setDeleteItem(null)} disabled={deleting} className="flex-1 py-2.5 rounded-xl text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-50 transition">انصراف</button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}