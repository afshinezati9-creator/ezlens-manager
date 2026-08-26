"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Pagination from "@/components/ui/Pagination";

type Order = {
  id: number;
  order_number: string;
  customer_name: string;
  total: string;
  status: string;
  date_created: string;
  payment_method_title: string;
  line_items: any[];
  billing: { first_name: string; last_name: string; email: string; phone: string; address_1: string; city: string };
  meta_data?: { key: string; value: any }[];
};

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, { label: string; bg: string; color: string }> = {
    pending: { label: "در انتظار", bg: "#fef9c3", color: "#854d0e" },
    processing: { label: "در حال پردازش", bg: "#fef3c7", color: "#b45309" },
    completed: { label: "تکمیل شده", bg: "#dcfce7", color: "#166534" },
    cancelled: { label: "لغو شده", bg: "#fee2e2", color: "#991b1b" },
    refunded: { label: "بازگشت وجه", bg: "#f3e8ff", color: "#6b21a8" },
    failed: { label: "ناموفق", bg: "#fee2e2", color: "#991b1b" },
    "on-hold": { label: "در انتظار", bg: "#fef9c3", color: "#854d0e" },
  };
  const s = map[status] || { label: status, bg: "#f1f5f9", color: "#475569" };
  return (
    <span className="text-[11px] px-2 py-0.5 rounded-full" style={{ background: s.bg, color: s.color }}>
      {s.label}
    </span>
  );
}

export default function OrdersPage() {
  const router = useRouter();
  const [orders, setOrders] = useState<Order[]>([]);
  const [q, setQ] = useState("");
  const [searchTerm, setSearchTerm] = useState("");
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [searching, setSearching] = useState(false);
  const [error, setError] = useState("");

  const [statusFilter, setStatusFilter] = useState<string>("");

  const debounceTimer = useRef<NodeJS.Timeout | null>(null);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const params = new URLSearchParams({
        page: String(page),
        per_page: String(perPage),
      });
      if (searchTerm.trim()) params.set("search", searchTerm.trim());
      if (statusFilter) params.set("status", statusFilter);

      const res = await fetch(`/api/orders?${params.toString()}`);
      const data = await res.json();

      if (!res.ok) throw new Error(data?.error || "خطا در دریافت سفارشات");

      setOrders(data.orders || []);
      setTotal(data.total || 0);
      setTotalPages(data.totalPages || 1);
    } catch (e: any) {
      setError(e?.message || "خطای ناشناخته");
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, [page, searchTerm, statusFilter, perPage]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  const handleSearchChange = useCallback((value: string) => {
    setQ(value);
    setSearching(true);

    if (debounceTimer.current) clearTimeout(debounceTimer.current);

    debounceTimer.current = setTimeout(() => {
      setSearchTerm(value);
      setPage(1);
      setSearching(false);
    }, 500);
  }, []);

  const handleStatusChange = (value: string) => {
    setStatusFilter(value);
    setPage(1);
  };

  const handlePerPageChange = (value: string) => {
    setPerPage(Number(value));
    setPage(1);
  };

  const formatPrice = (price: string | number) => {
    const n = Number(price || 0);
    if (!n) return "—";
    return n.toLocaleString("fa-IR") + " تومان";
  };

  return (
    <main className="p-4 space-y-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>سفارشات</h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>
            {total.toLocaleString("fa-IR")} سفارش از ووکامرس
          </p>
        </div>
      </div>

      {/* فیلترها */}
      <div className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <div className="flex flex-wrap gap-3 items-center">
          <div className="flex-1 min-w-[160px] relative">
            <input
              value={q}
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder="جستجوی سفارش (مشتری، شماره)..."
              className="w-full bg-white border rounded-xl px-3 py-2.5 outline-none text-sm pr-9"
              style={{ borderColor: "var(--border)" }}
            />
            <div className="absolute right-3 top-1/2 -translate-y-1/2">
              {searching ? (
                <div className="w-4 h-4 border-2 border-gray-300 border-t-blue-600 rounded-full animate-spin"></div>
              ) : (
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ color: "var(--text-muted)" }}>
                  <circle cx="11" cy="11" r="8" />
                  <path d="m21 21-4.3-4.3" />
                </svg>
              )}
            </div>
          </div>

          <div className="min-w-[140px]">
            <select
              value={statusFilter}
              onChange={(e) => handleStatusChange(e.target.value)}
              className="w-full bg-white border rounded-xl px-3 py-2.5 outline-none text-sm"
              style={{ borderColor: "var(--border)" }}
            >
              <option value="">همه وضعیت‌ها</option>
              <option value="pending">در انتظار</option>
              <option value="processing">در حال پردازش</option>
              <option value="completed">تکمیل شده</option>
              <option value="cancelled">لغو شده</option>
              <option value="refunded">بازگشت وجه</option>
              <option value="failed">ناموفق</option>
              <option value="on-hold">در انتظار</option>
            </select>
          </div>

          <div className="min-w-[120px]">
            <select
              value={perPage}
              onChange={(e) => handlePerPageChange(e.target.value)}
              className="w-full bg-white border rounded-xl px-3 py-2.5 outline-none text-sm"
              style={{ borderColor: "var(--border)" }}
            >
              <option value="10">۱۰ مورد</option>
              <option value="20">۲۰ مورد</option>
              <option value="50">۵۰ مورد</option>
              <option value="100">۱۰۰ مورد</option>
            </select>
          </div>
        </div>
      </div>

      {loading && (
        <div className="text-sm" style={{ color: "var(--text-muted)" }}>
          در حال دریافت از ووکامرس...
        </div>
      )}

      {error && (
        <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--danger)" }}>
          {error}
        </div>
      )}

      <div className="space-y-3">
        {!loading && orders.length === 0 && !error && (
          <div className="bg-white border rounded-2xl p-6 text-center text-sm" style={{ borderColor: "var(--border)", color: "var(--text-muted)" }}>
            سفارشی یافت نشد
          </div>
        )}

        {orders.map((order) => (
          <div
            key={order.id}
            className="bg-white border rounded-2xl p-4 cursor-pointer hover:border-primary transition-colors"
            style={{ borderColor: "var(--border)" }}
            onClick={() => router.push(`/orders/${order.id}`)}
          >
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0 flex-1">
                <h3 className="font-bold text-sm leading-6">
                  #{order.order_number || order.id} — {order.customer_name || (order.billing?.first_name + " " + order.billing?.last_name) || "مشتری"}
                </h3>
                <p className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>
                  {order.date_created ? new Date(order.date_created).toLocaleDateString("fa-IR") : "تاریخ نامشخص"} · {order.payment_method_title || "روش پرداخت نامشخص"}
                </p>
                <div className="flex items-center gap-2 mt-2 flex-wrap">
                  <StatusBadge status={order.status} />
                </div>
              </div>

              <div className="text-left shrink-0">
                <div className="text-sm font-bold" style={{ color: "var(--primary)" }}>
                  {formatPrice(order.total)}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="space-y-2">
        <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        <div className="text-center text-sm" style={{ color: "var(--text-muted)" }}>
          صفحه {page.toLocaleString("fa-IR")} از {totalPages.toLocaleString("fa-IR")}
        </div>
      </div>
    </main>
  );
}