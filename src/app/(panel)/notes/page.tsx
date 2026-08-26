"use client";

import { useEffect, useState, useRef } from "react";
import dynamic from "next/dynamic";
import "react-quill-new/dist/quill.snow.css";
import Pagination from "@/components/ui/Pagination";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

import {
  Plus,
  Grid3x3,
  List,
  Pin,
  Eye,
  Edit,
  Trash2,
  X,
  Save,
  RefreshCw,
  AlertCircle,
  CheckCircle,
  Archive,
  Clock,
  Calendar,
  Tag,
  FileText,
  Code,
  Palette,
  CheckSquare,
  Square,
} from "lucide-react";

const ReactQuill = dynamic(() => import("react-quill-new"), { ssr: false });

const quillModules = {
  toolbar: [
    [{ header: [1, 2, 3, false] }],
    ["bold", "italic", "underline", "strike"],
    [{ list: "ordered" }, { list: "bullet" }],
    ["link", "image", "video"],
    ["blockquote", "code-block"],
    [{ align: [] }],
    [{ color: [] }, { background: [] }],
    ["clean"],
  ],
};

const quillFormats = [
  "header",
  "bold",
  "italic",
  "underline",
  "strike",
  "list",
  "bullet",
  "link",
  "image",
  "video",
  "blockquote",
  "code-block",
  "align",
  "color",
  "background",
];

type ChecklistItem = {
  id: number;
  text: string;
  done: boolean;
};

type NoteItem = {
  id: number;
  title: string;
  content: string;
  color: string;
  priority: string;
  checklist: ChecklistItem[];
  files: { url: string; name: string }[];
  date: string;
  modified: string;
  pinned: boolean;
  author_name: string;
  tags: string[];
  deadline: string;
  html: string;
  css: string;
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
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

function formatContent(text: string): string {
  if (!text) return "";
  if (text.includes("<") && text.includes(">")) return text;
  return text
    .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
    .replace(/\*(.*?)\*/g, "<em>$1</em>")
    .replace(/==(.*?)==/g, '<mark class="bg-yellow-200 px-1 rounded">$1</mark>')
    .replace(/!!(.*?)!!/g, '<span class="text-red-600 font-bold">$1</span>')
    .replace(/\n/g, "<br>");
}

// ✅ تبدیل هر نوع داده به آرایه‌ای از {id, text, done}
function normalizeChecklist(value: any): ChecklistItem[] {
  if (Array.isArray(value)) {
    if (value.length > 0 && typeof value[0] === "object" && value[0]?.text !== undefined) {
      return value.map((item: any) => ({
        id: item.id || Date.now() + Math.random() * 1000,
        text: item.text || "",
        done: !!item.done,
      }));
    }
    if (value.length > 0 && typeof value[0] === "string") {
      return value.map((text, index) => ({
        id: Date.now() + index,
        text,
        done: false,
      }));
    }
    return [];
  }
  return [];
}

const TEMPLATES = [
  {
    id: "product",
    label: "📦 محصول جدید",
    title: "بررسی محصول جدید",
    color: "blue",
    content:
      "<h3>نام محصول:</h3><p><br></p><h3>برند:</h3><p><br></p><h3>قیمت:</h3><p><br></p><h3>مشخصات فنی:</h3><p><br></p><h3>نکات بازاریابی:</h3><ul><li> </li></ul>",
    checklist: ["بررسی موجودی انبار", "تنظیم قیمت رقابتی"],
  },
  {
    id: "order",
    label: "📋 پیگیری سفارش",
    title: "وضعیت سفارش مشتری",
    color: "green",
    content:
      "<h3>شماره سفارش:</h3><p><br></p><h3>مشتری:</h3><p><br></p><h3>وضعیت فعلی:</h3><p><br></p><h3>مشکل/نکته:</h3><p><br></p><h3>اقدام بعدی:</h3><p><br></p>",
    checklist: ["تماس با مشتری", "بررسی هزینه ارسال"],
  },
  {
    id: "content",
    label: "✍️ مقاله آموزشی",
    title: "ایده مقاله سلامت بینایی",
    color: "purple",
    content:
      "<h3>عنوان مقاله:</h3><p><br></p><h3>کلمات کلیدی:</h3><p><br></p><h3>مقدمه:</h3><p><br></p><h3>بدنه اصلی:</h3><ul><li>نکته ۱</li><li>نکته ۲</li></ul><h3>نتیجه‌گیری:</h3><p><br></p>",
    checklist: ["تحقیق منابع معتبر", "انتخاب تصاویر شاخص"],
  },
  {
    id: "meeting",
    label: "🤝 جلسه تیمی",
    title: "خلاصه جلسه فروش",
    color: "yellow",
    content:
      "<h3>موضوع جلسه:</h3><p><br></p><h3>حاضران:</h3><p><br></p><h3>مصوبات:</h3><ul><li> </li></ul><h3>تکالیف:</h3><ul><li> </li></ul>",
    checklist: ["ارسال صورتجلسه", "پیگیری انجام کارها"],
  },
];

export default function NotesPage() {
  const [items, setItems] = useState<NoteItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [viewMode, setViewMode] = useState<"list" | "grid">("grid");

  const [q, setQ] = useState("");
  const [colorFilter, setColorFilter] = useState("all");
  const [priorityFilter, setPriorityFilter] = useState("all");
  const [tagFilter, setTagFilter] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [deadlineFrom, setDeadlineFrom] = useState("");
  const [deadlineTo, setDeadlineTo] = useState("");

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
  const [formChecklist, setFormChecklist] = useState<ChecklistItem[]>([]);
  const [formChecklistInput, setFormChecklistInput] = useState("");
  const [formFiles, setFormFiles] = useState<{ url: string; name: string }[]>([]);
  const [formTags, setFormTags] = useState<string[]>([]);
  const [formDeadline, setFormDeadline] = useState("");
  const [formTagInput, setFormTagInput] = useState("");
  const [formHtml, setFormHtml] = useState("");
  const [formCss, setFormCss] = useState("");
  const [editorTab, setEditorTab] = useState<"text" | "html" | "css">("text");

  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [showPreview, setShowPreview] = useState(false);

  const autoSaveTimer = useRef<NodeJS.Timeout | null>(null);
  const AUTO_SAVE_KEY = "ezlens_note_draft";

  async function load() {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`/api/notes`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در دریافت یادداشت‌ها");

      let list: NoteItem[] = (data || []).map((item: any) => ({
        ...item,
        checklist: normalizeChecklist(item.checklist),
        tags: Array.isArray(item.tags) ? item.tags : [],
        deadline: item.deadline || "",
        html: item.html || "",
        css: item.css || "",
      }));

      if (q.trim()) {
        const term = q.trim().toLowerCase();
        list = list.filter(
          (note) =>
            note.title.toLowerCase().includes(term) ||
            note.content.toLowerCase().includes(term) ||
            note.tags.some((t) => t.toLowerCase().includes(term))
        );
      }
      if (colorFilter !== "all") list = list.filter((note) => note.color === colorFilter);
      if (priorityFilter !== "all") list = list.filter((note) => note.priority === priorityFilter);
      if (tagFilter !== "all") list = list.filter((note) => note.tags.includes(tagFilter));
      if (dateFrom) {
        const from = new Date(dateFrom).getTime();
        list = list.filter((note) => new Date(note.date).getTime() >= from);
      }
      if (dateTo) {
        const to = new Date(dateTo).getTime() + 86400000;
        list = list.filter((note) => new Date(note.date).getTime() <= to);
      }
      if (deadlineFrom) {
        const from = new Date(deadlineFrom).getTime();
        list = list.filter((note) => note.deadline && new Date(note.deadline).getTime() >= from);
      }
      if (deadlineTo) {
        const to = new Date(deadlineTo).getTime() + 86400000;
        list = list.filter((note) => note.deadline && new Date(note.deadline).getTime() <= to);
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
  }, [page, perPage]);

  useEffect(() => {
    const t = setTimeout(() => {
      setPage(1);
      load();
    }, 350);
    return () => clearTimeout(t);
  }, [q, colorFilter, priorityFilter, tagFilter, dateFrom, dateTo, deadlineFrom, deadlineTo]);

  function openCreate() {
    setEditingNote(null);
    setFormTitle("");
    setFormContent("");
    setFormColor("yellow");
    setFormPriority("low");
    setFormChecklist([]);
    setFormChecklistInput("");
    setFormFiles([]);
    setFormTags([]);
    setFormDeadline("");
    setFormTagInput("");
    setFormHtml("");
    setFormCss("");
    setEditorTab("text");
    setShowPreview(false);
    clearDraft();
    setModalOpen(true);
  }

  function openEdit(note: NoteItem) {
    setEditingNote(note);
    setFormTitle(note.title);
    setFormContent(note.content);
    setFormColor(note.color);
    setFormPriority(note.priority);
    setFormChecklist(Array.isArray(note.checklist) ? note.checklist : []);
    setFormChecklistInput("");
    setFormFiles(note.files || []);
    setFormTags(note.tags || []);
    setFormDeadline(note.deadline || "");
    setFormTagInput("");
    setFormHtml(note.html || "");
    setFormCss(note.css || "");
    setEditorTab("text");
    setShowPreview(false);
    clearDraft();
    setModalOpen(true);
  }

  function applyTemplate(template: (typeof TEMPLATES)[0]) {
    setFormTitle(template.title);
    setFormContent(template.content);
    setFormColor(template.color as keyof typeof COLORS);
    const checklistFromTemplate = Array.isArray(template.checklist)
      ? template.checklist.map((text) => ({
          id: Date.now() + Math.random() * 1000,
          text,
          done: false,
        }))
      : [];
    setFormChecklist(checklistFromTemplate);
  }

  function addChecklistItem() {
    const text = formChecklistInput.trim();
    if (text) {
      setFormChecklist([
        ...formChecklist,
        { id: Date.now() + Math.random() * 1000, text, done: false },
      ]);
      setFormChecklistInput("");
    }
  }

  function removeChecklistItem(id: number) {
    setFormChecklist(formChecklist.filter((item) => item.id !== id));
  }

  function toggleChecklistItem(id: number) {
    setFormChecklist(
      formChecklist.map((item) =>
        item.id === id ? { ...item, done: !item.done } : item
      )
    );
  }

  function addTag() {
    const tag = formTagInput.trim();
    if (tag && !formTags.includes(tag)) {
      setFormTags([...formTags, tag]);
      setFormTagInput("");
    }
  }

  function removeTag(tag: string) {
    setFormTags(formTags.filter((t) => t !== tag));
  }

  function saveDraft() {
    if (!modalOpen || editingNote) return;
    const draft = {
      title: formTitle,
      content: formContent,
      color: formColor,
      priority: formPriority,
      checklist: formChecklist,
      tags: formTags,
      deadline: formDeadline,
      files: formFiles,
      html: formHtml,
      css: formCss,
    };
    try {
      localStorage.setItem(AUTO_SAVE_KEY, JSON.stringify(draft));
    } catch {}
  }

  function loadDraft() {
    if (editingNote) return;
    try {
      const raw = localStorage.getItem(AUTO_SAVE_KEY);
      if (raw) {
        const draft = JSON.parse(raw);
        setFormTitle(draft.title || "");
        setFormContent(draft.content || "");
        setFormColor(draft.color || "yellow");
        setFormPriority(draft.priority || "low");
        setFormChecklist(Array.isArray(draft.checklist) ? draft.checklist : []);
        setFormTags(Array.isArray(draft.tags) ? draft.tags : []);
        setFormDeadline(draft.deadline || "");
        setFormFiles(Array.isArray(draft.files) ? draft.files : []);
        setFormHtml(draft.html || "");
        setFormCss(draft.css || "");
      }
    } catch {}
  }

  function clearDraft() {
    try {
      localStorage.removeItem(AUTO_SAVE_KEY);
    } catch {}
  }

  useEffect(() => {
    if (modalOpen && !editingNote) {
      loadDraft();
    }
    if (modalOpen) {
      autoSaveTimer.current = setInterval(saveDraft, 30000);
    } else {
      if (autoSaveTimer.current) clearInterval(autoSaveTimer.current);
    }
    return () => {
      if (autoSaveTimer.current) clearInterval(autoSaveTimer.current);
    };
  }, [modalOpen, editingNote, formTitle, formContent, formColor, formPriority, formChecklist, formTags, formDeadline, formFiles, formHtml, formCss]);

  async function handleUpload(file: File) {
    setUploading(true);
    setError("");
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await fetch("/api/notes/upload", { method: "POST", body: fd });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "آپلود ناموفق");
      setFormFiles((prev) => [...prev, { url: data.url, name: data.name }]);
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
        tags: formTags,
        deadline: formDeadline,
        html: formHtml,
        css: formCss,
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
      clearDraft();
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
      setItems((prev) => prev.filter((item) => item.id !== deleteItem.id));
      setMessage("یادداشت حذف شد");
      setDeleteItem(null);
    } catch (e: any) {
      setError(e?.message || "خطا در حذف");
    } finally {
      setDeleting(false);
    }
  }

  const allTags = Array.from(new Set(items.flatMap((item) => item.tags || [])));
  const pagedItems = items.slice((page - 1) * perPage, page * perPage);

  return (
    <main className="min-h-screen bg-slate-50 py-6">
      <div className="max-w-7xl mx-auto px-4 space-y-6">
        {/* ===== Header ===== */}
        <div className="flex items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
              <Archive className="w-6 h-6 text-blue-600" />
              دفترچه یادداشت
            </h1>
            <p className="text-sm text-slate-500 mt-1">مدیریت یادداشت‌ها، چک‌لیست‌ها و کدهای اختصاصی</p>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex border rounded-lg overflow-hidden bg-white">
              <button
                onClick={() => setViewMode("list")}
                className={`px-3 py-2 text-xs font-medium transition flex items-center gap-1 ${
                  viewMode === "list" ? "bg-slate-100 text-slate-800" : "text-slate-500"
                }`}
              >
                <List className="w-3.5 h-3.5" /> لیستی
              </button>
              <button
                onClick={() => setViewMode("grid")}
                className={`px-3 py-2 text-xs font-medium transition flex items-center gap-1 ${
                  viewMode === "grid" ? "bg-slate-100 text-slate-800" : "text-slate-500"
                }`}
              >
                <Grid3x3 className="w-3.5 h-3.5" /> دو ستونه
              </button>
            </div>
            <button
              onClick={openCreate}
              className="px-4 py-2.5 rounded-xl text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 transition shadow-sm flex items-center gap-2"
            >
              <Plus className="w-4 h-4" /> یادداشت جدید
            </button>
          </div>
        </div>

        {error && (
          <div className="rounded-xl px-4 py-3 text-sm text-white bg-red-500 shadow-sm flex items-center gap-2">
            <AlertCircle className="w-4 h-4" /> {error}
          </div>
        )}
        {message && (
          <div className="rounded-xl px-4 py-3 text-sm text-white bg-emerald-500 shadow-sm flex items-center gap-2">
            <CheckCircle className="w-4 h-4" /> {message}
          </div>
        )}

        {/* ===== Filters ===== */}
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
              onChange={(e) => {
                setColorFilter(e.target.value);
                setPage(1);
              }}
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
            >
              <option value="all">همه رنگ‌ها</option>
              {Object.entries(COLORS).map(([key, val]) => (
                <option key={key} value={key}>
                  {val.label}
                </option>
              ))}
            </select>
            <select
              value={priorityFilter}
              onChange={(e) => {
                setPriorityFilter(e.target.value);
                setPage(1);
              }}
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
            >
              <option value="all">همه اولویت‌ها</option>
              {Object.entries(PRIORITIES).map(([key, val]) => (
                <option key={key} value={key}>
                  {val.label}
                </option>
              ))}
            </select>
            <select
              value={tagFilter}
              onChange={(e) => {
                setTagFilter(e.target.value);
                setPage(1);
              }}
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
            >
              <option value="all">همه برچسب‌ها</option>
              {allTags.map((tag) => (
                <option key={tag} value={tag}>
                  #{tag}
                </option>
              ))}
            </select>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div className="grid grid-cols-2 gap-2">
              <DatePicker
                value={dateFrom}
                onChange={(d) => setDateFrom(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="از تاریخ ایجاد"
              />
              <DatePicker
                value={dateTo}
                onChange={(d) => setDateTo(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="تا تاریخ ایجاد"
              />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <DatePicker
                value={deadlineFrom}
                onChange={(d) => setDeadlineFrom(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="از تاریخ سررسید"
              />
              <DatePicker
                value={deadlineTo}
                onChange={(d) => setDeadlineTo(d ? d.toDate().toISOString() : "")}
                calendar={persian}
                locale={persian_fa}
                inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                containerClassName="w-full"
                placeholder="تا تاریخ سررسید"
              />
            </div>
          </div>
          <div className="flex items-center justify-between pt-3 border-t text-sm text-slate-500">
            <div className="flex items-center gap-2">
              <span>تعداد در صفحه:</span>
              <select
                value={perPage}
                onChange={(e) => {
                  setPerPage(Number(e.target.value));
                  setPage(1);
                }}
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

        {loading && (
          <div className="flex justify-center py-10">
            <RefreshCw className="w-6 h-6 text-slate-400 animate-spin" />
          </div>
        )}
        {!loading && pagedItems.length === 0 && !error && (
          <div className="bg-white border border-slate-200 rounded-2xl p-10 text-center text-slate-400">
            یادداشتی یافت نشد
          </div>
        )}

        {/* ===== List View ===== */}
        {!loading && viewMode === "list" && pagedItems.length > 0 && (
          <div className="space-y-3">
            {pagedItems.map((note) => {
              const colorMeta = COLORS[note.color as keyof typeof COLORS] || COLORS.yellow;
              const priorityMeta = PRIORITIES[note.priority as keyof typeof PRIORITIES] || PRIORITIES.low;
              const hasDeadline = note.deadline && new Date(note.deadline) > new Date();
              const isOverdue = note.deadline && new Date(note.deadline) < new Date();

              return (
                <div
                  key={note.id}
                  className="bg-white border border-slate-200 rounded-2xl p-4 hover:shadow-md transition"
                  style={{ borderRight: `4px solid ${colorMeta.border}` }}
                >
                  <div className="flex flex-col md:flex-row md:items-start gap-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <h3 className="font-bold text-slate-900">{note.title}</h3>
                        <span className={`text-[10px] px-2 py-0.5 rounded-full ${priorityMeta.color}`}>
                          {priorityMeta.label}
                        </span>
                        {note.pinned && <Pin className="w-3 h-3 text-blue-600" />}
                        {hasDeadline && <Clock className="w-3 h-3 text-amber-500" />}
                        {isOverdue && <AlertCircle className="w-3 h-3 text-red-500" />}
                      </div>
                      {note.tags && note.tags.length > 0 && (
                        <div className="flex gap-1 mt-1 flex-wrap">
                          {note.tags.map((tag) => (
                            <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-blue-50 text-blue-600">
                              #{tag}
                            </span>
                          ))}
                        </div>
                      )}
                      <div
                        className="mt-2 text-sm text-slate-600 line-clamp-2 quill-content"
                        dangerouslySetInnerHTML={{ __html: note.content }}
                      />
                      {note.checklist && note.checklist.length > 0 && (
                        <div className="mt-3 space-y-1">
                          {note.checklist.slice(0, 3).map((item) => (
                            <div key={item.id} className="flex items-center gap-2 text-xs">
                              <span
                                className={`w-3 h-3 rounded-full border ${
                                  item.done ? "bg-green-500 border-green-500" : "border-slate-300"
                                }`}
                              />
                              <span className={item.done ? "line-through text-slate-400" : "text-slate-600"}>
                                {item.text}
                              </span>
                            </div>
                          ))}
                          {note.checklist.length > 3 && (
                            <div className="text-xs text-slate-400">+ {note.checklist.length - 3} مورد دیگر</div>
                          )}
                        </div>
                      )}
                      {(note.html || note.css) && (
                        <div className="mt-1 flex gap-2 text-[10px] text-slate-400">
                          {note.html && (
                            <span className="flex items-center gap-1">
                              <Code className="w-3 h-3" /> HTML
                            </span>
                          )}
                          {note.css && (
                            <span className="flex items-center gap-1">
                              <Palette className="w-3 h-3" /> CSS
                            </span>
                          )}
                        </div>
                      )}
                      <div className="mt-2 flex flex-wrap gap-3 text-xs text-slate-400">
                        <span>✍️ {note.author_name || "نامشخص"}</span>
                        <span>🕒 {toFaDate(note.modified || note.date)}</span>
                        {note.deadline && (
                          <span className={isOverdue ? "text-red-500" : "text-slate-400"}>
                            📅 سررسید: {toFaDate(note.deadline)}
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="flex gap-2 md:flex-col md:w-32 shrink-0">
                      <button
                        onClick={() => setViewItem(note)}
                        className="flex-1 py-1.5 rounded-lg text-xs bg-blue-50 text-blue-600 hover:bg-blue-100 transition flex items-center justify-center gap-1"
                      >
                        <Eye className="w-3 h-3" /> مشاهده
                      </button>
                      <button
                        onClick={() => openEdit(note)}
                        className="flex-1 py-1.5 rounded-lg text-xs bg-amber-50 text-amber-600 hover:bg-amber-100 transition flex items-center justify-center gap-1"
                      >
                        <Edit className="w-3 h-3" /> ویرایش
                      </button>
                      <button
                        onClick={() => setDeleteItem(note)}
                        className="flex-1 py-1.5 rounded-lg text-xs bg-red-50 text-red-600 hover:bg-red-100 transition flex items-center justify-center gap-1"
                      >
                        <Trash2 className="w-3 h-3" /> حذف
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* ===== Grid View ===== */}
        {!loading && viewMode === "grid" && pagedItems.length > 0 && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {pagedItems.map((note) => {
              const colorMeta = COLORS[note.color as keyof typeof COLORS] || COLORS.yellow;
              const priorityMeta = PRIORITIES[note.priority as keyof typeof PRIORITIES] || PRIORITIES.low;
              const hasDeadline = note.deadline && new Date(note.deadline) > new Date();
              const isOverdue = note.deadline && new Date(note.deadline) < new Date();

              return (
                <div
                  key={note.id}
                  className="bg-white border border-slate-200 rounded-2xl overflow-hidden hover:shadow-md transition"
                  style={{ borderTop: `4px solid ${colorMeta.border}` }}
                >
                  <div className="p-4">
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="font-bold text-slate-900 line-clamp-1">{note.title}</h3>
                      <span className={`text-[10px] px-2 py-0.5 rounded-full ${priorityMeta.color}`}>
                        {priorityMeta.label}
                      </span>
                    </div>
                    {note.tags && note.tags.length > 0 && (
                      <div className="flex gap-1 mt-1 flex-wrap">
                        {note.tags.slice(0, 3).map((tag) => (
                          <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-blue-50 text-blue-600">
                            #{tag}
                          </span>
                        ))}
                      </div>
                    )}
                    <div
                      className="mt-2 text-sm text-slate-600 line-clamp-3 quill-content"
                      dangerouslySetInnerHTML={{ __html: note.content }}
                    />
                    {note.checklist && note.checklist.length > 0 && (
                      <div className="mt-3 space-y-1">
                        {note.checklist.slice(0, 3).map((item) => (
                          <div key={item.id} className="flex items-center gap-2 text-xs">
                            <span
                              className={`w-3 h-3 rounded-full border ${
                                item.done ? "bg-green-500 border-green-500" : "border-slate-300"
                              }`}
                            />
                            <span className={item.done ? "line-through text-slate-400" : "text-slate-600"}>
                              {item.text}
                            </span>
                          </div>
                        ))}
                        {note.checklist.length > 3 && (
                          <div className="text-xs text-slate-400">+ {note.checklist.length - 3} مورد دیگر</div>
                        )}
                      </div>
                    )}
                    {(note.html || note.css) && (
                      <div className="mt-1 flex gap-2 text-[10px] text-slate-400">
                        {note.html && <span className="flex items-center gap-1"><Code className="w-3 h-3" /> HTML</span>}
                        {note.css && <span className="flex items-center gap-1"><Palette className="w-3 h-3" /> CSS</span>}
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
                    {note.deadline && (
                      <div className={`mt-1 text-[10px] ${isOverdue ? "text-red-500" : "text-slate-400"}`}>
                        📅 سررسید: {toFaDate(note.deadline)}
                      </div>
                    )}
                  </div>
                  <div className="flex gap-1 p-3 pt-0">
                    <button
                      onClick={() => setViewItem(note)}
                      className="flex-1 py-1.5 rounded-lg text-xs bg-blue-50 text-blue-600 hover:bg-blue-100 transition flex items-center justify-center gap-1"
                    >
                      <Eye className="w-3 h-3" /> مشاهده
                    </button>
                    <button
                      onClick={() => openEdit(note)}
                      className="flex-1 py-1.5 rounded-lg text-xs bg-amber-50 text-amber-600 hover:bg-amber-100 transition flex items-center justify-center gap-1"
                    >
                      <Edit className="w-3 h-3" /> ویرایش
                    </button>
                    <button
                      onClick={() => setDeleteItem(note)}
                      className="flex-1 py-1.5 rounded-lg text-xs bg-red-50 text-red-600 hover:bg-red-100 transition flex items-center justify-center gap-1"
                    >
                      <Trash2 className="w-3 h-3" /> حذف
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <Pagination page={page} totalPages={totalPages} onChange={setPage} />
      </div>

      {/* ================================================================ */}
      {/* ===== Modal (Create / Edit) ===== */}
      {/* ================================================================ */}
      {modalOpen && (
        <div
          className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4"
          onClick={() => {
            if (!saving) setModalOpen(false);
          }}
        >
          <div
            className="bg-white w-full max-w-4xl max-h-[92vh] rounded-2xl overflow-hidden flex flex-col shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between p-4 border-b shrink-0">
              <h3 className="font-bold text-lg">{editingNote ? "✏️ ویرایش یادداشت" : "📝 یادداشت جدید"}</h3>
              <button
                onClick={() => setModalOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-full hover:bg-slate-100 transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-5">
              {/* Templates */}
              {!editingNote && (
                <div className="space-y-2">
                  <label className="block text-sm font-medium text-slate-700">🚀 شروع سریع با قالب</label>
                  <div className="grid grid-cols-2 gap-2">
                    {TEMPLATES.map((template) => {
                      const colorMap: Record<string, string> = {
                        blue: "bg-blue-50 border-blue-200 hover:bg-blue-100 text-blue-800",
                        green: "bg-green-50 border-green-200 hover:bg-green-100 text-green-800",
                        purple: "bg-purple-50 border-purple-200 hover:bg-purple-100 text-purple-800",
                        yellow: "bg-yellow-50 border-yellow-200 hover:bg-yellow-100 text-yellow-800",
                      };
                      return (
                        <button
                          key={template.id}
                          onClick={() => applyTemplate(template)}
                          className={`px-4 py-3 rounded-xl text-right text-xs font-medium border-2 transition ${colorMap[template.color] || "bg-slate-50 border-slate-200"}`}
                        >
                          <div className="text-lg">{template.label}</div>
                          <div className="text-slate-600 text-[10px]">{template.title}</div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">عنوان <span className="text-red-500">*</span></label>
                <input
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  placeholder="مثلاً پیگیری سفارش..."
                  className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Content Editor */}
              <div>
                <div className="flex items-center justify-between mb-1">
                  <label className="block text-sm font-medium text-slate-700">محتوا</label>
                  <div className="flex gap-1 border rounded-lg overflow-hidden">
                    <button
                      onClick={() => setEditorTab("text")}
                      className={`px-3 py-1 text-xs font-medium transition ${
                        editorTab === "text" ? "bg-blue-50 text-blue-600" : "text-slate-500 hover:bg-slate-50"
                      }`}
                    >
                      <FileText className="w-3 h-3 inline" /> نوشتار
                    </button>
                    <button
                      onClick={() => setEditorTab("html")}
                      className={`px-3 py-1 text-xs font-medium transition ${
                        editorTab === "html" ? "bg-blue-50 text-blue-600" : "text-slate-500 hover:bg-slate-50"
                      }`}
                    >
                      <Code className="w-3 h-3 inline" /> HTML
                    </button>
                    <button
                      onClick={() => setEditorTab("css")}
                      className={`px-3 py-1 text-xs font-medium transition ${
                        editorTab === "css" ? "bg-blue-50 text-blue-600" : "text-slate-500 hover:bg-slate-50"
                      }`}
                    >
                      <Palette className="w-3 h-3 inline" /> CSS
                    </button>
                  </div>
                </div>

                {editorTab === "text" && (
                  <div>
                    <ReactQuill
                      theme="snow"
                      value={formContent}
                      onChange={setFormContent}
                      modules={quillModules}
                      formats={quillFormats}
                      placeholder="متن یادداشت..."
                      className="bg-white rounded-xl"
                      style={{ height: "200px", marginBottom: "48px" }}
                    />
                    <div className="text-xs text-slate-400 mt-1">💡 از نوار ابزار بالا برای فرمت‌دهی استفاده کنید.</div>
                  </div>
                )}

                {editorTab === "html" && (
                  <div>
                    <textarea
                      value={formHtml}
                      onChange={(e) => setFormHtml(e.target.value)}
                      rows={4}
                      placeholder="<!-- کد HTML اختصاصی یادداشت -->"
                      className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 font-mono bg-slate-50"
                    />
                  </div>
                )}

                {editorTab === "css" && (
                  <div>
                    <textarea
                      value={formCss}
                      onChange={(e) => setFormCss(e.target.value)}
                      rows={4}
                      placeholder="/* استایل‌های اختصاصی یادداشت */"
                      className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 font-mono bg-slate-50"
                    />
                  </div>
                )}
              </div>

              {/* Color + Priority + Deadline */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">رنگ</label>
                  <div className="flex gap-2">
                    {Object.entries(COLORS).map(([key, val]) => (
                      <button
                        key={key}
                        onClick={() => setFormColor(key)}
                        className={`w-8 h-8 rounded-full border-2 ${
                          formColor === key ? "border-blue-500" : "border-transparent"
                        }`}
                        style={{ background: val.border }}
                        title={val.label}
                      />
                    ))}
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">اولویت</label>
                  <select
                    value={formPriority}
                    onChange={(e) => setFormPriority(e.target.value)}
                    className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
                  >
                    <option value="low">کم</option>
                    <option value="medium">متوسط</option>
                    <option value="high">بحرانی</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">تاریخ سررسید</label>
                  <DatePicker
                    value={formDeadline}
                    onChange={(d) => setFormDeadline(d ? d.toDate().toISOString() : "")}
                    calendar={persian}
                    locale={persian_fa}
                    inputClass="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none"
                    containerClassName="w-full"
                    placeholder="انتخاب تاریخ"
                  />
                </div>
              </div>

              {/* Tags */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">برچسب‌ها</label>
                <div className="flex gap-2">
                  <input
                    value={formTagInput}
                    onChange={(e) => setFormTagInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        addTag();
                      }
                    }}
                    placeholder="برچسب جدید (Enter)"
                    className="flex-1 border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button
                    onClick={addTag}
                    className="px-4 py-2.5 rounded-xl text-sm text-white bg-blue-600 hover:bg-blue-700 transition"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
                <div className="flex flex-wrap gap-1 mt-2">
                  {formTags.map((tag) => (
                    <span
                      key={tag}
                      className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded-full bg-blue-50 text-blue-600"
                    >
                      #{tag}
                      <button onClick={() => removeTag(tag)} className="hover:text-red-500 transition">
                        <X className="w-3 h-3" />
                      </button>
                    </span>
                  ))}
                </div>
              </div>

              {/* Checklist with Checkbox */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="block text-sm font-medium text-slate-700">چک‌لیست</label>
                </div>
                <div className="space-y-2 max-h-40 overflow-y-auto">
                  {formChecklist.map((item) => (
                    <div key={item.id} className="flex items-center gap-2">
                      <button
                        onClick={() => toggleChecklistItem(item.id)}
                        className="shrink-0 focus:outline-none"
                      >
                        {item.done ? (
                          <CheckSquare className="w-4 h-4 text-emerald-500" />
                        ) : (
                          <Square className="w-4 h-4 text-slate-400" />
                        )}
                      </button>
                      <span
                        className={`text-sm flex-1 ${
                          item.done ? "line-through text-slate-400" : "text-slate-700"
                        }`}
                      >
                        {item.text}
                      </span>
                      <button
                        onClick={() => removeChecklistItem(item.id)}
                        className="text-red-500 hover:text-red-700 transition"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
                <div className="flex gap-2 mt-2">
                  <input
                    value={formChecklistInput}
                    onChange={(e) => setFormChecklistInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        addChecklistItem();
                      }
                    }}
                    placeholder="مورد جدید (Enter)"
                    className="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button
                    onClick={addChecklistItem}
                    className="px-4 py-2 rounded-lg text-sm text-white bg-blue-600 hover:bg-blue-700 transition"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Files */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">فایل‌های پیوست</label>
                <div className="space-y-2">
                  {formFiles.map((file, idx) => (
                    <div key={idx} className="flex items-center gap-2 bg-slate-50 p-2 rounded-lg">
                      <span className="text-sm">📎</span>
                      <span className="flex-1 text-sm text-slate-600 truncate">{file.name}</span>
                      <a href={file.url} target="_blank" rel="noreferrer" className="text-xs text-blue-600 hover:underline">
                        مشاهده
                      </a>
                      <button
                        onClick={() => setFormFiles((prev) => prev.filter((_, i) => i !== idx))}
                        className="text-red-500 hover:text-red-700 transition"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
                <label className="block mt-2">
                  <span className="text-sm text-blue-600 cursor-pointer hover:underline">
                    {uploading ? "در حال آپلود..." : "+ آپلود فایل"}
                  </span>
                  <input
                    type="file"
                    className="hidden"
                    disabled={uploading}
                    onChange={(e) => {
                      if (e.target.files?.[0]) handleUpload(e.target.files[0]);
                      e.currentTarget.value = "";
                    }}
                  />
                </label>
              </div>

              {/* Preview */}
              <div>
                <button
                  onClick={() => setShowPreview(!showPreview)}
                  className="text-sm text-blue-600 hover:underline flex items-center gap-1"
                >
                  {showPreview ? "🙈 مخفی کردن پیش‌نمایش" : "👁️ نمایش پیش‌نمایش"}
                </button>
                {showPreview && (
                  <div className="mt-2 p-4 border border-slate-200 rounded-xl bg-slate-50">
                    <h4 className="font-bold text-slate-800">{formTitle || "عنوان"}</h4>
                    <div
                      className="mt-1 text-sm text-slate-700"
                      dangerouslySetInnerHTML={{ __html: formContent }}
                    />
                    {formChecklist.length > 0 && (
                      <ul className="mt-2 space-y-1">
                        {formChecklist.map((item) => (
                          <li key={item.id} className="flex items-center gap-2 text-sm">
                            <span>{item.done ? "✅" : "⬜"}</span>
                            <span className={item.done ? "line-through text-slate-400" : ""}>
                              {item.text}
                            </span>
                          </li>
                        ))}
                      </ul>
                    )}
                    {formHtml && (
                      <div className="mt-3 border-t pt-3 border-slate-200">
                        <div className="text-xs font-medium text-slate-500 mb-1">HTML:</div>
                        <div
                          className="text-sm text-slate-700 p-3 bg-white rounded-lg border border-slate-200"
                          dangerouslySetInnerHTML={{ __html: formHtml }}
                        />
                      </div>
                    )}
                    {formCss && (
                      <div className="mt-3 border-t pt-3 border-slate-200">
                        <div className="text-xs font-medium text-slate-500 mb-1">CSS:</div>
                        <div
                          className="text-sm text-slate-700 p-3 bg-white rounded-lg border border-slate-200"
                          dangerouslySetInnerHTML={{ __html: `<style>${formCss}</style>` }}
                        />
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            <div className="flex gap-2 p-4 border-t shrink-0 bg-slate-50">
              <button
                onClick={saveNote}
                disabled={saving}
                className="flex-1 py-2.5 rounded-xl text-sm text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition flex items-center justify-center gap-2"
              >
                {saving ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" /> در حال ذخیره...
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4" /> ذخیره
                  </>
                )}
              </button>
              <button
                onClick={() => setModalOpen(false)}
                className="px-4 py-2.5 rounded-xl text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 transition"
              >
                انصراف
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ===== View Modal ===== */}
      {viewItem && (
        <div
          className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4"
          onClick={() => setViewItem(null)}
        >
          <div
            className="bg-white w-full max-w-2xl rounded-2xl p-6 space-y-4 max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg">{viewItem.title}</h3>
              <button onClick={() => setViewItem(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <span>✍️ {viewItem.author_name || "نامشخص"}</span>
              <span>🕒 {toFaDate(viewItem.modified || viewItem.date)}</span>
            </div>
            {viewItem.tags && viewItem.tags.length > 0 && (
              <div className="flex gap-1 flex-wrap">
                {viewItem.tags.map((tag) => (
                  <span key={tag} className="text-xs px-2 py-0.5 rounded-full bg-blue-50 text-blue-600">#{tag}</span>
                ))}
              </div>
            )}
            {viewItem.content && (
              <div
                className="text-sm text-slate-700"
                dangerouslySetInnerHTML={{ __html: viewItem.content }}
              />
            )}
            {viewItem.html && (
              <div className="border rounded-xl p-4 bg-slate-50 border-slate-200">
                <div className="text-xs font-medium text-slate-500 mb-2 flex items-center gap-1">
                  <Code className="w-3 h-3" /> HTML
                </div>
                <div
                  className="text-sm text-slate-700"
                  dangerouslySetInnerHTML={{ __html: viewItem.html }}
                />
              </div>
            )}
            {viewItem.css && (
              <div className="border rounded-xl p-4 bg-slate-50 border-slate-200">
                <div className="text-xs font-medium text-slate-500 mb-2 flex items-center gap-1">
                  <Palette className="w-3 h-3" /> CSS
                </div>
                <div
                  className="text-sm text-slate-700"
                  dangerouslySetInnerHTML={{ __html: `<style>${viewItem.css}</style>` }}
                />
              </div>
            )}
            {viewItem.checklist && viewItem.checklist.length > 0 && (
              <div className="bg-slate-50 rounded-xl p-4 space-y-2">
                {viewItem.checklist.map((item) => (
                  <div key={item.id} className="flex items-center gap-2 text-sm">
                    <span
                      className={`w-4 h-4 rounded-full border ${
                        item.done ? "bg-green-500 border-green-500" : "border-slate-300"
                      }`}
                    />
                    <span className={item.done ? "line-through text-slate-400" : "text-slate-700"}>
                      {item.text}
                    </span>
                  </div>
                ))}
              </div>
            )}
            {viewItem.files && viewItem.files.length > 0 && (
              <div className="space-y-2">
                {viewItem.files.map((file, idx) => (
                  <a
                    key={idx}
                    href={file.url}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center gap-2 bg-slate-50 p-2 rounded-lg hover:bg-slate-100 transition"
                  >
                    <span className="text-sm">📎</span>
                    <span className="flex-1 text-sm text-slate-600 truncate">{file.name}</span>
                    <span className="text-xs text-blue-600">مشاهده</span>
                  </a>
                ))}
              </div>
            )}
            {viewItem.deadline && (
              <div className="text-sm text-slate-500">📅 سررسید: {toFaDate(viewItem.deadline)}</div>
            )}
          </div>
        </div>
      )}

      {/* ===== Delete Modal ===== */}
      {deleteItem && (
        <div className="fixed inset-0 z-[60] bg-black/60 flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-sm rounded-2xl p-6 space-y-4 text-center shadow-2xl">
            <div className="text-4xl">🗑️</div>
            <h3 className="font-bold text-lg">حذف یادداشت</h3>
            <p className="text-sm text-slate-500">آیا از حذف «{deleteItem.title}» مطمئن هستید؟</p>
            <div className="flex gap-2 pt-2">
              <button
                onClick={confirmDelete}
                disabled={deleting}
                className="flex-1 py-2.5 rounded-xl text-sm text-white bg-red-600 hover:bg-red-700 disabled:opacity-50 transition"
              >
                {deleting ? "در حال حذف..." : "بله، حذف کن"}
              </button>
              <button
                onClick={() => setDeleteItem(null)}
                disabled={deleting}
                className="flex-1 py-2.5 rounded-xl text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 transition"
              >
                انصراف
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}