"use client";

import { useEffect, useMemo, useState, useRef } from "react";
import Pagination from "@/components/ui/Pagination";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

type MediaItem = {
  id: number;
  title: string;
  alt: string;
  caption: string;
  description: string;
  mime: string;
  type: "image" | "video" | "audio" | "file";
  url: string;
  link: string;
  date: string;
  modified: string;
  size: string;
  bytes: number;
  width: number | null;
  height: number | null;
};

function toFaDate(iso: string) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleDateString("fa-IR", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
  } catch {
    return iso;
  }
}

function toFaDateTime(iso: string) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleString("fa-IR", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

export default function MediaPage() {
  const [items, setItems] = useState<MediaItem[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [q, setQ] = useState("");
  const [type, setType] = useState("");
  const [sizeFilter, setSizeFilter] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // حالت نمایش: لیستی یا جدولی (دو ستونه)
  const [viewMode, setViewMode] = useState<"list" | "grid">("list");

  // آپلود
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [uploadTitle, setUploadTitle] = useState("");
  const fileInputRef = useRef<HTMLInputElement>(null);

  // مشاهده/ویرایش
  const [viewItem, setViewItem] = useState<MediaItem | null>(null);
  const [editItem, setEditItem] = useState<MediaItem | null>(null);
  const [editTitle, setEditTitle] = useState("");
  const [editAlt, setEditAlt] = useState("");
  const [saving, setSaving] = useState(false);

  // مودال تایید حذف
  const [deleteItem, setDeleteItem] = useState<MediaItem | null>(null);
  const [deleting, setDeleting] = useState(false);

  // ⬇️ تابع لود اطلاعات (AJAX)
  async function load() {
    setLoading(true);
    setError("");
    try {
      const params = new URLSearchParams({
        page: String(page),
        per_page: "24",
      });
      if (q.trim()) params.set("search", q.trim());
      if (type) params.set("media_type", type);

      // برای فیلترهای سایز و تاریخ، سرور فیلتر مستقیم ندارد، پس همه را می‌گیریم و فیلتر می‌کنیم
      const res = await fetch(`/api/media?${params.toString()}`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در دریافت رسانه");

      let fetchedItems = data.items || [];
      if (sizeFilter !== "all") {
        fetchedItems = fetchedItems.filter((item: MediaItem) => {
          if (sizeFilter === "small") return item.bytes < 100 * 1024;
          if (sizeFilter === "medium") return item.bytes >= 100 * 1024 && item.bytes < 1 * 1024 * 1024;
          if (sizeFilter === "large") return item.bytes >= 1 * 1024 * 1024;
          return true;
        });
      }
      if (dateFrom) {
        const from = new Date(dateFrom).getTime();
        fetchedItems = fetchedItems.filter((item: MediaItem) => new Date(item.date).getTime() >= from);
      }
      if (dateTo) {
        const to = new Date(dateTo).getTime() + 86400000;
        fetchedItems = fetchedItems.filter((item: MediaItem) => new Date(item.date).getTime() <= to);
      }
      setItems(fetchedItems);
      setTotal(data.total || 0);
      setTotalPages(data.totalPages || 1);
    } catch (e: any) {
      setError(e?.message || "خطای ناشناخته");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }

  // ⬇️ با تغییر صفحه یا نوع یا سایز یا تاریخ، لیست ایجکسی آپدیت شود
  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, type, sizeFilter, dateFrom, dateTo]);

  // ⬇️ جستجو با Debounce (با تایپ، لیست ایجکسی آپدیت شود)
  useEffect(() => {
    const t = setTimeout(() => {
      setPage(1);
      load();
    }, 350);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  // کپی لینک
  async function copyLink(url: string) {
    try {
      await navigator.clipboard.writeText(url);
      setMessage("لینک کپی شد");
    } catch {
      setMessage("کپی لینک ناموفق بود");
    }
  }

  // آپلود دسته‌ای (AJAX - بدون رفرش)
  async function uploadFiles(files: FileList | null) {
    if (!files?.length) return;
    setUploading(true);
    setProgress(5);
    setError("");
    setMessage("");

    try {
      const list = Array.from(files);
      let done = 0;

      for (const file of list) {
        const fd = new FormData();
        fd.append("file", file);
        if (uploadTitle.trim()) fd.append("title", uploadTitle.trim());

        const res = await fetch("/api/media", { method: "POST", body: fd });
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || `آپلود ${file.name} ناموفق بود`);

        done += 1;
        setProgress(Math.round((done / list.length) * 100));
      }

      setMessage(
        list.length > 1
          ? `${list.length.toLocaleString("fa-IR")} فایل با موفقیت آپلود شد`
          : "آپلود موفق بود"
      );
      setUploadTitle("");
      setPage(1);
      await load(); // ⬅️ آپدیت ایجکسی لیست بعد از آپلود
    } catch (e: any) {
      setError(e?.message || "خطا در آپلود");
    } finally {
      setUploading(false);
      setTimeout(() => setProgress(0), 400);
    }
  }

  function openEdit(item: MediaItem) {
    setEditItem(item);
    setEditTitle(item.title || "");
    setEditAlt(item.alt || "");
  }

  // ویرایش (AJAX - بدون رفرش)
  async function saveEdit() {
    if (!editItem) return;
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/media/${editItem.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: editTitle,
          alt: editAlt,
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ذخیره ناموفق بود");

      setMessage("ویرایش ذخیره شد");
      setEditItem(null);
      await load(); // ⬅️ آپدیت ایجکسی لیست بعد از ویرایش
    } catch (e: any) {
      setError(e?.message || "خطا در ویرایش");
    } finally {
      setSaving(false);
    }
  }

  // حذف (AJAX - بدون رفرش)
  async function confirmDelete() {
    if (!deleteItem) return;
    setDeleting(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/media/${deleteItem.id}`, { method: "DELETE" });
      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        throw new Error("پاسخ نامعتبر از سرور (فایل route.ts وجود ندارد)");
      }
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "حذف ناموفق بود");
      
      // حذف از لیست بدون رفرش
      setItems(prev => prev.filter(item => item.id !== deleteItem.id));
      setTotal(prev => Math.max(0, prev - 1));
      setMessage("فایل با موفقیت حذف شد");
      setDeleteItem(null);
    } catch (e: any) {
      setError(e?.message || "خطا در حذف");
    } finally {
      setDeleting(false);
    }
  }

  const typeLabel = useMemo(
    () =>
      ({
        image: "تصویر",
        video: "ویدیو",
        audio: "صوت",
        file: "فایل",
      }) as Record<string, string>,
    []
  );

  return (
    <main className="p-4 space-y-4 pb-8">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>رسانه</h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>
            {total.toLocaleString("fa-IR")} مورد از کتابخانه وردپرس
          </p>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setViewMode("list")}
            className={`px-3 py-1.5 rounded-lg text-xs border ${viewMode === "list" ? "bg-slate-100" : ""}`}
            style={{ borderColor: "var(--border)" }}
          >
            لیستی
          </button>
          <button
            type="button"
            onClick={() => setViewMode("grid")}
            className={`px-3 py-1.5 rounded-lg text-xs border ${viewMode === "grid" ? "bg-slate-100" : ""}`}
            style={{ borderColor: "var(--border)" }}
          >
            جدولی دو ستونه
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--danger)" }}>
          {error}
        </div>
      )}
      {message && (
        <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--success)" }}>
          {message}
        </div>
      )}

      {/* آپلود */}
      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">آپلود فایل (تکی / دسته‌ای)</h3>
        <input
          value={uploadTitle}
          onChange={(e) => setUploadTitle(e.target.value)}
          placeholder="عنوان اختیاری برای فایل‌(ها)"
          className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none"
          style={{ borderColor: "var(--border)" }}
        />
        <label className="block">
          <div
            className="rounded-2xl border border-dashed p-6 text-center cursor-pointer"
            style={{ borderColor: "var(--border)", background: "#f8fafc" }}
          >
            <div className="text-sm font-medium">کلیک برای انتخاب فایل‌ها</div>
            <div className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>
              امکان انتخاب چند فایل با هم
            </div>
          </div>
          <input
            ref={fileInputRef}
            type="file"
            multiple
            className="hidden"
            onChange={(e) => {
              uploadFiles(e.target.files);
              e.currentTarget.value = "";
            }}
          />
        </label>
        {uploading && (
          <div className="space-y-1">
            <div className="text-xs" style={{ color: "var(--text-muted)" }}>
              در حال آپلود... {progress.toLocaleString("fa-IR")}٪
            </div>
            <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
              <div className="h-2 rounded-full" style={{ width: `${progress}%`, background: "var(--primary)" }} />
            </div>
          </div>
        )}
      </section>

      {/* فیلترها */}
      <div className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="جستجو عنوان..."
            className="w-full border rounded-xl px-3 py-2.5 outline-none text-sm"
            style={{ borderColor: "var(--border)" }}
          />
          <select
            value={type}
            onChange={(e) => {
              setType(e.target.value);
              setPage(1);
            }}
            className="w-full border rounded-xl px-3 py-2.5 outline-none text-sm"
            style={{ borderColor: "var(--border)" }}
          >
            <option value="">همه فرمت‌ها</option>
            <option value="image">تصویر</option>
            <option value="video">ویدیو</option>
            <option value="audio">صوت</option>
            <option value="file">فایل</option>
          </select>
          <select
            value={sizeFilter}
            onChange={(e) => setSizeFilter(e.target.value)}
            className="w-full border rounded-xl px-3 py-2.5 outline-none text-sm"
            style={{ borderColor: "var(--border)" }}
          >
            <option value="all">همه سایزها</option>
            <option value="small">کوچک (زیر ۱۰۰KB)</option>
            <option value="medium">متوسط (۱۰۰KB - ۱MB)</option>
            <option value="large">بزرگ (بالای ۱MB)</option>
          </select>
          <div className="grid grid-cols-2 gap-2">
            <DatePicker
              value={dateFrom}
              onChange={(d) => setDateFrom(d ? d.toDate().toISOString() : "")}
              calendar={persian}
              locale={persian_fa}
              inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none"
              containerClassName="w-full"
              placeholder="از تاریخ"
            />
            <DatePicker
              value={dateTo}
              onChange={(d) => setDateTo(d ? d.toDate().toISOString() : "")}
              calendar={persian}
              locale={persian_fa}
              inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none"
              containerClassName="w-full"
              placeholder="تا تاریخ"
            />
          </div>
        </div>
      </div>

      {loading && (
        <div className="text-sm" style={{ color: "var(--text-muted)" }}>
          در حال دریافت از وردپرس...
        </div>
      )}

      {/* حالت لیستی */}
      {!loading && viewMode === "list" && items.length === 0 && !error && (
        <div
          className="bg-white border rounded-2xl p-6 text-center text-sm"
          style={{ borderColor: "var(--border)", color: "var(--text-muted)" }}
        >
          رسانه‌ای یافت نشد
        </div>
      )}

      {!loading && viewMode === "list" && items.length > 0 && (
        <div className="space-y-3">
          {items.map((item) => (
            <div
              key={item.id}
              className="bg-white border rounded-2xl p-3 flex gap-3"
              style={{ borderColor: "var(--border)" }}
            >
              <button
                type="button"
                className="w-20 h-20 rounded-xl overflow-hidden bg-slate-50 shrink-0 flex items-center justify-center"
                onClick={() => setViewItem(item)}
              >
                {item.type === "image" ? (
                  <img src={item.url} alt={item.title} className="w-full h-full object-cover" />
                ) : (
                  <span className="text-xs" style={{ color: "var(--text-muted)" }}>
                    {typeLabel[item.type] || "فایل"}
                  </span>
                )}
              </button>

              <div className="min-w-0 flex-1 space-y-1">
                <div className="font-bold text-sm truncate">{item.title}</div>
                <div className="text-xs" style={{ color: "var(--text-muted)" }}>
                  {typeLabel[item.type] || item.type} · {item.size} · {toFaDate(item.date)}
                </div>
                <div className="text-[11px] break-all" style={{ color: "var(--text-muted)" }}>
                  {item.url}
                </div>

                <div className="flex flex-wrap gap-2 pt-1">
                  <button
                    type="button"
                    onClick={() => setViewItem(item)}
                    className="px-2.5 py-1 rounded-lg text-xs border"
                    style={{ borderColor: "var(--border)" }}
                  >
                    مشاهده
                  </button>
                  <button
                    type="button"
                    onClick={() => openEdit(item)}
                    className="px-2.5 py-1 rounded-lg text-xs border"
                    style={{ borderColor: "var(--border)" }}
                  >
                    ویرایش
                  </button>
                  <button
                    type="button"
                    onClick={() => copyLink(item.url)}
                    className="px-2.5 py-1 rounded-lg text-xs border"
                    style={{ borderColor: "var(--border)" }}
                  >
                    کپی لینک
                  </button>
                  <button
                    type="button"
                    onClick={() => setDeleteItem(item)}
                    className="px-2.5 py-1 rounded-lg text-xs border"
                    style={{ borderColor: "var(--border)", color: "var(--danger)" }}
                  >
                    حذف
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* حالت جدولی دو ستونه */}
      {!loading && viewMode === "grid" && items.length > 0 && (
        <div className="grid grid-cols-2 gap-4">
          {items.map((item) => (
            <div
              key={item.id}
              className="relative bg-white border rounded-2xl overflow-hidden group"
              style={{ borderColor: "var(--border)" }}
            >
              <button
                type="button"
                className="block w-full h-40 overflow-hidden"
                onClick={() => openEdit(item)}
              >
                {item.type === "image" ? (
                  <img
                    src={item.url}
                    alt={item.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-slate-50 text-xs" style={{ color: "var(--text-muted)" }}>
                    {typeLabel[item.type] || "فایل"}
                  </div>
                )}
              </button>

              <div className="absolute top-2 left-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  type="button"
                  onClick={() => openEdit(item)}
                  className="p-1.5 rounded-lg bg-white/90 text-xs border"
                  style={{ borderColor: "var(--border)" }}
                >
                  ✏️ ویرایش
                </button>
                <button
                  type="button"
                  onClick={() => setDeleteItem(item)}
                  className="p-1.5 rounded-lg bg-red-50 text-xs text-red-600 border"
                  style={{ borderColor: "var(--border)" }}
                >
                  🗑️ حذف
                </button>
              </div>

              <div className="p-2">
                <div className="text-xs font-bold truncate">{item.title}</div>
                <div className="text-[10px] text-slate-400">
                  {item.size} · {toFaDate(item.date)}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <Pagination page={page} totalPages={totalPages} onChange={setPage} />

      {/* مودال مشاهده */}
      {viewItem && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4" onClick={() => setViewItem(null)}>
          <div className="bg-white w-full max-w-lg rounded-2xl p-4 space-y-3 max-h-[90vh] overflow-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between gap-2">
              <h3 className="font-bold text-sm">مشاهده رسانه</h3>
              <button onClick={() => setViewItem(null)}>بستن</button>
            </div>

            {viewItem.type === "image" ? (
              <img src={viewItem.url} alt={viewItem.title} className="w-full rounded-xl max-h-[50vh] object-contain bg-slate-50" />
            ) : (
              <div className="p-8 text-center text-sm" style={{ color: "var(--text-muted)" }}>
                پیش‌نمایش این نوع فایل در دسترس نیست
              </div>
            )}

            <div className="text-sm space-y-1">
              <div><b>عنوان:</b> {viewItem.title}</div>
              <div><b>حجم:</b> {viewItem.size}</div>
              <div><b>تاریخ ایجاد:</b> {toFaDateTime(viewItem.date)}</div>
              {viewItem.width && viewItem.height ? (
                <div><b>ابعاد:</b> {viewItem.width} × {viewItem.height}</div>
              ) : null}
              <div className="break-all"><b>لینک:</b> {viewItem.url}</div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => copyLink(viewItem.url)}
                className="py-2.5 rounded-xl text-sm text-white"
                style={{ background: "var(--primary)" }}
              >
                کپی لینک
              </button>
              <button
                type="button"
                onClick={() => {
                  setViewItem(null);
                  openEdit(viewItem);
                }}
                className="py-2.5 rounded-xl text-sm border"
                style={{ borderColor: "var(--border)" }}
              >
                ویرایش
              </button>
            </div>
          </div>
        </div>
      )}

      {/* مودال ویرایش */}
      {editItem && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4" onClick={() => setEditItem(null)}>
          <div className="bg-white w-full max-w-lg rounded-2xl p-4 space-y-3" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between gap-2">
              <h3 className="font-bold text-sm">ویرایش رسانه</h3>
              <button onClick={() => setEditItem(null)}>بستن</button>
            </div>

            {editItem.type === "image" && (
              <img src={editItem.url} alt={editItem.title} className="w-full rounded-xl max-h-40 object-contain bg-slate-50" />
            )}

            <div>
              <label className="text-sm block mb-1">عنوان</label>
              <input
                value={editTitle}
                onChange={(e) => setEditTitle(e.target.value)}
                className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none"
                style={{ borderColor: "var(--border)" }}
              />
            </div>

            <div>
              <label className="text-sm block mb-1">متن جایگزین (ALT)</label>
              <input
                value={editAlt}
                onChange={(e) => setEditAlt(e.target.value)}
                className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none"
                style={{ borderColor: "var(--border)" }}
              />
            </div>

            <div className="text-xs break-all" style={{ color: "var(--text-muted)" }}>
              لینک: {editItem.url}
            </div>

            <button
              type="button"
              onClick={saveEdit}
              disabled={saving}
              className="w-full py-2.5 rounded-xl text-sm text-white disabled:opacity-60"
              style={{ background: "var(--primary)" }}
            >
              {saving ? "در حال ذخیره..." : "ذخیره تغییرات"}
            </button>
          </div>
        </div>
      )}

      {/* مودال تایید حذف (وسط صفحه) */}
      {deleteItem && (
        <div className="fixed inset-0 z-[60] bg-black/60 flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-sm rounded-2xl p-6 space-y-4 text-center shadow-2xl">
            <div className="text-4xl">🗑️</div>
            <h3 className="font-bold text-lg">حذف فایل</h3>
            <p className="text-sm text-slate-500">
              آیا از حذف «{deleteItem.title}» مطمئن هستید؟ این عمل غیرقابل بازگشت است.
            </p>
            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={confirmDelete}
                disabled={deleting}
                className="flex-1 py-2.5 rounded-xl text-sm text-white bg-red-600 hover:bg-red-700 disabled:opacity-50"
              >
                {deleting ? "در حال حذف..." : "بله، حذف کن"}
              </button>
              <button
                type="button"
                onClick={() => setDeleteItem(null)}
                disabled={deleting}
                className="flex-1 py-2.5 rounded-xl text-sm border"
                style={{ borderColor: "var(--border)" }}
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