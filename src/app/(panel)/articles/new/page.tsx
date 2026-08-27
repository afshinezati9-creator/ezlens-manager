"use client";

import type { JSX } from "react";
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import CodeEditor from "@/components/ui/CodeEditor";
import UploadBox from "@/components/ui/UploadBox";

type CodeTab = "html" | "css" | "js";
type Item = { id: number; name: string; parent?: number };
type Img = { id: number; src: string; name: string; title?: string; size?: string };
type CategoryNode = Item & { children: CategoryNode[] };

export default function NewArticlePage() {
  const router = useRouter();

  const [title, setTitle] = useState("");
  const [slug, setSlug] = useState("");
  const [status, setStatus] = useState("draft");
  const [excerpt, setExcerpt] = useState("");

  const [categories, setCategories] = useState<Item[]>([]);
  const [selectedCats, setSelectedCats] = useState<number[]>([]);

  // State برای دسته جدید در مودال
  const [newCat, setNewCat] = useState("");
  const [newCatParent, setNewCatParent] = useState<number | 0>(0);

  const [htmlCode, setHtmlCode] = useState("<p>متن مقاله...</p>");
  const [cssCode, setCssCode] = useState("/* استایل اختصاصی مقاله */\n.article-title{font-weight:700;}");
  const [jsCode, setJsCode] = useState("// جاوااسکریپت اختصاصی مقاله");
  const [codeTab, setCodeTab] = useState<CodeTab>("html");

  const [seoTitle, setSeoTitle] = useState("");
  const [seoDescription, setSeoDescription] = useState("");
  const [seoKeywords, setSeoKeywords] = useState("");

  const [featuredImage, setFeaturedImage] = useState<Img | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // State‌های مودال
  const [catModalOpen, setCatModalOpen] = useState(false);
  const [expandedCats, setExpandedCats] = useState<Record<number, boolean>>({});
  const [showAddCatForm, setShowAddCatForm] = useState(false);

  // ✅ دریافت دسته‌های مقالات
  useEffect(() => {
    fetch("/api/post-categories")
      .then((r) => r.json())
      .then((data) => {
        setCategories(data.categories || []);
      })
      .catch(() => {});
  }, []);

  const categoryTree = useMemo((): CategoryNode[] => {
    const map = new Map<number, CategoryNode>();
    const roots: CategoryNode[] = [];
    categories.forEach((cat) => {
      map.set(cat.id, { ...cat, children: [] });
    });
    categories.forEach((cat) => {
      const node = map.get(cat.id)!;
      if (cat.parent && map.has(cat.parent)) {
        const parent = map.get(cat.parent)!;
        parent.children.push(node);
      } else {
        roots.push(node);
      }
    });
    return roots;
  }, [categories]);

  useEffect(() => {
    if (categories.length && Object.keys(expandedCats).length === 0) {
      const expanded: Record<number, boolean> = {};
      categories.forEach(c => { expanded[c.id] = true; });
      setExpandedCats(expanded);
    }
  }, [categories]);

  function toggleExpand(id: number) {
    setExpandedCats((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  function toggleId(list: number[], id: number, setter: (v: number[]) => void) {
    setter(list.includes(id) ? list.filter((x) => x !== id) : [...list, id]);
  }

  async function uploadFile(file: File): Promise<Img> {
    const fd = new FormData();
    fd.append("file", file);
    setUploading(true);
    setUploadProgress(20);
    const timer = setInterval(() => setUploadProgress((p) => (p < 90 ? p + 10 : p)), 120);
    try {
      const res = await fetch("/api/media", { method: "POST", body: fd });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "آپلود ناموفق");
      setUploadProgress(100);
      return {
        id: data.id,
        src: data.src,
        name: data.name,
        title: data.name,
        size: `${Math.max(1, Math.round(file.size / 1024))} KB`,
      };
    } finally {
      clearInterval(timer);
      setTimeout(() => {
        setUploading(false);
        setUploadProgress(0);
      }, 250);
    }
  }

  async function onFeaturedImage(files: FileList) {
    try {
      setError("");
      const img = await uploadFile(files[0]);
      setFeaturedImage(img);
      setMessage("تصویر شاخص آپلود شد");
    } catch (e: any) {
      setError(e?.message || "خطا در آپلود");
    }
  }

  function CategoryTreeItem({ node, level = 0 }: { node: CategoryNode; level?: number }) {
    const isExpanded = expandedCats[node.id] ?? true;
    const hasChildren = node.children.length > 0;
    const isChecked = selectedCats.includes(node.id);

    return (
      <div style={{ marginRight: level * 20 }}>
        <div className="flex items-center gap-2 py-1">
          {hasChildren && (
            <button
              type="button"
              onClick={() => toggleExpand(node.id)}
              className="text-xs w-5 h-5 flex items-center justify-center rounded hover:bg-gray-100"
            >
              {isExpanded ? "▼" : "▶"}
            </button>
          )}
          <label className="flex items-center gap-2 text-sm flex-1">
            <input
              type="checkbox"
              checked={isChecked}
              onChange={() => toggleId(selectedCats, node.id, setSelectedCats)}
            />
            <span className={hasChildren ? "font-medium" : ""}>{node.name}</span>
          </label>
        </div>
        {hasChildren && isExpanded && (
          <div className="mr-4">
            {node.children.map((child) => (
              <CategoryTreeItem key={child.id} node={child} level={level + 1} />
            ))}
          </div>
        )}
      </div>
    );
  }

  function renderCategoryOptions(nodes: CategoryNode[], level = 0): JSX.Element[] {
    const options: JSX.Element[] = [];
    nodes.forEach((node) => {
      const indent = "\u00A0".repeat(level * 4);
      options.push(
        <option key={node.id} value={node.id}>
          {indent}{node.name}
        </option>
      );
      if (node.children.length > 0) {
        options.push(...renderCategoryOptions(node.children, level + 1));
      }
    });
    return options;
  }

  async function save() {
    if (!title.trim()) {
      setError("عنوان مقاله الزامی است");
      return;
    }
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch("/api/articles", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title,
          slug,
          status,
          excerpt,
          content_html: htmlCode,
          description_css: cssCode,
          description_js: jsCode,
          categories: selectedCats,
          featured_media: featuredImage?.id || 0,
          seo_title: seoTitle,
          seo_description: seoDescription,
          seo_keywords: seoKeywords,
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ساخت مقاله ناموفق بود");
      setMessage("مقاله ساخته شد");
      router.push(`/articles/${data.id}`);
    } catch (e: any) {
      setError(e?.message || "خطا در ساخت مقاله");
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="p-4 space-y-4 pb-8">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>مقاله جدید</h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>فرم کامل مقاله</p>
        </div>
        <Link href="/articles" className="text-sm" style={{ color: "var(--secondary)" }}>بازگشت</Link>
      </div>

      {error && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--danger)" }}>{error}</div>}
      {message && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--success)" }}>{message}</div>}

      {/* تصویر شاخص */}
      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">تصویر شاخص</h3>
        <UploadBox label="آپلود تصویر شاخص مقاله" previewUrl={featuredImage?.src} onFiles={onFeaturedImage} />
        {featuredImage && (
          <div className="text-xs space-y-1" style={{ color: "var(--text-muted)" }}>
            <div>عنوان: {featuredImage.title || featuredImage.name}</div>
            <div className="break-all">لینک: {featuredImage.src}</div>
          </div>
        )}
      </section>

      {/* اطلاعات اصلی */}
      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">اطلاعات اصلی</h3>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="عنوان مقاله" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        <textarea value={excerpt} onChange={(e) => setExcerpt(e.target.value)} rows={2} placeholder="خلاصه مقاله" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        <div className="grid grid-cols-2 gap-3">
          <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }}>
            <option value="draft">پیش‌نویس</option>
            <option value="publish">انتشار</option>
            <option value="pending">در انتظار بررسی</option>
            <option value="private">خصوصی</option>
          </select>
          <input value={slug} onChange={(e) => setSlug(e.target.value)} placeholder="پیوند یکتا (اختیاری)" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)", direction: "ltr" }} />
        </div>
      </section>

      {/* دسته‌ها */}
      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <div className="flex items-center justify-between gap-2">
          <h3 className="font-bold text-sm">دسته‌ها</h3>
          <button
            type="button"
            onClick={() => setCatModalOpen(true)}
            className="px-3 py-1.5 rounded-lg text-xs text-white"
            style={{ background: "var(--primary)" }}
          >
            مدیریت دسته‌ها
          </button>
        </div>
        <div className="text-sm" style={{ color: "var(--text-muted)" }}>
          {selectedCats.length
            ? `${selectedCats.length.toLocaleString("fa-IR")} دسته انتخاب شده`
            : "هنوز دسته‌ای انتخاب نشده"}
        </div>
        {selectedCats.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {selectedCats.map((id) => {
              const c = categories.find((x) => x.id === id);
              return (
                <span key={id} className="text-xs px-2 py-1 rounded-full bg-slate-100 flex items-center gap-1">
                  <span style={{ color: "var(--success)" }}>✓</span>
                  {c?.name || id}
                </span>
              );
            })}
          </div>
        )}
      </section>

      {/* کد */}
      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">متن مقاله (HTML / CSS / JS)</h3>
        <p className="text-xs" style={{ color: "var(--text-muted)" }}>
          CSS/JS فقط برای همین مقاله ذخیره می‌شود و ایزوله است.
        </p>
        <div className="flex gap-2">
          {(["html", "css", "js"] as CodeTab[]).map((tab) => (
            <button key={tab} type="button" onClick={() => setCodeTab(tab)} className="px-3 py-1.5 rounded-lg text-xs"
              style={{ background: codeTab === tab ? "var(--primary)" : "#f1f5f9", color: codeTab === tab ? "#fff" : "var(--text-muted)" }}>
              {tab.toUpperCase()}
            </button>
          ))}
        </div>
        <div className="max-h-80 overflow-y-auto">
          {codeTab === "html" && <CodeEditor value={htmlCode} onChange={setHtmlCode} />}
          {codeTab === "css" && <CodeEditor value={cssCode} onChange={setCssCode} />}
          {codeTab === "js" && <CodeEditor value={jsCode} onChange={setJsCode} />}
        </div>
      </section>

      {/* سئو */}
      <section className="bg-white border rounded-2xl p-4 space-y-4" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">سئو (Rank Math)</h3>
        <div>
          <label className="text-sm font-medium block mb-1">عنوان سئو</label>
          <input value={seoTitle} onChange={(e) => setSeoTitle(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        </div>
        <div>
          <label className="text-sm font-medium block mb-1">توضیحات سئو</label>
          <textarea value={seoDescription} onChange={(e) => setSeoDescription(e.target.value)} rows={3} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        </div>
        <div>
          <label className="text-sm font-medium block mb-1">کلمات کلیدی</label>
          <input value={seoKeywords} onChange={(e) => setSeoKeywords(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        </div>
      </section>

      <button onClick={save} disabled={saving || uploading} className="w-full py-3 rounded-xl text-white text-sm disabled:opacity-60" style={{ background: "var(--primary)" }}>
        {saving ? "در حال ایجاد..." : "ایجاد مقاله در وردپرس"}
      </button>

      {/* مودال دسته‌ها */}
      {catModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white w-full max-w-lg rounded-2xl p-4 space-y-3 max-h-[85vh] overflow-auto">
            <div className="flex items-center justify-between">
              <h3 className="font-bold">مدیریت دسته‌ها</h3>
              <button onClick={() => setCatModalOpen(false)} className="text-sm text-gray-500 hover:text-gray-700">بستن</button>
            </div>

            <div className="border rounded-xl p-3 space-y-2 max-h-64 overflow-auto" style={{ borderColor: "var(--border)" }}>
              {categoryTree.length === 0 ? (
                <div className="text-sm text-gray-500">دسته‌ای وجود ندارد</div>
              ) : (
                categoryTree.map((root) => (
                  <CategoryTreeItem key={root.id} node={root} level={0} />
                ))
              )}
            </div>

            <div className="border-t pt-3" style={{ borderColor: "var(--border)" }}>
              <button
                type="button"
                onClick={() => setShowAddCatForm(!showAddCatForm)}
                className="text-sm text-blue-600 hover:underline"
              >
                {showAddCatForm ? "− بستن فرم" : "+ افزودن دسته جدید"}
              </button>

              {showAddCatForm && (
                <div className="mt-3 space-y-3">
                  <div>
                    <label className="block text-sm font-medium mb-1">نام دسته</label>
                    <input
                      value={newCat}
                      onChange={(e) => setNewCat(e.target.value)}
                      placeholder="نام دسته جدید"
                      className="w-full border rounded-xl px-3 py-2 text-sm outline-none"
                      style={{ borderColor: "var(--border)" }}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">دسته اصلی (والد)</label>
                    <select
                      value={newCatParent}
                      onChange={(e) => setNewCatParent(Number(e.target.value))}
                      className="w-full border rounded-xl px-3 py-2 text-sm outline-none"
                      style={{ borderColor: "var(--border)" }}
                    >
                      <option value={0}>— دسته اصلی —</option>
                      {renderCategoryOptions(categoryTree)}
                    </select>
                  </div>
                  <button
                    type="button"
                    onClick={async () => {
                      if (!newCat.trim()) return;
                      try {
                        const res = await fetch("/api/post-categories", {
                          method: "POST",
                          headers: { "Content-Type": "application/json" },
                          body: JSON.stringify({ name: newCat.trim(), parent: newCatParent || 0 }),
                        });
                        const data = await res.json();
                        if (!res.ok) throw new Error(data?.error || "ساخت دسته ناموفق");
                        setCategories((prev) => [...prev, data]);
                        setSelectedCats((prev) => [...prev, data.id]);
                        setNewCat("");
                        setNewCatParent(0);
                        setShowAddCatForm(false);
                        setMessage("دسته جدید اضافه شد");
                      } catch (e: any) {
                        setError(e?.message || "خطا در ساخت دسته");
                      }
                    }}
                    className="w-full py-2.5 rounded-xl text-sm text-white"
                    style={{ background: "var(--primary)" }}
                  >
                    افزودن دسته
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </main>
  );
}