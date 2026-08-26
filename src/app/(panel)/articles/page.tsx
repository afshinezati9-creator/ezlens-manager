"use client";

import { useEffect, useMemo, useState, useRef, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Pagination from "@/components/ui/Pagination";

type Article = {
  id: number;
  title: string;
  status: string;
  date: string;
  modified: string;
  excerpt: string;
  categories: number[];
  categories_data?: { id: number; name: string }[];
  tags: number[];
  featured_media: number;
  featured_image?: { id: number; src: string; name: string };
  permalink: string;
  views: number;
  description_css: string;
  description_js: string;
  seo_title: string;
  seo_description: string;
  seo_keywords: string;
};

type Category = {
  id: number;
  name: string;
  parent?: number;
};

function StatusBadge({ status }: { status: string }) {
  const isPublish = status === "publish";
  const isDraft = status === "draft";
  let label = status;
  let bg = "#f1f5f9";
  let color = "#475569";

  if (isPublish) {
    label = "منتشر شده";
    bg = "#dcfce7";
    color = "#166534";
  } else if (isDraft) {
    label = "پیش‌نویس";
    bg = "#fef9c3";
    color = "#854d0e";
  }

  return (
    <span
      className="text-[11px] px-2 py-0.5 rounded-full"
      style={{ background: bg, color }}
    >
      {label}
    </span>
  );
}

export default function ArticlesPage() {
  const router = useRouter();
  const [articles, setArticles] = useState<Article[]>([]);
  const [q, setQ] = useState("");
  const [searchTerm, setSearchTerm] = useState("");
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [searching, setSearching] = useState(false);
  const [error, setError] = useState("");
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const [categoryFilter, setCategoryFilter] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [categories, setCategories] = useState<Category[]>([]);

  const debounceTimer = useRef<NodeJS.Timeout | null>(null);

  const handleSearchChange = useCallback((value: string) => {
    setQ(value);
    setSearching(true);

    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }

    debounceTimer.current = setTimeout(() => {
      setSearchTerm(value);
      setPage(1);
      setSearching(false);
    }, 500);
  }, []);

  // ✅ دریافت دسته‌های مقالات (از API اختصاصی)
  useEffect(() => {
    fetch("/api/post-categories")
      .then((res) => res.json())
      .then((data) => {
        if (data.categories) {
          setCategories(data.categories);
        }
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    let alive = true;

    async function load() {
      setLoading(true);
      setError("");
      try {
        const params = new URLSearchParams({
          page: String(page),
          per_page: String(perPage),
        });
        if (searchTerm.trim()) params.set("search", searchTerm.trim());
        if (categoryFilter) params.set("category", categoryFilter);
        if (statusFilter) params.set("status", statusFilter);

        const res = await fetch(`/api/articles?${params.toString()}`);
        const data = await res.json();

        if (!res.ok) {
          throw new Error(data?.error || "خطا در دریافت مقالات");
        }

        if (!alive) return;
        setArticles(data.articles || []);
        setTotal(data.total || 0);
        setTotalPages(data.totalPages || 1);
      } catch (e: any) {
        if (!alive) return;
        setError(e?.message || "خطای ناشناخته");
        setArticles([]);
      } finally {
        if (alive) setLoading(false);
      }
    }

    load();
    return () => {
      alive = false;
    };
  }, [page, searchTerm, categoryFilter, statusFilter, perPage]);

  const handleCategoryChange = (value: string) => {
    setCategoryFilter(value);
    setPage(1);
  };

  const handleStatusChange = (value: string) => {
    setStatusFilter(value);
    setPage(1);
  };

  const handlePerPageChange = (value: string) => {
    setPerPage(Number(value));
    setPage(1);
  };

  async function deleteArticle(id: number) {
    if (!confirm("آیا از حذف این مقاله مطمئن هستید؟")) return;

    setDeletingId(id);
    try {
      const res = await fetch(`/api/articles/${id}`, {
        method: "DELETE",
      });
      const data = await res.json();

      if (!res.ok) {
        throw new Error(data?.error || "حذف ناموفق بود");
      }

      setArticles((prev) => prev.filter((a) => a.id !== id));
      setTotal((prev) => prev - 1);

      if (articles.length === 1 && page > 1) {
        setPage(page - 1);
      }

      alert("مقاله با موفقیت حذف شد");
    } catch (e: any) {
      alert(e?.message || "خطا در حذف مقاله");
    } finally {
      setDeletingId(null);
    }
  }

  const getCategoryNames = (article: Article) => {
    if (article.categories_data && article.categories_data.length > 0) {
      return article.categories_data.map((c) => c.name).join(" · ");
    }
    return "بدون دسته";
  };

  return (
    <main className="p-4 space-y-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>
            مقالات
          </h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>
            {total.toLocaleString("fa-IR")} مورد از وردپرس
          </p>
        </div>
        <Link
          href="/articles/new"
          className="px-3 py-2 rounded-xl text-white text-sm"
          style={{ background: "var(--primary)" }}
        >
          + جدید
        </Link>
      </div>

      {/* پالت جستجو و فیلترها */}
      <div
        className="bg-white border rounded-2xl p-4 space-y-3"
        style={{ borderColor: "var(--border)" }}
      >
        <div className="flex flex-wrap gap-3 items-center">
          <div className="flex-1 min-w-[160px] relative">
            <input
              value={q}
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder="جستجوی مقاله..."
              className="w-full bg-white border rounded-xl px-3 py-2.5 outline-none text-sm pr-9"
              style={{ borderColor: "var(--border)" }}
            />
            <div className="absolute right-3 top-1/2 -translate-y-1/2">
              {searching ? (
                <div className="w-4 h-4 border-2 border-gray-300 border-t-blue-600 rounded-full animate-spin"></div>
              ) : (
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  style={{ color: "var(--text-muted)" }}
                >
                  <circle cx="11" cy="11" r="8" />
                  <path d="m21 21-4.3-4.3" />
                </svg>
              )}
            </div>
          </div>

          <div className="min-w-[140px]">
            <select
              value={categoryFilter}
              onChange={(e) => handleCategoryChange(e.target.value)}
              className="w-full bg-white border rounded-xl px-3 py-2.5 outline-none text-sm"
              style={{ borderColor: "var(--border)" }}
            >
              <option value="">همه دسته‌ها</option>
              {categories.map((cat) => (
                <option key={cat.id} value={String(cat.id)}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          <div className="min-w-[140px]">
            <select
              value={statusFilter}
              onChange={(e) => handleStatusChange(e.target.value)}
              className="w-full bg-white border rounded-xl px-3 py-2.5 outline-none text-sm"
              style={{ borderColor: "var(--border)" }}
            >
              <option value="">همه وضعیت‌ها</option>
              <option value="publish">منتشر شده</option>
              <option value="draft">پیش‌نویس</option>
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
          در حال دریافت از وردپرس...
        </div>
      )}

      {error && (
        <div
          className="rounded-xl px-3 py-2 text-sm text-white"
          style={{ background: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      <div className="space-y-3">
        {!loading && articles.length === 0 && !error && (
          <div
            className="bg-white border rounded-2xl p-6 text-center text-sm"
            style={{ borderColor: "var(--border)", color: "var(--text-muted)" }}
          >
            مقاله‌ای یافت نشد
          </div>
        )}

        {articles.map((a) => (
          <div
            key={a.id}
            className="bg-white border rounded-2xl p-4"
            style={{ borderColor: "var(--border)" }}
          >
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0 flex-1">
                <Link href={`/articles/${a.id}`}>
                  <h3 className="font-bold text-sm leading-6 hover:underline">
                    {a.title}
                  </h3>
                </Link>
                <p className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>
                  {getCategoryNames(a)}
                </p>
                <p className="text-xs" style={{ color: "var(--text-muted)" }}>
                  {a.date || "تاریخ نامشخص"} · 👁️ {a.views.toLocaleString("fa-IR")} بازدید
                </p>
                <div className="flex items-center gap-2 mt-2 flex-wrap">
                  <StatusBadge status={a.status} />
                </div>
              </div>

              {a.featured_image && (
                <div className="shrink-0">
                  <img
                    src={a.featured_image.src}
                    alt={a.featured_image.name}
                    className="w-16 h-16 object-cover rounded-lg"
                  />
                </div>
              )}
            </div>

            <div className="flex items-center justify-end gap-2 mt-3 pt-3 border-t" style={{ borderColor: "var(--border)" }}>
              <Link
                href={`/articles/${a.id}`}
                className="px-3 py-1.5 rounded-lg text-xs border"
                style={{ borderColor: "var(--border)" }}
              >
                ✏️ ویرایش
              </Link>
              <button
                type="button"
                onClick={() => deleteArticle(a.id)}
                disabled={deletingId === a.id}
                className="px-3 py-1.5 rounded-lg text-xs border"
                style={{
                  borderColor: "var(--border)",
                  color: "var(--danger)",
                  opacity: deletingId === a.id ? 0.5 : 1,
                }}
              >
                {deletingId === a.id ? "در حال حذف..." : "🗑️ حذف"}
              </button>
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