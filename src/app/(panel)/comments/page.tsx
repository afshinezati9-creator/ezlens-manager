"use client";

import { useEffect, useMemo, useState } from "react";
import Pagination from "@/components/ui/Pagination";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

type CommentItem = {
  id: number;
  author: number;
  author_name: string;
  author_email: string;
  author_url: string;
  author_avatar: string;
  content: string;
  date: string;
  status: string;
  link: string;
  post: number;
  post_title: string;
  post_link: string;
  post_type: string;
  post_type_label: string;
  parent: number;
  ip: string;
  user_agent: string;
};

type UserProfile = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  role: string;
  billing?: { phone?: string; city?: string; address_1?: string };
  total_spent?: string;
  date_created?: string;
};

function toFaDate(iso: string) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleString("fa-IR", {
      year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit"
    });
  } catch { return iso; }
}

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  approved: { label: "تأیید شده", color: "bg-emerald-100 text-emerald-700" },
  pending: { label: "در انتظار", color: "bg-amber-100 text-amber-700" },
  spam: { label: "اسپم", color: "bg-red-100 text-red-700" },
  trash: { label: "حذف شده", color: "bg-slate-100 text-slate-600" },
};

export default function CommentsPage() {
  const [items, setItems] = useState<CommentItem[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [q, setQ] = useState("");
  const [status, setStatus] = useState("any");
  const [postType, setPostType] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  
  // ⬇️ تنظیمات صفحه‌بندی
  const [perPage, setPerPage] = useState(20);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [replyItem, setReplyItem] = useState<CommentItem | null>(null);
  const [replyContent, setReplyContent] = useState("");
  const [replySaving, setReplySaving] = useState(false);

  const [deleteItem, setDeleteItem] = useState<CommentItem | null>(null);
  const [deleting, setDeleting] = useState(false);

  const [profileItem, setProfileItem] = useState<CommentItem | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [profileLoading, setProfileLoading] = useState(false);

  async function load() {
    setLoading(true);
    setError("");
    try {
      const params = new URLSearchParams({ 
        page: String(page), 
        per_page: String(perPage) // ⬅️ استفاده از perPage
      });
      if (q.trim()) params.set("search", q.trim());
      if (status !== "any") params.set("status", status);
      if (dateFrom) params.set("after", new Date(dateFrom).toISOString());
      if (dateTo) params.set("before", new Date(dateTo).toISOString());

      const res = await fetch(`/api/comments?${params.toString()}`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در دریافت نظرات");

      let filteredItems = data.items || [];
      if (postType !== "all") {
        filteredItems = filteredItems.filter((item: CommentItem) => item.post_type === postType);
      }

      setItems(filteredItems);
      setTotal(data.total || 0);
      setTotalPages(data.totalPages || 1);
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
  }, [page, status, dateFrom, dateTo, perPage]); // ⬅️ وابستگی perPage

  useEffect(() => {
    const t = setTimeout(() => { setPage(1); load(); }, 350);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  // با تغییر تعداد در صفحه، به صفحه اول برگرد
  useEffect(() => {
    setPage(1);
  }, [perPage]);

  async function openProfile(item: CommentItem) {
    setProfileItem(item);
    setUserProfile(null);
    setProfileLoading(true);

    if (item.author && item.author > 0) {
      try {
        const res = await fetch(`/api/users/${item.author}`);
        const data = await res.json();
        if (res.ok) {
          setUserProfile(data);
        } else {
          setUserProfile(null);
        }
      } catch (e) {
        setUserProfile(null);
      }
    } else {
      setUserProfile({
        id: 0,
        first_name: item.author_name || "کاربر مهمان",
        last_name: "",
        email: item.author_email || "ندارد",
        role: "مهمان",
      });
    }
    setProfileLoading(false);
  }

  async function updateStatus(id: number, newStatus: string) {
    setError(""); setMessage("");
    try {
      const res = await fetch(`/api/comments/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در تغییر وضعیت");
      setItems(prev => prev.map(item => item.id === id ? { ...item, status: newStatus } : item));
      setMessage("وضعیت نظر با موفقیت تغییر کرد");
    } catch (e: any) { setError(e?.message || "خطا در تغییر وضعیت"); }
  }

  async function submitReply() {
    if (!replyItem || !replyContent.trim()) return;
    setReplySaving(true);
    setError(""); setMessage("");
    try {
      const res = await fetch("/api/comments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ post: replyItem.post, content: replyContent.trim(), parent: replyItem.id, author_name: "مدیر سایت", author_email: "info@ezlens.ir" }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در ارسال پاسخ");
      setMessage("پاسخ با موفقیت ارسال شد");
      setReplyItem(null);
      setReplyContent("");
      await load();
    } catch (e: any) { setError(e?.message || "خطا در پاسخ"); }
    finally { setReplySaving(false); }
  }

  async function confirmDelete() {
    if (!deleteItem) return;
    setDeleting(true); setError(""); setMessage("");
    try {
      const res = await fetch(`/api/comments/${deleteItem.id}`, { method: "DELETE" });
      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) throw new Error("پاسخ نامعتبر از سرور");
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "حذف ناموفق بود");
      setItems(prev => prev.filter(item => item.id !== deleteItem.id));
      setTotal(prev => Math.max(0, prev - 1));
      setMessage("نظر حذف شد");
      setDeleteItem(null);
    } catch (e: any) { setError(e?.message || "خطا در حذف"); }
    finally { setDeleting(false); }
  }

  return (
    <main className="p-4 space-y-4 pb-8">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>نظرات</h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>{total.toLocaleString("fa-IR")} نظر</p>
        </div>
      </div>

      {error && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--danger)" }}>{error}</div>}
      {message && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--success)" }}>{message}</div>}

      {/* فیلترهای پیشرفته */}
      <div className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="جستجو در نظرات..." className="w-full border rounded-xl px-3 py-2.5 outline-none text-sm" style={{ borderColor: "var(--border)" }} />
          <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} className="w-full border rounded-xl px-3 py-2.5 outline-none text-sm bg-white" style={{ borderColor: "var(--border)" }}>
            <option value="any">همه وضعیت‌ها</option>
            <option value="approved">تأیید شده</option>
            <option value="pending">در انتظار</option>
            <option value="spam">اسپم</option>
            <option value="trash">حذف شده</option>
          </select>
          <select value={postType} onChange={(e) => { setPostType(e.target.value); setPage(1); }} className="w-full border rounded-xl px-3 py-2.5 outline-none text-sm bg-white" style={{ borderColor: "var(--border)" }}>
            <option value="all">همه نوع پست‌ها</option>
            <option value="product">محصولات</option>
            <option value="post">نوشته‌ها</option>
            <option value="page">برگه‌ها</option>
          </select>
          <div className="grid grid-cols-2 gap-2">
            <DatePicker value={dateFrom} onChange={(d) => setDateFrom(d ? d.toDate().toISOString() : "")} calendar={persian} locale={persian_fa} inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none" containerClassName="w-full" placeholder="از تاریخ" />
            <DatePicker value={dateTo} onChange={(d) => setDateTo(d ? d.toDate().toISOString() : "")} calendar={persian} locale={persian_fa} inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none" containerClassName="w-full" placeholder="تا تاریخ" />
          </div>
        </div>

        {/* ⬇️ تنظیمات صفحه‌بندی */}
        <div className="flex items-center justify-between pt-3 border-t text-sm text-slate-500" style={{ borderColor: "var(--border)" }}>
          <div className="flex items-center gap-2">
            <span>تعداد در صفحه:</span>
            <select
              value={perPage}
              onChange={(e) => setPerPage(Number(e.target.value))}
              className="border rounded-lg px-2 py-1 text-sm outline-none bg-white"
              style={{ borderColor: "var(--border)" }}
            >
              <option value={5}>۵</option>
              <option value={10}>۱۰</option>
              <option value={20}>۲۰</option>
              <option value={50}>۵۰</option>
            </select>
          </div>
          <span>تعداد کل: {total.toLocaleString("fa-IR")} نظر</span>
        </div>
      </div>

      {loading && <div className="text-sm" style={{ color: "var(--text-muted)" }}>در حال دریافت نظرات...</div>}

      {!loading && items.length === 0 && !error && (
        <div className="bg-white border rounded-2xl p-6 text-center text-sm" style={{ borderColor: "var(--border)", color: "var(--text-muted)" }}>نظری یافت نشد</div>
      )}

      {/* لیست نظرات */}
      {!loading && items.length > 0 && (
        <div className="space-y-3">
          {items.map((item) => {
            const statusMeta = STATUS_LABELS[item.status] || { label: item.status, color: "bg-slate-100 text-slate-600" };
            return (
              <div key={item.id} className="bg-white border rounded-2xl p-4 hover:shadow-sm transition" style={{ borderColor: "var(--border)" }}>
                <div className="flex flex-col gap-3">
                  {/* هدر: اطلاعات کاربر (با قابلیت کلیک برای مشاهده پروفایل) */}
                  <div className="flex items-start justify-between gap-3">
                    <button type="button" onClick={() => openProfile(item)} className="flex items-center gap-3 hover:bg-slate-50 p-1 rounded-lg transition text-left">
                      {item.author_avatar ? (
                        <img src={item.author_avatar} alt={item.author_name} className="w-10 h-10 rounded-full object-cover shrink-0" />
                      ) : (
                        <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-600 font-bold shrink-0">
                          {(item.author_name?.[0] || "؟").toUpperCase()}
                        </div>
                      )}
                      <div>
                        <div className="font-bold text-sm text-blue-600 hover:underline">{item.author_name}</div>
                        <div className="text-xs text-slate-500">{item.author_email}</div>
                      </div>
                    </button>
                    <span className={`text-[11px] px-2 py-0.5 rounded-full ${statusMeta.color}`}>{statusMeta.label}</span>
                  </div>

                  {/* بخش "از کجا آمده" */}
                  <div className="bg-slate-50 rounded-xl p-3 text-xs text-slate-600 flex flex-wrap gap-2 items-center">
                    <span>📍 روی:</span>
                    <a href={item.post_link} target="_blank" rel="noreferrer" className="text-blue-600 font-medium hover:underline">{item.post_title} ({item.post_type_label})</a>
                    <span className="text-slate-400">|</span>
                    <span>🕒 {toFaDate(item.date)}</span>
                  </div>

                  {/* محتوا */}
                  <div className="text-sm text-slate-700 whitespace-pre-wrap" dangerouslySetInnerHTML={{ __html: item.content }} />

                  {/* جزئیات فنی */}
                  <div className="flex flex-col gap-1 text-[11px] text-slate-400 border-t pt-2" style={{ borderColor: "var(--border)" }}>
                    {item.ip && <div>🌐 IP: <span dir="ltr">{item.ip}</span></div>}
                    {item.user_agent && <div>💻 مرورگر: <span className="line-clamp-1" title={item.user_agent}>{item.user_agent}</span></div>}
                  </div>

                  {/* دکمه‌ها */}
                  <div className="flex flex-wrap gap-2 pt-1 border-t" style={{ borderColor: "var(--border)" }}>
                    {item.status !== "approved" && <button onClick={() => updateStatus(item.id, "approved")} className="px-2.5 py-1 rounded-lg text-xs bg-emerald-50 text-emerald-600 hover:bg-emerald-100">✓ تأیید</button>}
                    {item.status === "approved" && <button onClick={() => updateStatus(item.id, "pending")} className="px-2.5 py-1 rounded-lg text-xs bg-amber-50 text-amber-600 hover:bg-amber-100">⏳ معلق</button>}
                    <button onClick={() => setReplyItem(item)} className="px-2.5 py-1 rounded-lg text-xs bg-blue-50 text-blue-600 hover:bg-blue-100">↩ پاسخ</button>
                    <button onClick={() => updateStatus(item.id, "spam")} className="px-2.5 py-1 rounded-lg text-xs bg-red-50 text-red-600 hover:bg-red-100">⚠ اسپم</button>
                    <button onClick={() => setDeleteItem(item)} className="px-2.5 py-1 rounded-lg text-xs bg-slate-100 text-slate-600 hover:bg-slate-200">🗑 حذف</button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      <Pagination page={page} totalPages={totalPages} onChange={setPage} />

      {/* مودال پاسخ */}
      {replyItem && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4" onClick={() => setReplyItem(null)}>
          <div className="bg-white w-full max-w-lg rounded-2xl p-4 space-y-3" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between gap-2">
              <h3 className="font-bold text-sm">پاسخ به {replyItem.author_name}</h3>
              <button onClick={() => setReplyItem(null)}>بستن</button>
            </div>
            <div className="bg-slate-50 rounded-xl p-3 text-xs text-slate-600">{replyItem.content.replace(/<[^>]*>/g, "").slice(0, 200)}</div>
            <textarea value={replyContent} onChange={(e) => setReplyContent(e.target.value)} rows={4} placeholder="متن پاسخ خود را بنویسید..." className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500" />
            <button onClick={submitReply} disabled={replySaving || !replyContent.trim()} className="w-full py-2.5 rounded-xl text-sm text-white disabled:opacity-60" style={{ background: "var(--primary)" }}>
              {replySaving ? "در حال ارسال..." : "ارسال پاسخ"}
            </button>
          </div>
        </div>
      )}

      {/* مودال حذف */}
      {deleteItem && (
        <div className="fixed inset-0 z-[60] bg-black/60 flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-sm rounded-2xl p-6 space-y-4 text-center shadow-2xl">
            <div className="text-4xl">🗑️</div>
            <h3 className="font-bold text-lg">حذف نظر</h3>
            <p className="text-sm text-slate-500">آیا از حذف نظر «{deleteItem.author_name}» مطمئن هستید؟</p>
            <div className="flex gap-2 pt-2">
              <button onClick={confirmDelete} disabled={deleting} className="flex-1 py-2.5 rounded-xl text-sm text-white bg-red-600 hover:bg-red-700 disabled:opacity-50">{deleting ? "در حال حذف..." : "بله، حذف کن"}</button>
              <button onClick={() => setDeleteItem(null)} disabled={deleting} className="flex-1 py-2.5 rounded-xl text-sm border" style={{ borderColor: "var(--border)" }}>انصراف</button>
            </div>
          </div>
        </div>
      )}

      {/* مودال پروفایل کاربر */}
      {profileItem && (
        <div className="fixed inset-0 z-[70] bg-black/60 flex items-center justify-center p-4" onClick={() => setProfileItem(null)}>
          <div className="bg-white w-full max-w-md rounded-2xl p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg">مشخصات کاربر</h3>
              <button onClick={() => setProfileItem(null)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>

            {profileLoading ? (
              <div className="text-center py-4 text-slate-500">در حال بارگذاری...</div>
            ) : userProfile ? (
              <>
                <div className="flex items-center gap-4">
                  <div className="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center text-2xl font-bold text-slate-600">
                    {(userProfile.first_name?.[0] || userProfile.email?.[0] || "؟").toUpperCase()}
                  </div>
                  <div>
                    <div className="font-bold text-lg">{userProfile.first_name} {userProfile.last_name}</div>
                    <div className="text-sm text-slate-500">{userProfile.email}</div>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4 text-sm border-t pt-4" style={{ borderColor: "var(--border)" }}>
                  <div><span className="text-slate-400">نقش:</span> <div className="font-medium">{userProfile.role === "customer" ? "مشتری" : userProfile.role === "subscriber" ? "کاربر" : "مهمان"}</div></div>
                  <div><span className="text-slate-400">تلفن:</span> <div className="font-medium">{userProfile.billing?.phone || "ندارد"}</div></div>
                  <div><span className="text-slate-400">مجموع خرید:</span> <div className="font-medium">{userProfile.total_spent ? Number(userProfile.total_spent).toLocaleString("fa-IR") + " تومان" : "—"}</div></div>
                  <div><span className="text-slate-400">تاریخ عضویت:</span> <div className="font-medium">{userProfile.date_created ? toFaDate(userProfile.date_created) : "—"}</div></div>
                </div>

                <div className="flex gap-2 pt-4 border-t" style={{ borderColor: "var(--border)" }}>
                  {userProfile.id > 0 && (
                    <a href={`/users/${userProfile.id}`} className="flex-1 text-center py-2 rounded-xl text-sm text-white" style={{ background: "var(--primary)" }}>ویرایش کامل پروفایل</a>
                  )}
                  <button onClick={() => setProfileItem(null)} className="flex-1 py-2 rounded-xl text-sm border" style={{ borderColor: "var(--border)" }}>بستن</button>
                </div>
              </>
            ) : (
              <div className="text-center py-4 text-slate-500">اطلاعات کاربر یافت نشد (مهمان یا حذف شده)</div>
            )}
          </div>
        </div>
      )}
    </main>
  );
}