"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";

type Order = {
  id: number;
  order_number: string;
  status: string;
  total: string;
  subtotal?: string;
  discount_total?: string;
  shipping_total?: string;
  total_tax?: string;
  date_created: string;
  date_paid?: string;
  payment_method_title?: string;
  transaction_id?: string;
  billing: {
    first_name: string;
    last_name: string;
    company?: string;
    address_1: string;
    address_2?: string;
    city: string;
    state?: string;
    postcode?: string;
    country: string;
    email: string;
    phone: string;
  };
  shipping: {
    first_name: string;
    last_name: string;
    address_1: string;
    address_2?: string;
    city: string;
    state?: string;
    postcode?: string;
    country: string;
  };
  line_items: {
    id: number;
    name: string;
    product_id: number;
    quantity: number;
    total: string;
    price: string;
    sku?: string;
    image?: { src: string };
  }[];
  meta_data?: { key: string; value: any }[];
  customer_note?: string;
};

// تایپ برای یادداشت‌های ووکامرس
type OrderNote = {
  id: number;
  author: string;
  date_created: string;
  note: string;
  customer_note: boolean; // false یعنی خصوصی
};

const STATUS_OPTIONS = [
  { value: "pending", label: "در انتظار", bg: "#fef9c3", color: "#854d0e", icon: "⏳" },
  { value: "processing", label: "در حال پردازش", bg: "#fef3c7", color: "#b45309", icon: "⚙️" },
  { value: "completed", label: "تکمیل شده", bg: "#dcfce7", color: "#166534", icon: "✅" },
  { value: "cancelled", label: "لغو شده", bg: "#fee2e2", color: "#991b1b", icon: "❌" },
  { value: "refunded", label: "بازگشت وجه", bg: "#f3e8ff", color: "#6b21a8", icon: "💰" },
  { value: "failed", label: "ناموفق", bg: "#fee2e2", color: "#991b1b", icon: "🚫" },
  { value: "on-hold", label: "در انتظار بررسی", bg: "#ffedd5", color: "#c2410c", icon: "⏸️" },
];

function StatusBadge({ status }: { status: string }) {
  const s = STATUS_OPTIONS.find((x) => x.value === status) || STATUS_OPTIONS[0];
  return (
    <span className="inline-flex items-center gap-1 text-[11px] px-2.5 py-1 rounded-full font-medium"
      style={{ background: s.bg, color: s.color }}>
      {s.icon} {s.label}
    </span>
  );
}

function formatPrice(price: string | number | null | undefined) {
  const n = Number(price || 0);
  if (!n) return "—";
  return n.toLocaleString("fa-IR") + " تومان";
}

function formatDate(dateString?: string) {
  if (!dateString) return "—";
  return new Date(dateString).toLocaleDateString("fa-IR", {
    year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
  });
}

export default function OrderDetailPage() {
  const params = useParams();
  const id = String(params.id || "");

  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [updating, setUpdating] = useState(false);
  const [message, setMessage] = useState("");

  // State برای یادداشت‌ها
  const [notes, setNotes] = useState<OrderNote[]>([]);
  const [newNote, setNewNote] = useState("");
  const [notesLoading, setNotesLoading] = useState(false);
  const [noteSubmitting, setNoteSubmitting] = useState(false);

  useEffect(() => {
    let alive = true;
    async function load() {
      if (!id) return;
      setLoading(true);
      try {
        const res = await fetch(`/api/orders/${id}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || "خطا در دریافت سفارش");
        if (!alive) return;
        setOrder(data);
      } catch (e: any) {
        setError(e?.message || "خطای ناشناخته");
      } finally {
        setLoading(false);
      }
    }
    load();
    return () => { alive = false; };
  }, [id]);

  // دریافت یادداشت‌ها
  useEffect(() => {
    if (!id) return;
    async function loadNotes() {
      setNotesLoading(true);
      try {
        const res = await fetch(`/api/orders/${id}/notes`);
        const data = await res.json();
        if (res.ok) {
          // فقط یادداشت‌های خصوصی (customer_note: false) را نمایش بده
          const privateNotes = data.filter((n: any) => n.customer_note === false);
          setNotes(privateNotes);
        }
      } catch {
        // خطای یادداشت‌ها نباید مانع نمایش سفارش شود
      } finally {
        setNotesLoading(false);
      }
    }
    loadNotes();
  }, [id]);

  async function updateStatus(newStatus: string) {
    if (!order || newStatus === order.status) return;
    setUpdating(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/orders/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "تغییر وضعیت ناموفق");
      setOrder({ ...order, status: newStatus });
      setMessage("وضعیت سفارش به‌روزرسانی شد");
    } catch (e: any) {
      setError(e?.message || "خطا در تغییر وضعیت");
    } finally {
      setUpdating(false);
    }
  }

  async function addNote() {
    if (!newNote.trim()) return;
    setNoteSubmitting(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`/api/orders/${id}/notes`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ note: newNote.trim() }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ثبت یادداشت ناموفق");
      
      // اضافه کردن یادداشت جدید به لیست
      setNotes(prev => [data, ...prev]);
      setNewNote("");
      setMessage("یادداشت داخلی ثبت شد");
    } catch (e: any) {
      setError(e?.message || "خطا در ثبت یادداشت");
    } finally {
      setNoteSubmitting(false);
    }
  }

  if (loading) {
    return (
      <main className="p-6 space-y-4 animate-pulse">
        <div className="h-8 bg-slate-200 rounded-xl w-1/3"></div>
        <div className="h-32 bg-slate-200 rounded-2xl"></div>
        <div className="h-64 bg-slate-200 rounded-2xl"></div>
      </main>
    );
  }

  if (error || !order) {
    return (
      <main className="p-6">
        <div className="rounded-xl px-4 py-3 text-sm text-white" style={{ background: "var(--danger)" }}>
          {error || "سفارش یافت نشد"}
        </div>
        <Link href="/orders" className="text-sm mt-4 inline-block hover:underline" style={{ color: "var(--secondary)" }}>
          بازگشت به لیست سفارشات
        </Link>
      </main>
    );
  }

  return (
    <main className="max-w-5xl mx-auto p-4 md:p-6 space-y-6 pb-12">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: "var(--primary)" }}>
            سفارش #{order.order_number || order.id}
          </h1>
          <p className="text-sm mt-1" style={{ color: "var(--text-muted)" }}>
            ثبت: {formatDate(order.date_created)} {order.date_paid ? `· پرداخت: ${formatDate(order.date_paid)}` : "· پرداخت نشده"}
          </p>
        </div>
        <Link href="/orders" className="text-sm font-medium hover:opacity-80" style={{ color: "var(--secondary)" }}>
          ← بازگشت به لیست
        </Link>
      </div>

      {/* Messages */}
      {error && <div className="rounded-xl px-4 py-2.5 text-sm text-white" style={{ background: "var(--danger)" }}>{error}</div>}
      {message && <div className="rounded-xl px-4 py-2.5 text-sm text-white" style={{ background: "var(--success)" }}>{message}</div>}

      {/* Status & Actions */}
      <section className="bg-white border rounded-2xl p-5 space-y-4" style={{ borderColor: "var(--border)", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-3">
            <span className="text-sm font-medium">وضعیت فعلی:</span>
            <StatusBadge status={order.status} />
          </div>
          <div className="flex gap-2">
            {order.status !== "completed" && (
              <button onClick={() => updateStatus("completed")} disabled={updating}
                className="px-3 py-1.5 rounded-lg text-xs text-white disabled:opacity-50" style={{ background: "#16a34a" }}>
                ✅ تکمیل سفارش
              </button>
            )}
            {order.status !== "cancelled" && (
              <button onClick={() => updateStatus("cancelled")} disabled={updating}
                className="px-3 py-1.5 rounded-lg text-xs text-white disabled:opacity-50" style={{ background: "#dc2626" }}>
                ❌ لغو سفارش
              </button>
            )}
          </div>
        </div>
        <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-center">
          <label className="text-sm font-medium">تغییر وضعیت:</label>
          <select
            value={order.status}
            onChange={(e) => updateStatus(e.target.value)}
            disabled={updating}
            className="w-full sm:w-auto border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
            style={{ borderColor: "var(--border)", background: "#f8fafc" }}
          >
            {STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
          {updating && <span className="text-xs" style={{ color: "var(--text-muted)" }}>در حال ذخیره...</span>}
        </div>
      </section>

      {/* Payment Section */}
      <section className="bg-white border rounded-2xl p-5" style={{ borderColor: "var(--border)" }}>
        <h2 className="font-bold text-sm mb-4 flex items-center gap-2">💳 اطلاعات پرداخت</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
          <div className="bg-slate-50 rounded-xl p-3">
            <div className="text-xs" style={{ color: "var(--text-muted)" }}>روش پرداخت</div>
            <div className="font-medium mt-1">{order.payment_method_title || "—"}</div>
          </div>
          <div className="bg-slate-50 rounded-xl p-3">
            <div className="text-xs" style={{ color: "var(--text-muted)" }}>کد تراکنش</div>
            <div className="font-medium mt-1 break-all" style={{ direction: "ltr", textAlign: "right" }}>
              {order.transaction_id || "—"}
            </div>
          </div>
          <div className="bg-slate-50 rounded-xl p-3">
            <div className="text-xs" style={{ color: "var(--text-muted)" }}>وضعیت پرداخت</div>
            <div className="font-medium mt-1">
              {order.date_paid ? "پرداخت شده ✅" : "در انتظار پرداخت ⏳"}
            </div>
          </div>
        </div>
        {order.status === "pending" && (
          <a href={`https://ezlens.ir/checkout/order-pay/${order.id}`} target="_blank" rel="noreferrer"
             className="mt-4 inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-white"
             style={{ background: "var(--primary)" }}>
            🔗 لینک پرداخت مستقیم
          </a>
        )}
      </section>

      {/* Customer & Shipping Info */}
      <section className="bg-white border rounded-2xl p-5 space-y-4" style={{ borderColor: "var(--border)" }}>
        <h2 className="font-bold text-sm flex items-center gap-2">👤 اطلاعات مشتری و آدرس‌ها</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="rounded-xl border border-slate-100 p-4">
            <div className="text-xs font-medium mb-2" style={{ color: "var(--text-muted)" }}>🛒 صورت‌حساب</div>
            <div className="space-y-1">
              <div className="font-bold text-sm">{order.billing?.first_name} {order.billing?.last_name}</div>
              <div className="text-sm">{order.billing?.phone || "—"}</div>
              <div className="text-sm break-all">{order.billing?.email || "—"}</div>
              <div className="text-xs pt-2 text-slate-600">
                {order.billing?.address_1}{order.billing?.address_2 ? `، ${order.billing.address_2}` : ""}
                <br/>{order.billing?.city} · {order.billing?.postcode}
              </div>
            </div>
          </div>
          
          <div className="rounded-xl border border-slate-100 p-4">
            <div className="text-xs font-medium mb-2" style={{ color: "var(--text-muted)" }}>📦 آدرس ارسال</div>
            <div className="space-y-1">
              <div className="font-bold text-sm">{order.shipping?.first_name} {order.shipping?.last_name}</div>
              <div className="text-sm">{order.shipping?.address_1}{order.shipping?.address_2 ? `، ${order.shipping.address_2}` : ""}</div>
              <div className="text-sm">{order.shipping?.city}</div>
              <div className="text-xs text-slate-600">کد پستی: {order.shipping?.postcode || "—"}</div>
            </div>
          </div>
        </div>
        
        {order.customer_note && (
          <div className="mt-2 p-3 rounded-xl bg-amber-50 border border-amber-100 text-sm">
            <span className="font-bold">یادداشت مشتری: </span>{order.customer_note}
          </div>
        )}
      </section>

      {/* Line Items */}
      <section className="bg-white border rounded-2xl p-5" style={{ borderColor: "var(--border)" }}>
        <h2 className="font-bold text-sm mb-4 flex items-center gap-2">📦 اقلام سفارش</h2>
        <div className="divide-y divide-slate-100">
          {order.line_items?.map((item) => (
            <div key={item.id} className="py-4 flex flex-col sm:flex-row items-start gap-4">
              <div className="w-16 h-16 rounded-xl bg-slate-100 overflow-hidden shrink-0">
                {item.image?.src ? (
                  <img src={item.image.src} alt={item.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-xs text-slate-400">بدون عکس</div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <Link href={`/products/${item.product_id}`} className="font-medium text-sm hover:underline" style={{ color: "var(--primary)" }}>
                  {item.name}
                </Link>
                {item.sku && <div className="text-xs mt-0.5 text-slate-500">SKU: {item.sku}</div>}
              </div>
              <div className="text-left shrink-0">
                <div className="text-xs text-slate-500">{item.quantity} × {formatPrice(item.price)}</div>
                <div className="font-bold text-sm mt-1" style={{ color: "var(--primary)" }}>{formatPrice(item.total)}</div>
              </div>
            </div>
          ))}
        </div>

        {/* Totals Breakdown */}
        <div className="mt-4 pt-4 border-t border-slate-200 space-y-2 text-sm">
          <div className="flex justify-between"><span>جمع جزء:</span><span>{formatPrice(order.subtotal)}</span></div>
          <div className="flex justify-between"><span>هزینه ارسال:</span><span>{formatPrice(order.shipping_total)}</span></div>
          <div className="flex justify-between"><span>مالیات:</span><span>{formatPrice(order.total_tax)}</span></div>
          {Number(order.discount_total) > 0 && (
            <div className="flex justify-between text-green-600"><span>تخفیف:</span><span>- {formatPrice(order.discount_total)}</span></div>
          )}
          <div className="flex justify-between text-base font-bold pt-2 border-t border-slate-200">
            <span>مبلغ نهایی:</span>
            <span style={{ color: "var(--primary)" }}>{formatPrice(order.total)}</span>
          </div>
        </div>
      </section>

      {/* Internal Notes (Order Notes) - اکنون کاملاً عملیاتی و خصوصی */}
      <section className="bg-white border rounded-2xl p-5" style={{ borderColor: "var(--border)" }}>
        <h2 className="font-bold text-sm mb-1 flex items-center gap-2">📝 یادداشت‌های داخلی</h2>
        <p className="text-xs text-slate-500 mb-4">
          این یادداشت‌ها خصوصی هستند و برای مشتری نمایش داده نمی‌شوند.
        </p>

        {/* لیست یادداشت‌ها */}
        <div className="space-y-3 mb-4 max-h-60 overflow-y-auto pr-1">
          {notesLoading && <div className="text-sm text-slate-400">در حال بارگذاری...</div>}
          {!notesLoading && notes.length === 0 && (
            <div className="text-sm text-slate-400">هنوز یادداشتی ثبت نشده است.</div>
          )}
          {notes.map((note) => (
            <div key={note.id} className="bg-slate-50 rounded-xl p-3 border border-slate-100">
              <div className="flex items-center justify-between mb-1">
                <span className="text-xs font-medium text-slate-600">{note.author}</span>
                <span className="text-[10px] text-slate-400">{formatDate(note.date_created)}</span>
              </div>
              <div className="text-sm text-slate-700">{note.note}</div>
            </div>
          ))}
        </div>

        {/* فرم افزودن یادداشت */}
        <div className="flex gap-2">
          <input
            value={newNote}
            onChange={(e) => setNewNote(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter" && !noteSubmitting) addNote(); }}
            placeholder="یادداشت داخلی جدید..."
            className="flex-1 border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
            style={{ borderColor: "var(--border)" }}
          />
          <button
            onClick={addNote}
            disabled={noteSubmitting || !newNote.trim()}
            className="px-4 py-2.5 rounded-xl text-sm text-white disabled:opacity-50 transition"
            style={{ background: "var(--primary)" }}
          >
            {noteSubmitting ? "در حال ثبت..." : "افزودن"}
          </button>
        </div>
      </section>
    </main>
  );
}