"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import DatePicker from "react-multi-date-picker";
import persian from "react-date-object/calendars/persian";
import persian_fa from "react-date-object/locales/persian_fa";

type Customer = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  role: string;
  date_created: string;
  orders_count?: number;
  total_spent?: string;
  avatar_url?: string;
  billing?: { phone?: string; state?: string; company?: string };
};

const ROLE_LABELS: Record<string, string> = {
  administrator: "مدیر کل",
  shop_manager: "مدیر فروشگاه",
  customer: "مشتری",
  subscriber: "کاربر سایت",
  editor: "ویرایشگر",
  author: "نویسنده",
  contributor: "همکار",
  "": "بدون نقش",
};

function getRoleLabel(role: string) {
  return ROLE_LABELS[role] || role;
}

function formatPrice(price: string | number | null | undefined) {
  const n = Number(price || 0);
  if (!n) return "—";
  return n.toLocaleString("fa-IR") + " تومان";
}

function formatDate(dateString?: string) {
  if (!dateString) return "—";
  return new Intl.DateTimeFormat('fa-IR-u-ca-persian', {
    year: 'numeric', month: 'long', day: 'numeric'
  }).format(new Date(dateString));
}

export default function UsersPage() {
  const router = useRouter();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [perPage, setPerPage] = useState(10);

  const [viewUser, setViewUser] = useState<Customer | null>(null);
  const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);
  const [deletingId, setDeletingId] = useState<number | null>(null);

  useEffect(() => {
    const timer = setTimeout(async () => {
      setLoading(true);
      setError("");
      try {
        const res = await fetch(`/api/users?search=${search}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || "خطا در دریافت کاربران");
        setCustomers(data);
        setCurrentPage(1);
      } catch (e: any) {
        setError(e?.message || "خطا در دریافت کاربران");
      } finally {
        setLoading(false);
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [search]);

  const filteredCustomers = useMemo(() => {
    return customers.filter((c) => {
      if (roleFilter !== "all" && c.role !== roleFilter) return false;
      if (dateFrom || dateTo) {
        const created = new Date(c.date_created).getTime();
        if (dateFrom && created < new Date(dateFrom).getTime()) return false;
        if (dateTo && created > new Date(dateTo).setHours(23, 59, 59, 999)) return false;
      }
      return true;
    });
  }, [customers, roleFilter, dateFrom, dateTo]);

  const totalPages = Math.ceil(filteredCustomers.length / perPage);
  const displayedCustomers = filteredCustomers.slice((currentPage - 1) * perPage, currentPage * perPage);

  useEffect(() => {
    setCurrentPage(1);
  }, [roleFilter, dateFrom, dateTo, perPage]);

  async function handleDelete(id: number) {
    if (confirmDeleteId !== id) {
      setConfirmDeleteId(id);
      return;
    }
    setDeletingId(id);
    setError("");
    try {
      const res = await fetch(`/api/users/${id}`, { method: "DELETE" });
      if (!res.ok) throw new Error("خطا در حذف کاربر");
      setCustomers(prev => prev.filter(c => c.id !== id));
      setConfirmDeleteId(null);
      setViewUser(null);
    } catch (e: any) {
      setError(e?.message || "خطا در حذف");
    } finally {
      setDeletingId(null);
    }
  }

  if (loading && customers.length === 0) {
    return (
      <main className="max-w-6xl mx-auto p-6 space-y-4 animate-pulse">
        <div className="h-24 bg-slate-200 rounded-2xl"></div>
        <div className="h-40 bg-slate-200 rounded-2xl"></div>
        <div className="h-40 bg-slate-200 rounded-2xl"></div>
      </main>
    );
  }

  return (
    <main className="max-w-6xl mx-auto p-4 md:p-6 space-y-6 pb-12">
      {/* هدر */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <h1 className="text-2xl font-bold" style={{ color: "var(--primary)" }}>مخاطبین</h1>
        <Link href="/users/new" className="px-4 py-2 rounded-xl text-sm text-white text-center" style={{ background: "var(--primary)" }}>
          + افزودن مخاطب جدید
        </Link>
      </div>

      {/* پالت جامع فیلتر */}
      <div className="bg-white border rounded-2xl p-4 space-y-4" style={{ borderColor: "var(--border)", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="جستجوی نام، ایمیل..."
            className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-blue-500"
            style={{ borderColor: "var(--border)" }}
          />
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="w-full border rounded-xl px-4 py-2.5 text-sm outline-none bg-white"
            style={{ borderColor: "var(--border)" }}
          >
            <option value="all">همه نقش‌ها</option>
            <option value="customer">مشتری</option>
            <option value="subscriber">کاربر سایت</option>
            <option value="shop_manager">مدیر فروشگاه</option>
          </select>
          <div className="flex flex-col gap-1">
            <label className="text-xs text-slate-500 px-1">از تاریخ عضویت</label>
            <DatePicker
              value={dateFrom}
              onChange={(date) => setDateFrom(date ? date.toDate().toISOString().slice(0, 10) : "")}
              calendar={persian} locale={persian_fa} calendarPosition="bottom-right"
              inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none"
              containerClassName="w-full" format="YYYY/MM/DD" placeholder="انتخاب"
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs text-slate-500 px-1">تا تاریخ عضویت</label>
            <DatePicker
              value={dateTo}
              onChange={(date) => setDateTo(date ? date.toDate().toISOString().slice(0, 10) : "")}
              calendar={persian} locale={persian_fa} calendarPosition="bottom-right"
              inputClass="w-full border rounded-xl px-3 py-2 text-sm outline-none"
              containerClassName="w-full" format="YYYY/MM/DD" placeholder="انتخاب"
            />
          </div>
        </div>
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
          <span>تعداد کل: {filteredCustomers.length.toLocaleString("fa-IR")} نفر</span>
        </div>
      </div>

      {error && <div className="rounded-xl px-4 py-2.5 text-sm text-white" style={{ background: "var(--danger)" }}>{error}</div>}

      {/* لیست تک ستونه */}
      <div className="space-y-3">
        {displayedCustomers.length === 0 ? (
          <div className="bg-white border rounded-2xl p-10 text-center text-slate-500" style={{ borderColor: "var(--border)" }}>
            مخاطبی با این مشخصات یافت نشد
          </div>
        ) : (
          displayedCustomers.map((c) => (
            <div key={c.id} className="bg-white border rounded-2xl p-5 hover:shadow-md transition-shadow duration-200" style={{ borderColor: "var(--border)" }}>
              
              {/* بخش بالایی: عکس و نام */}
              <div className="flex items-center gap-4 mb-4">
                {c.avatar_url ? (
                  <img src={c.avatar_url} alt={c.email} className="w-14 h-14 rounded-full object-cover shrink-0" />
                ) : (
                  <div className="w-14 h-14 rounded-full bg-slate-100 flex items-center justify-center text-slate-600 text-2xl font-bold shrink-0">
                    {(c.first_name?.[0] || c.email?.[0] || "؟").toUpperCase()}
                  </div>
                )}
                <div className="min-w-0">
                  <div className="font-bold text-lg truncate">{c.first_name} {c.last_name}</div>
                  <div className="text-sm text-slate-500 truncate">{c.email}</div>
                  <span className="inline-block mt-1 px-2 py-0.5 rounded-full text-[11px] font-medium bg-slate-100 text-slate-700">
                    {getRoleLabel(c.role)}
                  </span>
                </div>
              </div>

              {/* بخش وسط: جزئیات با گرید مرتب و بدون سرریز */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3 bg-slate-50 rounded-xl p-4">
                <div className="min-w-0">
                  <div className="text-xs text-slate-400 mb-1">تاریخ عضویت</div>
                  <div className="font-medium text-sm truncate">{formatDate(c.date_created)}</div>
                </div>
                <div className="min-w-0">
                  <div className="text-xs text-slate-400 mb-1">تلفن</div>
                  <div className="font-medium text-sm truncate" dir="ltr">{c.billing?.phone || "—"}</div>
                </div>
                <div className="min-w-0">
                  <div className="text-xs text-slate-400 mb-1">مجموع خرید</div>
                  <div className="font-medium text-sm truncate">{formatPrice(c.total_spent)}</div>
                </div>
                <div className="min-w-0">
                  <div className="text-xs text-slate-400 mb-1">سفارش‌ها</div>
                  <div className="font-medium text-sm truncate">{c.orders_count || 0}</div>
                </div>
              </div>

              {/* بخش پایینی: سه دکمه با فاصله مناسب */}
              <div className="flex gap-2 mt-4">
                <button 
                  onClick={() => setViewUser(c)} 
                  className="flex-1 py-2.5 rounded-lg text-xs font-medium bg-blue-50 text-blue-600 hover:bg-blue-100 transition"
                >
                  👁️ مشاهده
                </button>
                <Link 
                  href={`/users/${c.id}`} 
                  className="flex-1 text-center py-2.5 rounded-lg text-xs font-medium bg-amber-50 text-amber-600 hover:bg-amber-100 transition"
                >
                  ✏️ ویرایش
                </Link>
                <button 
                  onClick={() => handleDelete(c.id)}
                  disabled={deletingId === c.id}
                  className={`flex-1 py-2.5 rounded-lg text-xs font-medium transition disabled:opacity-50 ${
                    confirmDeleteId === c.id 
                      ? "bg-red-600 text-white hover:bg-red-700" 
                      : "bg-red-50 text-red-600 hover:bg-red-100"
                  }`}
                >
                  {deletingId === c.id ? "..." : confirmDeleteId === c.id ? "مطمئنی؟ حذف" : "🗑️ حذف"}
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* صفحه‌بندی */}
      {totalPages > 1 && (
        <div className="flex justify-center gap-2 pt-6">
          <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1} className="px-4 py-2 rounded-lg border text-sm disabled:opacity-50 hover:bg-slate-50">قبلی</button>
          {Array.from({ length: totalPages }, (_, i) => i + 1).map((pageNum) => (
            <button
              key={pageNum}
              onClick={() => setCurrentPage(pageNum)}
              className={`w-10 h-10 rounded-lg text-sm font-medium transition ${currentPage === pageNum ? "text-white" : "border hover:bg-slate-50"}`}
              style={currentPage === pageNum ? { background: "var(--primary)" } : { borderColor: "var(--border)" }}
            >
              {pageNum.toLocaleString("fa-IR")}
            </button>
          ))}
          <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages} className="px-4 py-2 rounded-lg border text-sm disabled:opacity-50 hover:bg-slate-50">بعدی</button>
        </div>
      )}

      {/* مودال مشاهده */}
      {viewUser && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4" onClick={() => setViewUser(null)}>
          <div className="bg-white w-full max-w-md rounded-2xl p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg">مشخصات مخاطب</h3>
              <button onClick={() => setViewUser(null)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center text-2xl font-bold text-slate-600">
                {(viewUser.first_name?.[0] || viewUser.email?.[0] || "؟").toUpperCase()}
              </div>
              <div>
                <div className="font-bold">{viewUser.first_name} {viewUser.last_name}</div>
                <div className="text-sm text-slate-500">{viewUser.email}</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 text-sm border-t pt-4" style={{ borderColor: "var(--border)" }}>
              <div><span className="text-slate-400">نقش:</span><div className="font-medium">{getRoleLabel(viewUser.role)}</div></div>
              <div><span className="text-slate-400">تلفن:</span><div className="font-medium">{viewUser.billing?.phone || "—"}</div></div>
              <div><span className="text-slate-400">تاریخ عضویت:</span><div className="font-medium">{formatDate(viewUser.date_created)}</div></div>
              <div><span className="text-slate-400">مجموع خرید:</span><div className="font-medium">{formatPrice(viewUser.total_spent)}</div></div>
            </div>
            <div className="flex gap-2 pt-4 border-t" style={{ borderColor: "var(--border)" }}>
              <Link href={`/users/${viewUser.id}`} className="flex-1 text-center py-2 rounded-xl text-sm text-white" style={{ background: "var(--primary)" }}>ویرایش اطلاعات</Link>
              <button onClick={() => setViewUser(null)} className="flex-1 py-2 rounded-xl text-sm border" style={{ borderColor: "var(--border)" }}>بستن</button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}