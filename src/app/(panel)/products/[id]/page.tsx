"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import CodeEditor from "@/components/ui/CodeEditor";
import UploadBox from "@/components/ui/UploadBox";

type CodeTab = "html" | "css" | "js";
type Item = { id: number; name: string; parent?: number };
type Img = { id: number; src: string; name: string; title?: string; size?: string };
type CategoryNode = Item & { children: CategoryNode[] };

function formatPrice(value: string | number | null | undefined) {
  const n = Number(value || 0);
  if (!n) return "—";
  return n.toLocaleString("fa-IR") + " تومان";
}

function numberToWords(num: number): string {
  if (num === 0) return "صفر";
  const units = ["", "یک", "دو", "سه", "چهار", "پنج", "شش", "هفت", "هشت", "نه"];
  const tens = ["", "ده", "بیست", "سی", "چهل", "پنجاه", "شصت", "هفتاد", "هشتاد", "نود"];
  const hundreds = ["", "صد", "دویست", "سیصد", "چهارصد", "پانصد", "ششصد", "هفتصد", "هشتصد", "نهصد"];
  const thousands = ["", "هزار", "میلیون", "میلیارد"];

  function convertLessThanThousand(n: number): string {
    if (n === 0) return "";
    let result = "";
    if (n >= 100) {
      result += hundreds[Math.floor(n / 100)];
      n %= 100;
      if (n > 0) result += " و ";
    }
    if (n >= 20) {
      result += tens[Math.floor(n / 10)];
      n %= 10;
      if (n > 0) result += " و " + units[n];
    } else if (n > 0) {
      result += units[n];
    }
    return result;
  }

  let parts = [];
  let index = 0;
  while (num > 0) {
    const chunk = num % 1000;
    if (chunk > 0) {
      const chunkText = convertLessThanThousand(chunk);
      parts.push(chunkText + (thousands[index] ? " " + thousands[index] : ""));
    }
    num = Math.floor(num / 1000);
    index++;
  }
  return parts.reverse().join(" و ");
}

export default function EditProductPage() {
  const router = useRouter();
  const params = useParams();
  const id = String(params.id || "");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [permalink, setPermalink] = useState("");

  // اطلاعات محصول
  const [title, setTitle] = useState("");
  const [slug, setSlug] = useState("");
  const [status, setStatus] = useState("draft");
  const [regularPrice, setRegularPrice] = useState("");
  const [salePrice, setSalePrice] = useState("");
  const [stock, setStock] = useState("");
  const [shortDescription, setShortDescription] = useState("");

  // دسته‌ها، برندها، برچسب‌ها
  const [categories, setCategories] = useState<Item[]>([]);
  const [brands, setBrands] = useState<Item[]>([]);
  const [tags, setTags] = useState<Item[]>([]);

  const [selectedCats, setSelectedCats] = useState<number[]>([]);
  const [selectedBrands, setSelectedBrands] = useState<number[]>([]);
  const [selectedTags, setSelectedTags] = useState<number[]>([]);

  // ✅ اسم دسته‌های انتخاب‌شده برای نمایش (از data.categories)
  const [selectedCatsNames, setSelectedCatsNames] = useState<string[]>([]);

  const [newCat, setNewCat] = useState("");
  const [newBrand, setNewBrand] = useState("");
  const [newTag, setNewTag] = useState("");

  // کدها
  const [htmlCode, setHtmlCode] = useState("");
  const [cssCode, setCssCode] = useState("");
  const [jsCode, setJsCode] = useState("");
  const [codeTab, setCodeTab] = useState<CodeTab>("html");

  // سئو
  const [seoTitle, setSeoTitle] = useState("");
  const [seoDescription, setSeoDescription] = useState("");
  const [seoKeywords, setSeoKeywords] = useState("");

  // تصاویر
  const [mainImage, setMainImage] = useState<Img | null>(null);
  const [gallery, setGallery] = useState<Img[]>([]);
  const [galleryOpen, setGalleryOpen] = useState(false);
  const [activeGallery, setActiveGallery] = useState<Img | null>(null);

  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  // State‌های مودال
  const [catModalOpen, setCatModalOpen] = useState(false);
  const [galleryModalOpen, setGalleryModalOpen] = useState(false);
  const [newCatParent, setNewCatParent] = useState<number | 0>(0);
  const [expandedCats, setExpandedCats] = useState<Record<number, boolean>>({});
  const [showAddCatForm, setShowAddCatForm] = useState(false);

  // دریافت دسته‌ها، برندها، برچسب‌ها
  useEffect(() => {
    Promise.all([
      fetch("/api/categories").then((r) => r.json()),
      fetch("/api/brands").then((r) => r.json()),
      fetch("/api/tags").then((r) => r.json()),
    ]).then(([c, b, t]) => {
      setCategories(c.categories || []);
      setBrands(b.brands || []);
      setTags(t.tags || []);
    }).catch(() => {});
  }, []);

  // دریافت اطلاعات محصول
  useEffect(() => {
    let alive = true;
    async function load() {
      if (!id) return;
      setLoading(true);
      setError("");
      try {
        const res = await fetch(`/api/products/${id}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data?.error || "خطا در دریافت محصول");
        if (!alive) return;

        setTitle(data.title || "");
        setSlug(data.slug || "");
        setStatus(data.status || "draft");
        setRegularPrice(data.regular_price ?? "");
        setSalePrice(data.sale_price ?? "");
        setStock(data.stock === null || data.stock === undefined ? "" : String(data.stock));
        setShortDescription(data.short_description || "");
        setHtmlCode(data.description || "");
        setCssCode(data.description_css || "");
        setJsCode(data.description_js || "");
        setSeoTitle(data.seo_title || "");
        setSeoDescription(data.seo_description || "");
        setSeoKeywords(data.seo_keywords || "");
        setPermalink(data.permalink || "");

        // ✅ دسته‌ها: ذخیره ID و نام
        if (data.categories && Array.isArray(data.categories)) {
          const catIds = data.categories.map((c: any) => c.id);
          const catNames = data.categories.map((c: any) => c.name);
          setSelectedCats(catIds);
          setSelectedCatsNames(catNames);
        }

        // ✅ برندها: اگر data.brand رشته است، آن را با brands تطابق بده
        if (data.brand) {
          const brandName = data.brand;
          const found = brands.find((b) => b.name === brandName);
          if (found) {
            setSelectedBrands([found.id]);
          } else {
            setSelectedBrands([]);
          }
        } else if (data.brands && Array.isArray(data.brands) && data.brands.length > 0) {
          setSelectedBrands(data.brands.map((b: any) => b.id));
        } else {
          setSelectedBrands([]);
        }

        // ✅ برچسب‌ها
        if (data.tags && Array.isArray(data.tags)) {
          const tagIds = data.tags
            .map((t: any) => {
              const found = tags.find((tag) => tag.name === (t.name || t));
              return found ? found.id : -1;
            })
            .filter((id: number) => id !== -1);
          setSelectedTags(tagIds);
        }

        // تصاویر
        const imgs: Img[] = (data.images || []).map((img: any) => ({
          id: img.id,
          src: img.src,
          name: img.name,
          title: img.name,
          size: img.size || "—",
        }));
        setMainImage(imgs[0] || null);
        setGallery(imgs.slice(1));
      } catch (e: any) {
        if (!alive) return;
        setError(e?.message || "خطای ناشناخته");
      } finally {
        if (alive) setLoading(false);
      }
    }
    load();
    return () => {
      alive = false;
    };
  }, [id, brands, tags]);

  // ساخت درخت دسته‌ها
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

  // باز کردن پیش‌فرض همه گره‌ها
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

  function removeGalleryImage(id: number) {
    setGallery((prev) => prev.filter((g) => g.id !== id));
  }

  async function onMain(files: FileList) {
    try {
      setError("");
      const img = await uploadFile(files[0]);
      setMainImage(img);
      setMessage("تصویر اصلی آپلود شد");
    } catch (e: any) {
      setError(e?.message || "خطا در آپلود");
    }
  }

  async function onGallery(files: FileList) {
    try {
      setError("");
      const arr: Img[] = [];
      for (const f of Array.from(files)) arr.push(await uploadFile(f));
      setGallery((prev) => [...prev, ...arr]);
      setMessage("گالری آپلود شد");
    } catch (e: any) {
      setError(e?.message || "خطا در آپلود گالری");
    }
  }

  async function addBrand() {
    if (!newBrand.trim()) return;
    try {
      const res = await fetch("/api/brands", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: newBrand.trim() }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ساخت برند ناموفق");
      setBrands((prev) => [...prev, data]);
      setSelectedBrands((prev) => [...prev, data.id]);
      setNewBrand("");
      setMessage("برند جدید اضافه شد");
    } catch (e: any) {
      setError(e?.message || "خطا در ساخت برند");
    }
  }

  async function addTag() {
    if (!newTag.trim()) return;
    try {
      const res = await fetch("/api/tags", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: newTag.trim() }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ساخت برچسب ناموفق");
      setTags((prev) => [...prev, data]);
      setSelectedTags((prev) => [...prev, data.id]);
      setNewTag("");
      setMessage("برچسب جدید اضافه شد");
    } catch (e: any) {
      setError(e?.message || "خطا در ساخت برچسب");
    }
  }

  // کامپوننت درختی
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

  // تابع تولید گزینه‌های والد
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
      setError("نام محصول الزامی است");
      return;
    }
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const images = [
        ...(mainImage ? [{ id: mainImage.id }] : []),
        ...gallery.map((g) => ({ id: g.id })),
      ];

      const res = await fetch(`/api/products/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title,
          slug,
          status,
          regular_price: regularPrice,
          sale_price: salePrice,
          stock,
          short_description: shortDescription,
          description_html: htmlCode,
          description_css: cssCode,
          description_js: jsCode,
          categories: selectedCats,
          brands: selectedBrands,
          tags: selectedTags.map((id) => tags.find((t) => t.id === id)?.name).filter(Boolean),
          images,
          seo_title: seoTitle,
          seo_description: seoDescription,
          seo_keywords: seoKeywords,
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "ذخیره ناموفق");
      setMessage("تغییرات در ووکامرس ذخیره شد");
      if (data.permalink) setPermalink(data.permalink);
    } catch (e: any) {
      setError(e?.message || "خطا در ذخیره");
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="p-4 space-y-4 pb-8">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>ویرایش محصول</h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>شناسه: {id}</p>
        </div>
        <Link href="/products" className="text-sm" style={{ color: "var(--secondary)" }}>بازگشت</Link>
      </div>

      {loading && <div className="text-sm" style={{ color: "var(--text-muted)" }}>در حال دریافت...</div>}
      {error && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--danger)" }}>{error}</div>}
      {message && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--success)" }}>{message}</div>}

      {!loading && (
        <>
          {/* بخش تصویر اصلی + گالری */}
          <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
            <h3 className="font-bold text-sm">تصویر اصلی</h3>
            <UploadBox label="آپلود تصویر اصلی" previewUrl={mainImage?.src} onFiles={onMain} />
            {mainImage && (
              <div className="text-xs space-y-1" style={{ color: "var(--text-muted)" }}>
                <div>عنوان: {mainImage.title || mainImage.name}</div>
                <div className="break-all">لینک: {mainImage.src}</div>
              </div>
            )}

            <div className="pt-3 border-t" style={{ borderColor: "var(--border)" }}>
              <div className="flex items-center justify-between gap-2">
                <h3 className="font-bold text-sm">گالری محصول</h3>
                <button
                  type="button"
                  onClick={() => setGalleryModalOpen(true)}
                  className="px-3 py-1.5 rounded-lg text-xs text-white"
                  style={{ background: "var(--primary)" }}
                >
                  مدیریت گالری
                </button>
              </div>
              <div className="text-sm" style={{ color: "var(--text-muted)" }}>
                {gallery.length
                  ? `${gallery.length.toLocaleString("fa-IR")} تصویر در گالری`
                  : "گالری خالی است"}
              </div>
              {gallery.length > 0 && (
                <div className="grid grid-cols-4 gap-2 mt-2">
                  {gallery.slice(0, 4).map((g) => (
                    <img key={g.id} src={g.src} alt={g.name} className="w-full h-16 object-cover rounded-lg" />
                  ))}
                </div>
              )}
            </div>
          </section>

          {/* اطلاعات اصلی */}
          <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
            <h3 className="font-bold text-sm">اطلاعات اصلی</h3>
            <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="نام محصول" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
            <textarea value={shortDescription} onChange={(e) => setShortDescription(e.target.value)} rows={3} placeholder="توضیح کوتاه" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
            <div className="grid grid-cols-2 gap-3">
              <div>
                <input
                  value={regularPrice}
                  onChange={(e) => setRegularPrice(e.target.value)}
                  placeholder="قیمت عادی"
                  className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none"
                  style={{ borderColor: "var(--border)" }}
                />
                {regularPrice && (
                  <div className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>
                    <div>{formatPrice(regularPrice)}</div>
                    <div className="text-[11px]">{numberToWords(Number(regularPrice))} تومان</div>
                  </div>
                )}
              </div>
              <div>
                <input
                  value={salePrice}
                  onChange={(e) => setSalePrice(e.target.value)}
                  placeholder="قیمت ویژه"
                  className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none"
                  style={{ borderColor: "var(--border)" }}
                />
                {salePrice && (
                  <div className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>
                    <div>{formatPrice(salePrice)}</div>
                    <div className="text-[11px]">{numberToWords(Number(salePrice))} تومان</div>
                  </div>
                )}
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <input value={stock} onChange={(e) => setStock(e.target.value)} placeholder="موجودی انبار" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
              <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }}>
                <option value="draft">پیش‌نویس</option>
                <option value="publish">انتشار</option>
                <option value="pending">در انتظار بررسی</option>
                <option value="private">خصوصی</option>
              </select>
            </div>
          </section>

          {/* ✅ دسته‌ها: نمایش اسم دسته‌های انتخاب‌شده و تیک */}
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
            {/* ✅ نمایش اسم دسته‌ها با تیک */}
            {selectedCatsNames.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {selectedCatsNames.map((name, index) => (
                  <span key={index} className="text-xs px-2 py-1 rounded-full bg-slate-100 flex items-center gap-1">
                    <span style={{ color: "var(--success)" }}>✓</span>
                    {name}
                  </span>
                ))}
              </div>
            )}
          </section>

          {/* ✅ برندها با نمایش اسم برند انتخاب‌شده و تیک */}
          <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
            <h3 className="font-bold text-sm">برندها</h3>
            {/* ✅ نمایش برند انتخاب‌شده */}
            {selectedBrands.length > 0 && (
              <div className="text-sm mb-2" style={{ color: "var(--primary)" }}>
                برند انتخاب‌شده:{" "}
                {selectedBrands.map((id) => {
                  const b = brands.find((x) => x.id === id);
                  return b ? b.name : id;
                }).join("، ")}
              </div>
            )}
            <div className="max-h-40 overflow-auto border rounded-xl p-3 space-y-2" style={{ borderColor: "var(--border)" }}>
              {brands.map((b) => (
                <label key={b.id} className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={selectedBrands.includes(b.id)}
                    onChange={() => toggleId(selectedBrands, b.id, setSelectedBrands)}
                  />
                  {b.name}
                </label>
              ))}
            </div>
            <div className="flex gap-2">
              <input value={newBrand} onChange={(e) => setNewBrand(e.target.value)} placeholder="برند جدید" className="flex-1 border rounded-xl px-3 py-2 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
              <button type="button" onClick={addBrand} className="px-3 py-2 rounded-xl text-sm text-white" style={{ background: "var(--primary)" }}>+ برند</button>
            </div>
          </section>

          {/* برچسب‌ها */}
          <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
            <h3 className="font-bold text-sm">برچسب‌ها</h3>
            <div className="max-h-40 overflow-auto border rounded-xl p-3 space-y-2" style={{ borderColor: "var(--border)" }}>
              {tags.map((t) => (
                <label key={t.id} className="flex items-center gap-2 text-sm">
                  <input type="checkbox" checked={selectedTags.includes(t.id)} onChange={() => toggleId(selectedTags, t.id, setSelectedTags)} />
                  {t.name}
                </label>
              ))}
            </div>
            <div className="flex gap-2">
              <input value={newTag} onChange={(e) => setNewTag(e.target.value)} placeholder="برچسب جدید" className="flex-1 border rounded-xl px-3 py-2 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
              <button type="button" onClick={addTag} className="px-3 py-2 rounded-xl text-sm text-white" style={{ background: "var(--primary)" }}>+ برچسب</button>
            </div>
          </section>

          {/* ✅ کد با ارتفاع بیشتر و اسکرول داخلی */}
          <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
            <h3 className="font-bold text-sm">توضیحات بلند (ایزوله)</h3>
            <p className="text-xs" style={{ color: "var(--text-muted)" }}>
              CSS/JS فقط برای همین محصول ذخیره می‌شود و نباید استایل کل سایت را هدف بگیرد.
            </p>
            <div className="flex gap-2">
              {(["html", "css", "js"] as CodeTab[]).map((tab) => (
                <button key={tab} type="button" onClick={() => setCodeTab(tab)} className="px-3 py-1.5 rounded-lg text-xs"
                  style={{ background: codeTab === tab ? "var(--primary)" : "#f1f5f9", color: codeTab === tab ? "#fff" : "var(--text-muted)" }}>
                  {tab.toUpperCase()}
                </button>
              ))}
            </div>
            {/* ✅ ارتفاع افزایش‌یافته: max-h-80 (320px) */}
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
              <label className="text-sm font-medium block mb-1">۱) عنوان سئو</label>
              <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>حدود ۵۰ تا ۶۰ کاراکتر</p>
              <input value={seoTitle} onChange={(e) => setSeoTitle(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
            </div>
            <div>
              <label className="text-sm font-medium block mb-1">۲) پیوند یکتا (Slug)</label>
              <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>انگلیسی، با خط تیره</p>
              <input value={slug} onChange={(e) => setSlug(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)", direction: "ltr" }} />
            </div>
            <div>
              <label className="text-sm font-medium block mb-1">۳) توضیحات سئو</label>
              <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>حدود ۱۴۰ تا ۱۶۰ کاراکتر</p>
              <textarea value={seoDescription} onChange={(e) => setSeoDescription(e.target.value)} rows={3} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
            </div>
            <div>
              <label className="text-sm font-medium block mb-1">۴) کلمات کلیدی</label>
              <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>کلمه اصلی + ۲-۳ کلمه مرتبط</p>
              <input value={seoKeywords} onChange={(e) => setSeoKeywords(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
            </div>
          </section>

          <button onClick={save} disabled={saving || uploading} className="w-full py-3 rounded-xl text-white text-sm disabled:opacity-60" style={{ background: "var(--primary)" }}>
            {saving ? "در حال ذخیره..." : "ذخیره در ووکامرس"}
          </button>

          {permalink && (
            <a href={permalink} target="_blank" rel="noreferrer" className="block text-center py-3 rounded-xl text-sm border" style={{ borderColor: "var(--border)" }}>
              🔗 مشاهده محصول در سایت
            </a>
          )}
        </>
      )}

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
                        const res = await fetch("/api/categories", {
                          method: "POST",
                          headers: { "Content-Type": "application/json" },
                          body: JSON.stringify({ name: newCat.trim(), parent: newCatParent || 0 }),
                        });
                        const data = await res.json();
                        if (!res.ok) throw new Error(data?.error || "ساخت دسته ناموفق");
                        setCategories((prev) => [...prev, data]);
                        setSelectedCats((prev) => [...prev, data.id]);
                        setSelectedCatsNames((prev) => [...prev, data.name]);
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

      {/* مودال گالری */}
      {galleryModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white w-full max-w-lg rounded-2xl p-4 space-y-3 max-h-[85vh] overflow-auto">
            <div className="flex items-center justify-between">
              <h3 className="font-bold">مدیریت گالری</h3>
              <button onClick={() => setGalleryModalOpen(false)} className="text-sm text-gray-500 hover:text-gray-700">بستن</button>
            </div>

            <UploadBox label="آپلود تصاویر گالری" multiple onFiles={onGallery} />

            {uploading && (
              <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                <div className="h-2 rounded-full" style={{ width: `${uploadProgress}%`, background: "var(--primary)" }} />
              </div>
            )}

            <div className="space-y-2">
              {gallery.length === 0 && (
                <div className="text-sm" style={{ color: "var(--text-muted)" }}>
                  هنوز تصویری آپلود نشده
                </div>
              )}
              {gallery.map((g) => (
                <div key={g.id} className="border rounded-xl p-3 flex gap-3 items-start" style={{ borderColor: "var(--border)" }}>
                  <img src={g.src} alt={g.name} className="w-16 h-16 object-cover rounded-lg" />
                  <div className="min-w-0 flex-1 space-y-1">
                    <input
                      value={g.title || ""}
                      onChange={(e) =>
                        setGallery((prev) =>
                          prev.map((x) => (x.id === g.id ? { ...x, title: e.target.value } : x))
                        )
                      }
                      placeholder="عنوان عکس"
                      className="w-full border rounded-lg px-2 py-1.5 text-xs outline-none"
                      style={{ borderColor: "var(--border)" }}
                    />
                    <div className="text-[11px]" style={{ color: "var(--text-muted)" }}>حجم: {g.size || "—"}</div>
                    <div className="text-[11px] break-all" style={{ color: "var(--text-muted)" }}>لینک: {g.src}</div>
                  </div>
                  <button
                    type="button"
                    onClick={() => removeGalleryImage(g.id)}
                    className="text-xs px-2 py-1 rounded-lg border"
                    style={{ borderColor: "var(--border)", color: "var(--danger)" }}
                  >
                    حذف
                  </button>
                </div>
              ))}
            </div>

            <button
              type="button"
              onClick={() => setGalleryModalOpen(false)}
              className="w-full py-2.5 rounded-xl text-sm text-white"
              style={{ background: "var(--primary)" }}
            >
              تأیید و بستن
            </button>
          </div>
        </div>
      )}

      {galleryOpen && activeGallery && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4" onClick={() => setGalleryOpen(false)}>
          <div className="bg-white w-full max-w-lg rounded-2xl p-4 space-y-3" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-sm">مشاهده تصویر گالری</h3>
              <button onClick={() => setGalleryOpen(false)} className="text-sm text-gray-500 hover:text-gray-700">بستن</button>
            </div>
            <img src={activeGallery.src} alt={activeGallery.name} className="w-full rounded-xl max-h-[50vh] object-contain bg-slate-50" />
            <div className="text-sm">عنوان: {activeGallery.title || activeGallery.name}</div>
            <div className="text-xs break-all" style={{ color: "var(--text-muted)" }}>لینک: {activeGallery.src}</div>
          </div>
        </div>
      )}
    </main>
  );
}