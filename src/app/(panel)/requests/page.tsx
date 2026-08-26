"use client";

import { useEffect, useMemo, useState } from "react";
import Pagination from "@/components/ui/Pagination";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

type RequestItem = {
  id: number;
  form_id?: number;
  form_title?: string;
  name?: string;
  email?: string;
  phone?: string;
  subject?: string;
  message?: string;
  status?: string;
  date?: string;
  created_at?: string;
  files?: Array<{ name?: string; url?: string; path?: string; type?: string }>;
  meta?: Record<string, any>;
  user_id?: number;
};

const STATUS_CONFIG: Record<string, { label: string; bg: string; text: string; dot: string }> = {
  new: { label: "جدید", bg: "bg-blue-50", text: "text-blue-700", dot: "bg-blue-500" },
  review: { label: "در حال بررسی", bg: "bg-amber-50", text: "text-amber-700", dot: "bg-amber-500" },
  processed: { label: "بررسی شده", bg: "bg-emerald-50", text: "text-emerald-700", dot: "bg-emerald-500" },
  rejected: { label: "رد شده", bg: "bg-red-50", text: "text-red-700", dot: "bg-red-500" },
};

function toFaDateTime(iso?: string) {
  if (!iso) return "—";
  try {
    return new Intl.DateTimeFormat("fa-IR-u-ca-persian", {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    }).format(new Date(iso));
  } catch { return iso; }
}

function getFileType(url?: string) {
  if (!url) return "file";
  const ext = url.split(".").pop()?.toLowerCase();
  if (["jpg", "jpeg", "png", "gif", "webp", "svg"].includes(ext || "")) return "image";
  if (["pdf", "doc", "docx", "txt", "xls", "xlsx"].includes(ext || "")) return "document";
  if (["mp4", "avi", "mov"].includes(ext || "")) return "video";
  return "file";
}

export default function RequestsPage() {
  const [items, setItems] = useState<RequestItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [q, setQ] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");

  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [totalPages, setTotalPages] = useState(1);

  const [viewItem, setViewItem] = useState<RequestItem | null>(null);
  const [deleteItem, setDeleteItem] = useState<RequestItem | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [updatingStatus, setUpdatingStatus] = useState<number | null>(null);

  const stats = useMemo(() => {
    return {
      total: items.length,
      new: items.filter(i => i.status === "new").length,
      review: items.filter(i => i.status === "review").length,
      processed: items.filter(i => i.status === "processed").length,
      rejected: items.filter(i => i.status === "rejected").length,
    };
  }, [items]);

  async function load() {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`/api/ei-requests`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در دریافت درخواست‌ها");

      let list = data.items || [];

      if (q.trim()) {
        const term = q.trim().toLowerCase();
        list = list.filter((item: RequestItem) =>
          (item.name || "").toLowerCase().includes(term) ||
          (item.email || "").toLowerCase().includes(term) ||
          (item.phone || "").includes(term)
        );
      }
      if (statusFilter !== "all") {
        list = list.filter((item: RequestItem) => item.status === statusFilter);
      }
      if (dateFrom) {
        const from = new Date(dateFrom).getTime();
        list = list.filter((item: RequestItem) => new Date(item.date || item.created_at || "").getTime() >= from);
      }
      if (dateTo) {
        const to = new Date(dateTo).getTime() + 86400000;
        list = list.filter((item: RequestItem) => new Date(item.date || item.created_at || "").getTime() <= to);
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
  }, [q, statusFilter, dateFrom, dateTo]);

  async function updateStatus(id: number, newStatus: string) {
    setUpdatingStatus(id);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/ei-requests/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در تغییر وضعیت");
      setItems(prev => prev.map(item => item.id === id ? { ...item, status: newStatus } : item));
      setMessage("وضعیت با موفقیت تغییر کرد");
    } catch (e: any) {
      setError(e?.message || "خطا در تغییر وضعیت");
    } finally {
      setUpdatingStatus(null);
    }
  }

  async function confirmDelete() {
    if (!deleteItem) return;
    setDeleting(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/ei-requests/${deleteItem.id}`, { method: "DELETE" });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "حذف ناموفق بود");
      setItems(prev => prev.filter(item => item.id !== deleteItem.id));
      setMessage("درخواست حذف شد");
      setDeleteItem(null);
    } catch (e: any) {
      setError(e?.message || "خطا در حذف");
    } finally {
      setDeleting(false);
    }
  }

  function copyText(text?: string) {
    if (!text) return;
    navigator.clipboard.writeText(text).then(() => setMessage("کپی شد"));
  }

  const pagedItems = items.slice((page - 1) * perPage, page * perPage);

  return (
    <main className="min-h-screen bg-slate-50 py-6">
      <div className="max-w-7xl mx-auto px-4 space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-slate-900">درخواست‌ها</h1>
            <p className="text-sm text-slate-500 mt-1">مدیریت درخواست‌های ارسال‌شده از فرم‌های سایت</p>
          </div>
        </div>

        {/* آمار کلی */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center text-slate-600">📊</div>
              <span className="text-sm text-slate-500">کل</span>
            </div>
            <div className="text-2xl font-bold mt-2 text-slate-900">{stats.total.toLocaleString("fa-IR")}</div>
          </div>
          <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center text-blue-600">🆕</div>
              <span className="text-sm text-slate-500">جدید</span>
            </div>
            <div className="text-2xl font-bold mt-2 text-blue-600">{stats.new.toLocaleString("fa-IR")}</div>
          </div>
          <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-amber-50 flex items-center justify-center text-amber-600">⏳</div>
              <span className="text-sm text-slate-500">در حال بررسی</span>
            </div>
            <div className="text-2xl font-bold mt-2 text-amber-600">{stats.review.toLocaleString("fa-IR")}</div>
          </div>
          <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600">✅</div>
              <span className="text-sm text-slate-500">بررسی شده</span>
            </div>
            <div className="text-2xl font-bold mt-2 text-emerald-600">{stats.processed.toLocaleString("fa-IR")}</div>
          </div>
        </div>

        {error && <div className="rounded-xl px-4 py-3 text-sm text-white bg-red-500 shadow-sm">{error}</div>}
        {message && <div className="rounded-xl px-4 py-3 text-sm text-white bg-emerald-500 shadow-sm">{message}</div>}

        {/* فیلترها */}
        <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="جستجو نام، ایمیل، تلفن..."
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
            />
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
              className="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm outline-none bg-white"
            >
              <option value="all">همه وضعیت‌ها</option>
              <option value="new">جدید</option>
              <option value="review">در حال بررسی</option>
              <option value="processed">بررسی شده</option>
              <option value="rejected">رد شده</option>
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
            <div className="flex items-center gap-2 text-sm text-slate-500">
              <span>تعداد در صفحه:</span>
              <select
                value={perPage}
                onChange={(e) => { setPerPage(Number(e.target.value)); setPage(1); }}
                className="border border-slate-200 rounded-lg px-2 py-1.5 text-sm outline-none bg-white"
              >
                <option value={5}>۵</option>
                <option value={10}>۱۰</option>
                <option value={20}>۲۰</option>
                <option value={50}>۵۰</option>
              </select>
            </div>
          </div>
        </div>

        {loading && <div className="text-center py-10 text-slate-400">در حال بارگذاری...</div>}
        {!loading && pagedItems.length === 0 && !error && (
          <div className="bg-white border border-slate-200 rounded-2xl p-10 text-center text-slate-400">درخواستی یافت نشد</div>
        )}

        {/* لیست */}
        {!loading && pagedItems.length > 0 && (
          <div className="space-y-3">
            {pagedItems.map((item) => {
              const statusMeta = STATUS_CONFIG[item.status || "new"] || STATUS_CONFIG.new;
              return (
                <div key={item.id} className="bg-white border border-slate-200 rounded-2xl p-5 hover:shadow-md transition-shadow duration-200">
                  <div className="flex flex-col lg:flex-row lg:items-start gap-4">
                    {/* اطلاعات اصلی */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full" style={{ background: statusMeta.bg, color: statusMeta.text }}>
                          <span className={`w-1.5 h-1.5 rounded-full ${statusMeta.dot}`} />
                          {statusMeta.label}
                        </span>
                        <span className="text-xs text-slate-400">#{item.id}</span>
                        {item.form_title && (
                          <span className="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full">📋 {item.form_title}</span>
                        )}
                      </div>

                      {/* نام و اطلاعات تماس با برچسب مشخص */}
                      <div className="mt-3 space-y-1.5">
                        <div className="flex items-center gap-2">
                          <span className="w-6 text-center text-slate-400">👤</span>
                          <span className="font-bold text-slate-900">{item.name || "بدون نام"}</span>
                        </div>
                        {item.email && (
                          <div className="flex items-center gap-2">
                            <span className="w-6 text-center text-slate-400">✉️</span>
                            <span className="text-sm text-slate-600">{item.email}</span>
                            <button onClick={() => copyText(item.email)} className="text-xs text-blue-500 hover:underline">کپی</button>
                          </div>
                        )}
                        {item.phone && (
                          <div className="flex items-center gap-2">
                            <span className="w-6 text-center text-slate-400">📞</span>
                            <span className="text-sm text-slate-600" dir="ltr">{item.phone}</span>
                            <button onClick={() => copyText(item.phone)} className="text-xs text-blue-500 hover:underline">کپی</button>
                          </div>
                        )}
                      </div>

                      {item.message && (
                        <p className="mt-3 text-sm text-slate-600 line-clamp-2 bg-slate-50 rounded-lg p-3">{item.message}</p>
                      )}
                      <div className="mt-2 flex items-center gap-2 text-xs text-slate-400">
                        <span>🕒</span>
                        <span>{toFaDateTime(item.date || item.created_at)}</span>
                      </div>
                    </div>

                    {/* دکمه‌ها */}
                    <div className="flex flex-row lg:flex-col gap-2 lg:w-32 shrink-0">
                      <button
                        onClick={() => setViewItem(item)}
                        className="flex-1 py-2 rounded-lg text-xs font-medium bg-blue-50 text-blue-600 hover:bg-blue-100 transition"
                      >
                        👁️ مشاهده
                      </button>
                      {item.status !== "processed" && (
                        <button
                          onClick={() => updateStatus(item.id, "processed")}
                          disabled={updatingStatus === item.id}
                          className="flex-1 py-2 rounded-lg text-xs font-medium bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition disabled:opacity-50"
                        >
                          {updatingStatus === item.id ? "..." : "✅ بررسی شد"}
                        </button>
                      )}
                      {item.status !== "rejected" && (
                        <button
                          onClick={() => updateStatus(item.id, "rejected")}
                          disabled={updatingStatus === item.id}
                          className="flex-1 py-2 rounded-lg text-xs font-medium bg-red-50 text-red-600 hover:bg-red-100 transition disabled:opacity-50"
                        >
                          {updatingStatus === item.id ? "..." : "❌ رد"}
                        </button>
                      )}
                      <button
                        onClick={() => setDeleteItem(item)}
                        className="flex-1 py-2 rounded-lg text-xs font-medium bg-slate-100 text-slate-600 hover:bg-slate-200 transition"
                      >
                        🗑️ حذف
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <Pagination page={page} totalPages={totalPages} onChange={setPage} />
      </div>

      {/* مودال مشاهده جزئیات */}
      {viewItem && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4" onClick={() => setViewItem(null)}>
          <div className="bg-white w-full max-w-3xl rounded-2xl p-6 space-y-6 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg text-slate-900">جزئیات درخواست #{viewItem.id}</h3>
              <button onClick={() => setViewItem(null)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>

            {/* پالت اطلاعات کاربر */}
            <div className="bg-slate-50 rounded-xl p-5 border border-slate-200">
              <h4 className="text-xs font-bold text-slate-500 mb-3 uppercase tracking-wider">👤 اطلاعات کاربر</h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex items-center gap-2">
                  <span className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600">👤</span>
                  <div>
                    <div className="text-[10px] text-slate-400">نام</div>
                    <div className="text-sm font-medium text-slate-800">{viewItem.name || "—"}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600">✉️</span>
                  <div>
                    <div className="text-[10px] text-slate-400">ایمیل</div>
                    <div className="text-sm font-medium text-slate-800 break-all">{viewItem.email || "—"}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center text-amber-600">📞</span>
                  <div>
                    <div className="text-[10px] text-slate-400">تلفن</div>
                    <div className="text-sm font-medium text-slate-800" dir="ltr">{viewItem.phone || "—"}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-600">🕒</span>
                  <div>
                    <div className="text-[10px] text-slate-400">تاریخ</div>
                    <div className="text-sm font-medium text-slate-800">{toFaDateTime(viewItem.date || viewItem.created_at)}</div>
                  </div>
                </div>
              </div>
            </div>

            {/* پالت پیام */}
            {viewItem.message && (
              <div className="bg-white rounded-xl p-5 border border-slate-200">
                <h4 className="text-xs font-bold text-slate-500 mb-3 uppercase tracking-wider">💬 پیام</h4>
                <div className="text-sm text-slate-700 leading-relaxed whitespace-pre-wrap">{viewItem.message}</div>
              </div>
            )}

            {/* پالت فایل‌ها */}
            {viewItem.files && viewItem.files.length > 0 && (
              <div className="bg-white rounded-xl p-5 border border-slate-200">
                <h4 className="text-xs font-bold text-slate-500 mb-3 uppercase tracking-wider">📎 فایل‌های پیوست ({viewItem.files.length.toLocaleString("fa-IR")})</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {viewItem.files.map((file, idx) => {
                    const fileType = getFileType(file.url);
                    return (
                      <div key={idx} className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg border border-slate-200">
                        {fileType === "image" && file.url ? (
                          <img src={file.url} alt={file.name || "فایل"} className="w-14 h-14 rounded-lg object-cover border border-slate-200" />
                        ) : (
                          <div className="w-14 h-14 rounded-lg bg-slate-100 flex items-center justify-center text-xl">
                            {fileType === "document" ? "📄" : fileType === "video" ? "🎬" : "📎"}
                          </div>
                        )}
                        <div className="min-w-0 flex-1">
                          <div className="text-sm font-medium text-slate-700 truncate">{file.name || "فایل پیوست"}</div>
                          <div className="text-[10px] text-slate-400">{fileType === "image" ? "تصویر" : fileType === "document" ? "سند" : fileType === "video" ? "ویدیو" : "فایل"}</div>
                        </div>
                        <div className="flex flex-col gap-1">
                          {file.url && (
                            <a href={file.url} target="_blank" rel="noreferrer" className="text-xs text-blue-600 hover:underline">مشاهده</a>
                          )}
                          {file.url && (
                            <a href={file.url} download className="text-xs text-emerald-600 hover:underline">دانلود</a>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* پالت اطلاعات تکمیلی */}
            {viewItem.meta && Object.keys(viewItem.meta).length > 0 && (
              <div className="bg-white rounded-xl p-5 border border-slate-200">
                <h4 className="text-xs font-bold text-slate-500 mb-3 uppercase tracking-wider">📋 اطلاعات تکمیلی</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {Object.entries(viewItem.meta).map(([key, value]) => (
                    <div key={key} className="bg-slate-50 rounded-lg p-3">
                      <div className="text-[10px] text-slate-400">{key}</div>
                      <div className="text-sm font-medium text-slate-700">{String(value)}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* دکمه‌های عملیات */}
            <div className="flex flex-wrap gap-2 pt-2 border-t border-slate-100">
              {viewItem.status !== "processed" && (
                <button onClick={() => { updateStatus(viewItem.id, "processed"); setViewItem(null); }} className="px-4 py-2 rounded-xl text-sm text-white bg-emerald-600 hover:bg-emerald-700 transition">✅ تأیید و بررسی شد</button>
              )}
              {viewItem.status !== "review" && (
                <button onClick={() => { updateStatus(viewItem.id, "review"); setViewItem(null); }} className="px-4 py-2 rounded-xl text-sm text-white bg-amber-600 hover:bg-amber-700 transition">⏳ در حال بررسی</button>
              )}
              <button onClick={() => setViewItem(null)} className="px-4 py-2 rounded-xl text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 transition">بستن</button>
            </div>
          </div>
        </div>
      )}

      {/* مودال حذف */}
      {deleteItem && (
        <div className="fixed inset-0 z-[60] bg-black/60 flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-sm rounded-2xl p-6 space-y-4 text-center shadow-2xl">
            <div className="text-4xl">🗑️</div>
            <h3 className="font-bold text-lg text-slate-900">حذف درخواست</h3>
            <p className="text-sm text-slate-500">آیا از حذف درخواست «{deleteItem.name || `#${deleteItem.id}`}» مطمئن هستید؟</p>
            <div className="flex gap-2 pt-2">
              <button onClick={confirmDelete} disabled={deleting} className="flex-1 py-2.5 rounded-xl text-sm text-white bg-red-600 hover:bg-red-700 disabled:opacity-50 transition">
                {deleting ? "در حال حذف..." : "بله، حذف کن"}
              </button>
              <button onClick={() => setDeleteItem(null)} disabled={deleting} className="flex-1 py-2.5 rounded-xl text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-50 transition">
                انصراف
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}