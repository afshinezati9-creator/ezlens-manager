"use client";

import { useEffect, useState } from "react";
import Pagination from "@/components/ui/Pagination";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

// ============================================================
// ✅ آیکون‌های Lucide (مدرن و مینیمال)
// ============================================================
import {
  MessageSquare,
  Reply,
  CheckCircle,
  Clock,
  AlertCircle,
  Trash2,
  Eye,
  User,
  Mail,
  Calendar,
  MoreHorizontal,
  X,
  Send,
  RefreshCw,
  FileText,
  ShoppingBag,
  File,
} from "lucide-react";

// ============================================================
// تایپ‌ها
// ============================================================
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
  children?: CommentItem[];
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

// ============================================================
// توابع کمکی
// ============================================================
function toFaDate(iso: string) {
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

const STATUS_LABELS: Record<string, { label: string; color: string; icon: any }> = {
  approved: { label: "تأیید شده", color: "bg-emerald-100 text-emerald-700", icon: CheckCircle },
  pending: { label: "در انتظار", color: "bg-amber-100 text-amber-700", icon: Clock },
  spam: { label: "اسپم", color: "bg-red-100 text-red-700", icon: AlertCircle },
  trash: { label: "حذف شده", color: "bg-slate-100 text-slate-600", icon: Trash2 },
};

const POST_TYPE_ICONS: Record<string, any> = {
  post: FileText,
  page: File,
  product: ShoppingBag,
};

// ============================================================
// کامپوننت نظر تودرتو (برای مودال مکالمه)
// ============================================================
function CommentThread({
  comment,
  depth = 0,
  onReply,
}: {
  comment: CommentItem;
  depth?: number;
  onReply: (comment: CommentItem) => void;
}) {
  const statusMeta = STATUS_LABELS[comment.status] || {
    label: comment.status,
    color: "bg-slate-100 text-slate-600",
    icon: MessageSquare,
  };
  const StatusIcon = statusMeta.icon;

  const indent = depth * 16;

  return (
    <div
      className="relative"
      style={{
        marginRight: depth > 0 ? `${Math.min(indent, 128)}px` : 0,
        borderRight: depth > 0 ? "2px solid #e2e8f0" : "none",
        paddingRight: depth > 0 ? "12px" : 0,
      }}
    >
      <div
        className={`bg-white border rounded-2xl p-4 transition-all hover:shadow-sm ${
          depth > 0 ? "mt-3" : "mt-0"
        }`}
        style={{ borderColor: "var(--border)" }}
      >
        <div className="flex flex-col gap-2">
          {/* هدر */}
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
              {comment.author_avatar ? (
                <img
                  src={comment.author_avatar}
                  alt={comment.author_name}
                  className="w-8 h-8 rounded-full object-cover shrink-0 border border-slate-200"
                />
              ) : (
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center text-blue-700 font-bold text-sm shrink-0">
                  {(comment.author_name?.[0] || "؟").toUpperCase()}
                </div>
              )}
              <div>
                <div className="font-medium text-sm text-slate-800">
                  {comment.author_name}
                </div>
                <div className="text-xs text-slate-400 flex items-center gap-1">
                  <Mail className="w-3 h-3" />
                  {comment.author_email}
                </div>
                <div className="text-[10px] text-slate-400 mt-0.5 flex items-center gap-1">
                  <Calendar className="w-3 h-3" />
                  {toFaDate(comment.date)}
                </div>
              </div>
            </div>
            <span
              className={`flex items-center gap-1 text-[10px] px-2 py-0.5 rounded-full shrink-0 ${statusMeta.color}`}
            >
              <StatusIcon className="w-3 h-3" />
              {statusMeta.label}
            </span>
          </div>

          {/* محتوا */}
          <div
            className="text-sm text-slate-700 whitespace-pre-wrap bg-slate-50 rounded-xl p-3"
            dangerouslySetInnerHTML={{ __html: comment.content }}
          />

          {/* دکمه پاسخ */}
          <div className="flex justify-end mt-1">
            <button
              onClick={() => onReply(comment)}
              className="text-xs text-blue-600 hover:text-blue-800 flex items-center gap-1 transition-colors"
            >
              <Reply className="w-3.5 h-3.5" />
              پاسخ
            </button>
          </div>
        </div>
      </div>

      {/* فرزندان */}
      {comment.children && comment.children.length > 0 && (
        <div className="mt-2">
          {comment.children.map((child) => (
            <CommentThread
              key={child.id}
              comment={child}
              depth={depth + 1}
              onReply={onReply}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================================
// صفحه اصلی
// ============================================================
export default function CommentsPage() {
  // ----- لیست نظرات -----
  const [items, setItems] = useState<CommentItem[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [q, setQ] = useState("");
  const [status, setStatus] = useState("any");
  const [postType, setPostType] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [perPage, setPerPage] = useState(20);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // ----- مودال مکالمه -----
  const [conversationPostId, setConversationPostId] = useState<number | null>(null);
  const [conversationComments, setConversationComments] = useState<CommentItem[]>([]);
  const [conversationLoading, setConversationLoading] = useState(false);
  const [conversationError, setConversationError] = useState("");
  const [conversationPostTitle, setConversationPostTitle] = useState("");

  // ----- پاسخ در مودال -----
  const [replyTarget, setReplyTarget] = useState<CommentItem | null>(null);
  const [replyContent, setReplyContent] = useState("");
  const [replySaving, setReplySaving] = useState(false);

  // ----- سایر مودال‌ها -----
  const [deleteItem, setDeleteItem] = useState<CommentItem | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [profileItem, setProfileItem] = useState<CommentItem | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [profileLoading, setProfileLoading] = useState(false);

  // ===== بارگذاری لیست نظرات (Ajax) =====
  async function load() {
    setLoading(true);
    setError("");
    try {
      const params = new URLSearchParams({
        page: String(page),
        per_page: String(perPage),
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
        filteredItems = filteredItems.filter(
          (item: CommentItem) => item.post_type === postType
        );
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
  }, [page, status, dateFrom, dateTo, perPage]);

  useEffect(() => {
    const t = setTimeout(() => {
      setPage(1);
      load();
    }, 350);
    return () => clearTimeout(t);
  }, [q]);

  useEffect(() => {
    setPage(1);
  }, [perPage]);

  // ===== باز کردن مودال مکالمه (Ajax) =====
  async function openConversation(item: CommentItem) {
    setConversationPostId(item.post);
    setConversationPostTitle(item.post_title);
    setConversationLoading(true);
    setConversationError("");
    setConversationComments([]);
    setReplyTarget(null);
    setReplyContent("");

    try {
      const res = await fetch(`/api/comments?post=${item.post}&status=any&per_page=100`);
      const data = await res.json();

      if (!res.ok) throw new Error(data?.error || "خطا در دریافت مکالمه");

      setConversationComments(data.comments || []);
    } catch (e: any) {
      setConversationError(e?.message || "خطا در دریافت مکالمه");
    } finally {
      setConversationLoading(false);
    }
  }

  // ===== ارسال پاسخ در مودال (Ajax) =====
  async function submitReplyInModal() {
    if (!replyTarget || !replyContent.trim() || !conversationPostId) return;
    setReplySaving(true);
    setConversationError("");
    try {
      const res = await fetch("/api/comments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          post: conversationPostId,
          content: replyContent.trim(),
          parent: replyTarget.id,
          author_name: "مدیر سایت",
          author_email: "info@ezlens.ir",
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در ارسال پاسخ");

      // بارگذاری مجدد مکالمه (Ajax)
      await openConversation({ ...replyTarget, post: conversationPostId, post_title: conversationPostTitle } as CommentItem);
      setReplyContent("");
      setReplyTarget(null);
      setMessage("پاسخ با موفقیت ارسال شد");
    } catch (e: any) {
      setConversationError(e?.message || "خطا در پاسخ");
    } finally {
      setReplySaving(false);
    }
  }

  // ===== تغییر وضعیت (Ajax) =====
  async function updateStatus(id: number, newStatus: string) {
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/comments/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "خطا در تغییر وضعیت");
      setItems((prev) =>
        prev.map((item) =>
          item.id === id ? { ...item, status: newStatus } : item
        )
      );
      setMessage("وضعیت نظر با موفقیت تغییر کرد");
    } catch (e: any) {
      setError(e?.message || "خطا در تغییر وضعیت");
    }
  }

  // ===== حذف (Ajax) =====
  async function confirmDelete() {
    if (!deleteItem) return;
    setDeleting(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/comments/${deleteItem.id}`, {
        method: "DELETE",
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "حذف ناموفق بود");
      setItems((prev) => prev.filter((item) => item.id !== deleteItem.id));
      setTotal((prev) => Math.max(0, prev - 1));
      setMessage("نظر حذف شد");
      setDeleteItem(null);
    } catch (e: any) {
      setError(e?.message || "خطا در حذف");
    } finally {
      setDeleting(false);
    }
  }

  // ===== پروفایل (Ajax) =====
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

  // ============================================================
  // رندر
  // ============================================================
  return (
    <main className="p-4 space-y-4 pb-8 max-w-6xl mx-auto">
      {/* ===== هدر ===== */}
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold flex items-center gap-2" style={{ color: "var(--primary)" }}>
            <MessageSquare className="w-5 h-5" />
            نظرات
          </h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>
            {total.toLocaleString("fa-IR")} نظر
          </p>
        </div>
      </div>

      {/* ===== پیام‌ها ===== */}
      {error && (
        <div className="rounded-xl px-4 py-3 text-sm text-white flex items-center gap-2" style={{ background: "var(--danger)" }}>
          <AlertCircle className="w-4 h-4" />
          {error}
        </div>
      )}
      {message && (
        <div className="rounded-xl px-4 py-3 text-sm text-white flex items-center gap-2" style={{ background: "var(--success)" }}>
          <CheckCircle className="w-4 h-4" />
          {message}
        </div>
      )}

      {/* ===== فیلترها (مینیمال) ===== */}
      <div className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="جستجو در نظرات..."
            className="w-full border rounded-xl px-4 py-2.5 outline-none text-sm bg-transparent focus:ring-2 focus:ring-blue-500/20 transition"
            style={{ borderColor: "var(--border)" }}
          />
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value);
              setPage(1);
            }}
            className="w-full border rounded-xl px-4 py-2.5 outline-none text-sm bg-transparent focus:ring-2 focus:ring-blue-500/20 transition"
            style={{ borderColor: "var(--border)" }}
          >
            <option value="any">همه وضعیت‌ها</option>
            <option value="approved">تأیید شده</option>
            <option value="pending">در انتظار</option>
            <option value="spam">اسپم</option>
            <option value="trash">حذف شده</option>
          </select>
          <select
            value={postType}
            onChange={(e) => {
              setPostType(e.target.value);
              setPage(1);
            }}
            className="w-full border rounded-xl px-4 py-2.5 outline-none text-sm bg-transparent focus:ring-2 focus:ring-blue-500/20 transition"
            style={{ borderColor: "var(--border)" }}
          >
            <option value="all">همه نوع پست‌ها</option>
            <option value="product">محصولات</option>
            <option value="post">نوشته‌ها</option>
            <option value="page">برگه‌ها</option>
          </select>
          <div className="grid grid-cols-2 gap-2">
            <DatePicker
              value={dateFrom}
              onChange={(d) => setDateFrom(d ? d.toDate().toISOString() : "")}
              calendar={persian}
              locale={persian_fa}
              inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none bg-transparent"
              containerClassName="w-full"
              placeholder="از تاریخ"
            />
            <DatePicker
              value={dateTo}
              onChange={(d) => setDateTo(d ? d.toDate().toISOString() : "")}
              calendar={persian}
              locale={persian_fa}
              inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none bg-transparent"
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
              onChange={(e) => setPerPage(Number(e.target.value))}
              className="border rounded-lg px-2 py-1 text-sm outline-none bg-transparent"
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

      {/* ===== لیست نظرات ===== */}
      {loading && (
        <div className="flex justify-center py-8">
          <RefreshCw className="w-6 h-6 text-slate-400 animate-spin" />
        </div>
      )}

      {!loading && items.length === 0 && !error && (
        <div className="bg-white border rounded-2xl p-8 text-center text-sm" style={{ borderColor: "var(--border)", color: "var(--text-muted)" }}>
          <MessageSquare className="w-10 h-10 mx-auto text-slate-300 mb-2" />
          نظری یافت نشد
        </div>
      )}

      {!loading && items.length > 0 && (
        <div className="space-y-3">
          {items.map((item) => {
            const statusMeta = STATUS_LABELS[item.status] || {
              label: item.status,
              color: "bg-slate-100 text-slate-600",
              icon: MessageSquare,
            };
            const StatusIcon = statusMeta.icon;
            const PostIcon = POST_TYPE_ICONS[item.post_type] || FileText;

            return (
              <div
                key={item.id}
                className="bg-white border rounded-2xl p-4 hover:shadow-md transition-all duration-200"
                style={{ borderColor: "var(--border)" }}
              >
                <div className="flex flex-col gap-3">
                  {/* هدر */}
                  <div className="flex items-start justify-between gap-3">
                    <button
                      type="button"
                      onClick={() => openProfile(item)}
                      className="flex items-center gap-3 hover:bg-slate-50 p-1 rounded-lg transition text-left"
                    >
                      {item.author_avatar ? (
                        <img
                          src={item.author_avatar}
                          alt={item.author_name}
                          className="w-10 h-10 rounded-full object-cover shrink-0 border border-slate-200"
                        />
                      ) : (
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center text-blue-700 font-bold shrink-0">
                          {(item.author_name?.[0] || "؟").toUpperCase()}
                        </div>
                      )}
                      <div>
                        <div className="font-medium text-sm text-slate-800">
                          {item.author_name}
                        </div>
                        <div className="text-xs text-slate-400 flex items-center gap-1">
                          <Mail className="w-3 h-3" />
                          {item.author_email}
                        </div>
                      </div>
                    </button>
                    <span
                      className={`flex items-center gap-1 text-[11px] px-2 py-0.5 rounded-full shrink-0 ${statusMeta.color}`}
                    >
                      <StatusIcon className="w-3 h-3" />
                      {statusMeta.label}
                    </span>
                  </div>

                  {/* بخش "از کجا آمده" */}
                  <div className="bg-slate-50 rounded-xl p-3 text-xs text-slate-600 flex flex-wrap gap-2 items-center">
                    <PostIcon className="w-3.5 h-3.5 text-slate-400" />
                    <a
                      href={item.post_link}
                      target="_blank"
                      rel="noreferrer"
                      className="text-blue-600 font-medium hover:underline"
                    >
                      {item.post_title} ({item.post_type_label})
                    </a>
                    <span className="text-slate-300">|</span>
                    <span className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      {toFaDate(item.date)}
                    </span>
                  </div>

                  {/* محتوا */}
                  <div
                    className="text-sm text-slate-700 whitespace-pre-wrap bg-slate-50/50 rounded-xl p-3"
                    dangerouslySetInnerHTML={{ __html: item.content }}
                  />

                  {/* دکمه‌ها (با آیکون) */}
                  <div className="flex flex-wrap gap-2 pt-1 border-t" style={{ borderColor: "var(--border)" }}>
                    <button
                      onClick={() => openConversation(item)}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs bg-indigo-50 text-indigo-600 hover:bg-indigo-100 transition"
                    >
                      <Eye className="w-3.5 h-3.5" />
                      مشاهده مکالمه
                    </button>

                    {item.status !== "approved" && (
                      <button
                        onClick={() => updateStatus(item.id, "approved")}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition"
                      >
                        <CheckCircle className="w-3.5 h-3.5" />
                        تأیید
                      </button>
                    )}
                    {item.status === "approved" && (
                      <button
                        onClick={() => updateStatus(item.id, "pending")}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs bg-amber-50 text-amber-600 hover:bg-amber-100 transition"
                      >
                        <Clock className="w-3.5 h-3.5" />
                        معلق
                      </button>
                    )}
                    <button
                      onClick={() => updateStatus(item.id, "spam")}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs bg-red-50 text-red-600 hover:bg-red-100 transition"
                    >
                      <AlertCircle className="w-3.5 h-3.5" />
                      اسپم
                    </button>
                    <button
                      onClick={() => setDeleteItem(item)}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs bg-slate-100 text-slate-600 hover:bg-slate-200 transition"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      حذف
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* ===== صفحه‌بندی ===== */}
      <Pagination page={page} totalPages={totalPages} onChange={setPage} />

      {/* ================================================================ */}
      {/* ===== مودال مکالمه (نظرات تودرتو با آیکون) ===== */}
      {/* ================================================================ */}
      {conversationPostId !== null && (
        <div
          className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => {
            setConversationPostId(null);
            setConversationComments([]);
            setReplyTarget(null);
          }}
        >
          <div
            className="bg-white w-full max-w-3xl max-h-[90vh] rounded-2xl overflow-hidden flex flex-col shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            {/* هدر مودال */}
            <div className="flex items-center justify-between p-4 border-b shrink-0" style={{ borderColor: "var(--border)" }}>
              <div className="flex items-center gap-2">
                <MessageSquare className="w-5 h-5 text-blue-600" />
                <div>
                  <h3 className="font-bold text-lg">مکالمه</h3>
                  <p className="text-sm text-slate-500">{conversationPostTitle}</p>
                </div>
              </div>
              <button
                onClick={() => {
                  setConversationPostId(null);
                  setConversationComments([]);
                  setReplyTarget(null);
                }}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-full hover:bg-slate-100 transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* محتوای مودال */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              {conversationLoading && (
                <div className="flex justify-center py-8">
                  <RefreshCw className="w-6 h-6 text-slate-400 animate-spin" />
                </div>
              )}

              {conversationError && (
                <div className="rounded-xl px-4 py-3 text-sm text-white flex items-center gap-2" style={{ background: "var(--danger)" }}>
                  <AlertCircle className="w-4 h-4" />
                  {conversationError}
                </div>
              )}

              {!conversationLoading && !conversationError && conversationComments.length === 0 && (
                <div className="text-center text-slate-500 py-8">
                  <MessageSquare className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                  هیچ نظری برای این پست وجود ندارد.
                </div>
              )}

              {!conversationLoading &&
                conversationComments.length > 0 &&
                conversationComments.map((root) => (
                  <CommentThread
                    key={root.id}
                    comment={root}
                    depth={0}
                    onReply={setReplyTarget}
                  />
                ))}

              {/* فرم پاسخ */}
              {replyTarget && (
                <div className="bg-slate-50 rounded-2xl p-4 border mt-4" style={{ borderColor: "var(--border)" }}>
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-sm font-medium text-slate-700 flex items-center gap-2">
                      <Reply className="w-4 h-4 text-blue-600" />
                      پاسخ به {replyTarget.author_name}
                    </span>
                    <button
                      onClick={() => setReplyTarget(null)}
                      className="text-xs text-slate-400 hover:text-slate-600 flex items-center gap-1"
                    >
                      <X className="w-3.5 h-3.5" />
                      لغو
                    </button>
                  </div>
                  <div className="bg-white rounded-xl p-3 text-xs text-slate-500 mb-3 max-h-20 overflow-y-auto border" style={{ borderColor: "var(--border)" }}>
                    <div dangerouslySetInnerHTML={{ __html: replyTarget.content }} />
                  </div>
                  <textarea
                    value={replyContent}
                    onChange={(e) => setReplyContent(e.target.value)}
                    rows={3}
                    placeholder="متن پاسخ خود را بنویسید..."
                    className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500/20 transition bg-white"
                    style={{ borderColor: "var(--border)" }}
                  />
                  <button
                    onClick={submitReplyInModal}
                    disabled={replySaving || !replyContent.trim()}
                    className="w-full mt-2 py-2.5 rounded-xl text-sm text-white disabled:opacity-60 flex items-center justify-center gap-2 transition hover:shadow-md"
                    style={{ background: "var(--primary)" }}
                  >
                    {replySaving ? (
                      <>
                        <RefreshCw className="w-4 h-4 animate-spin" />
                        در حال ارسال...
                      </>
                    ) : (
                      <>
                        <Send className="w-4 h-4" />
                        ارسال پاسخ
                      </>
                    )}
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ===== مودال حذف ===== */}
      {deleteItem && (
        <div className="fixed inset-0 z-[60] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-sm rounded-2xl p-6 space-y-4 text-center shadow-2xl">
            <div className="text-4xl">🗑️</div>
            <h3 className="font-bold text-lg">حذف نظر</h3>
            <p className="text-sm text-slate-500">
              آیا از حذف نظر «{deleteItem.author_name}» مطمئن هستید؟
            </p>
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
                className="flex-1 py-2.5 rounded-xl text-sm border hover:bg-slate-50 transition"
                style={{ borderColor: "var(--border)" }}
              >
                انصراف
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ===== مودال پروفایل ===== */}
      {profileItem && (
        <div
          className="fixed inset-0 z-[70] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => setProfileItem(null)}
        >
          <div
            className="bg-white w-full max-w-md rounded-2xl p-6 space-y-4 shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg flex items-center gap-2">
                <User className="w-5 h-5 text-blue-600" />
                مشخصات کاربر
              </h3>
              <button
                onClick={() => setProfileItem(null)}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-full hover:bg-slate-100 transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {profileLoading ? (
              <div className="flex justify-center py-4">
                <RefreshCw className="w-6 h-6 text-slate-400 animate-spin" />
              </div>
            ) : userProfile ? (
              <>
                <div className="flex items-center gap-4">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center text-2xl font-bold text-blue-700">
                    {(userProfile.first_name?.[0] || userProfile.email?.[0] || "؟").toUpperCase()}
                  </div>
                  <div>
                    <div className="font-bold text-lg">
                      {userProfile.first_name} {userProfile.last_name}
                    </div>
                    <div className="text-sm text-slate-500 flex items-center gap-1">
                      <Mail className="w-3.5 h-3.5" />
                      {userProfile.email}
                    </div>
                  </div>
                </div>

                <div
                  className="grid grid-cols-2 gap-4 text-sm border-t pt-4"
                  style={{ borderColor: "var(--border)" }}
                >
                  <div>
                    <span className="text-slate-400">نقش:</span>
                    <div className="font-medium">
                      {userProfile.role === "customer"
                        ? "مشتری"
                        : userProfile.role === "subscriber"
                        ? "کاربر"
                        : "مهمان"}
                    </div>
                  </div>
                  <div>
                    <span className="text-slate-400">تلفن:</span>
                    <div className="font-medium">
                      {userProfile.billing?.phone || "ندارد"}
                    </div>
                  </div>
                  <div>
                    <span className="text-slate-400">مجموع خرید:</span>
                    <div className="font-medium">
                      {userProfile.total_spent
                        ? Number(userProfile.total_spent).toLocaleString("fa-IR") + " تومان"
                        : "—"}
                    </div>
                  </div>
                  <div>
                    <span className="text-slate-400">تاریخ عضویت:</span>
                    <div className="font-medium">
                      {userProfile.date_created ? toFaDate(userProfile.date_created) : "—"}
                    </div>
                  </div>
                </div>

                <div className="flex gap-2 pt-4 border-t" style={{ borderColor: "var(--border)" }}>
                  {userProfile.id > 0 && (
                    <a
                      href={`/users/${userProfile.id}`}
                      className="flex-1 text-center py-2 rounded-xl text-sm text-white transition hover:shadow-md"
                      style={{ background: "var(--primary)" }}
                    >
                      ویرایش کامل پروفایل
                    </a>
                  )}
                  <button
                    onClick={() => setProfileItem(null)}
                    className="flex-1 py-2 rounded-xl text-sm border hover:bg-slate-50 transition"
                    style={{ borderColor: "var(--border)" }}
                  >
                    بستن
                  </button>
                </div>
              </>
            ) : (
              <div className="text-center py-4 text-slate-500">
                اطلاعات کاربر یافت نشد (مهمان یا حذف شده)
              </div>
            )}
          </div>
        </div>
      )}
    </main>
  );
}