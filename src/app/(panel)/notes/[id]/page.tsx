"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import dynamic from "next/dynamic";
import "react-quill-new/dist/quill.snow.css";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

import {
  Save,
  RefreshCw,
  X,
  Plus,
  Code,
  Palette,
  FileText,
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

const COLORS = {
  yellow: { label: "زرد", bg: "#fef9c3", border: "#fde047" },
  blue: { label: "آبی", bg: "#dbeafe", border: "#60a5fa" },
  green: { label: "سبز", bg: "#dcfce7", border: "#4ade80" },
  red: { label: "قرمز", bg: "#fee2e2", border: "#f87171" },
  purple: { label: "بنفش", bg: "#f3e8ff", border: "#c084fc" },
} as const;

type ChecklistItem = {
  id: number;
  text: string;
  done: boolean;
};

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

export default function EditNotePage() {
  const params = useParams();
  const router = useRouter();
  const id = String(params.id || "");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [showPreview, setShowPreview] = useState(false);
  const [editorTab, setEditorTab] = useState<"text" | "html" | "css">("text");

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [color, setColor] = useState("yellow");
  const [priority, setPriority] = useState("low");
  const [checklist, setChecklist] = useState<ChecklistItem[]>([]);
  const [checklistInput, setChecklistInput] = useState("");
  const [files, setFiles] = useState<{ url: string; name: string }[]>([]);
  const [tags, setTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState("");
  const [deadline, setDeadline] = useState("");
  const [html, setHtml] = useState("");
  const [css, setCss] = useState("");

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
        setChecklist(normalizeChecklist(data.checklist));
        setFiles(data.files || []);
        setTags(Array.isArray(data.tags) ? data.tags : []);
        setDeadline(data.deadline || "");
        setHtml(data.html || "");
        setCss(data.css || "");
      } catch (e: any) {
        setError(e?.message || "خطای ناشناخته");
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [id]);

  function addTag() {
    const tag = tagInput.trim();
    if (tag && !tags.includes(tag)) {
      setTags([...tags, tag]);
      setTagInput("");
    }
  }
  function removeTag(tag: string) {
    setTags(tags.filter((t) => t !== tag));
  }

  function addChecklistItem() {
    const text = checklistInput.trim();
    if (text) {
      setChecklist([
        ...checklist,
        { id: Date.now() + Math.random() * 1000, text, done: false },
      ]);
      setChecklistInput("");
    }
  }

  function removeChecklistItem(id: number) {
    setChecklist(checklist.filter((item) => item.id !== id));
  }

  function toggleChecklistItem(id: number) {
    setChecklist(
      checklist.map((item) =>
        item.id === id ? { ...item, done: !item.done } : item
      )
    );
  }

  async function save() {
    if (!title.trim()) {
      setError("عنوان الزامی است");
      return;
    }
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const payload = {
        title,
        content,
        color,
        priority,
        checklist,
        files,
        tags,
        deadline,
        html,
        css,
      };

      const res = await fetch(`/api/notes/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
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

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <RefreshCw className="w-6 h-6 text-slate-400 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 py-10">
      <main className="max-w-4xl mx-auto p-6 space-y-6 pb-12">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">✏️ ویرایش یادداشت</h1>
          <Link href="/notes" className="text-sm text-slate-600 hover:text-slate-900">← بازگشت</Link>
        </div>

        {error && <div className="bg-red-50 text-red-600 rounded-xl p-3 text-sm">{error}</div>}
        {message && <div className="bg-emerald-50 text-emerald-600 rounded-xl p-3 text-sm">{message}</div>}

        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-5">
          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">عنوان *</label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
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
                  value={content}
                  onChange={setContent}
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
                  value={html}
                  onChange={(e) => setHtml(e.target.value)}
                  rows={5}
                  placeholder="<!-- کد HTML اختصاصی -->"
                  className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500 font-mono bg-slate-50"
                />
              </div>
            )}

            {editorTab === "css" && (
              <div>
                <textarea
                  value={css}
                  onChange={(e) => setCss(e.target.value)}
                  rows={5}
                  placeholder="/* استایل‌های اختصاصی */"
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
                    onClick={() => setColor(key)}
                    className={`w-8 h-8 rounded-full border-2 ${
                      color === key ? "border-blue-500" : "border-transparent"
                    }`}
                    style={{ background: val.border }}
                  />
                ))}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">اولویت</label>
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
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
                value={deadline}
                onChange={(d) => setDeadline(d ? d.toDate().toISOString() : "")}
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
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
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
              {tags.map((tag) => (
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
            <div className="space-y-2 max-h-48 overflow-y-auto">
              {checklist.map((item) => (
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
                value={checklistInput}
                onChange={(e) => setChecklistInput(e.target.value)}
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
            <label className="block text-sm font-medium text-slate-700 mb-2">فایل‌ها</label>
            <div className="space-y-2">
              {files.map((file, idx) => (
                <div key={idx} className="flex items-center gap-2 bg-slate-50 p-2 rounded-lg">
                  <span className="text-sm">📎</span>
                  <span className="flex-1 text-sm truncate">{file.name}</span>
                  <a href={file.url} target="_blank" rel="noreferrer" className="text-xs text-blue-600">
                    مشاهده
                  </a>
                  <button
                    onClick={() => setFiles((prev) => prev.filter((_, i) => i !== idx))}
                    className="text-red-500"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>
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
                <h4 className="font-bold text-slate-800">{title || "عنوان"}</h4>
                <div
                  className="mt-1 text-sm text-slate-700"
                  dangerouslySetInnerHTML={{ __html: formatContent(content) }}
                />
                {checklist.length > 0 && (
                  <ul className="mt-2 space-y-1">
                    {checklist.map((item) => (
                      <li key={item.id} className="flex items-center gap-2 text-sm">
                        <span>{item.done ? "✅" : "⬜"}</span>
                        <span className={item.done ? "line-through text-slate-400" : ""}>
                          {item.text}
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
                {html && (
                  <div className="mt-3 border-t pt-3 border-slate-200">
                    <div className="text-xs font-medium text-slate-500 mb-1">HTML:</div>
                    <div
                      className="text-sm text-slate-700 p-3 bg-white rounded-lg border border-slate-200"
                      dangerouslySetInnerHTML={{ __html: html }}
                    />
                  </div>
                )}
                {css && (
                  <div className="mt-3 border-t pt-3 border-slate-200">
                    <div className="text-xs font-medium text-slate-500 mb-1">CSS:</div>
                    <div
                      className="text-sm text-slate-700 p-3 bg-white rounded-lg border border-slate-200"
                      dangerouslySetInnerHTML={{ __html: `<style>${css}</style>` }}
                    />
                  </div>
                )}
              </div>
            )}
          </div>

          <button
            onClick={save}
            disabled={saving}
            className="w-full py-3 rounded-xl text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition flex items-center justify-center gap-2"
          >
            {saving ? (
              <>
                <RefreshCw className="w-4 h-4 animate-spin" /> در حال ذخیره...
              </>
            ) : (
              <>
                <Save className="w-4 h-4" /> ذخیره تغییرات
              </>
            )}
          </button>
        </div>
      </main>
    </div>
  );
}