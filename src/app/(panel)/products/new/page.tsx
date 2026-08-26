"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import CodeEditor from "@/components/ui/CodeEditor";
import UploadBox from "@/components/ui/UploadBox";

type CodeTab = "html" | "css" | "js";
type Item = { id: number; name: string; parent?: number };
type Img = { id: number; src: string; name: string; title?: string; size?: string };

type CategoryNode = Item & { children: CategoryNode[] };

export default function NewProductPage() {
  const router = useRouter();

  const [title, setTitle] = useState("");
  const [slug, setSlug] = useState("");
  const [status, setStatus] = useState("draft");
  const [regularPrice, setRegularPrice] = useState("");
  const [salePrice, setSalePrice] = useState("");
  const [stock, setStock] = useState("");
  const [shortDescription, setShortDescription] = useState("");

  const [categories, setCategories] = useState<Item[]>([]);
  const [brands, setBrands] = useState<Item[]>([]);
  const [tags, setTags] = useState<Item[]>([]);

  const [selectedCats, setSelectedCats] = useState<number[]>([]);
  const [selectedBrands, setSelectedBrands] = useState<number[]>([]);
  const [selectedTags, setSelectedTags] = useState<number[]>([]);

  const [newCat, setNewCat] = useState("");
  const [newBrand, setNewBrand] = useState("");
  const [newTag, setNewTag] = useState("");

  const [htmlCode, setHtmlCode] = useState("<p>توضیحات محصول...</p>");
  const [cssCode, setCssCode] = useState("/* فقط روی همین محصول اثر می‌کند */\n.title{font-weight:700;}");
  const [jsCode, setJsCode] = useState("// JS محدود به باکس همین محصول");
  const [codeTab, setCodeTab] = useState<CodeTab>("html");

  const [seoTitle, setSeoTitle] = useState("");
  const [seoDescription, setSeoDescription] = useState("");
  const [seoKeywords, setSeoKeywords] = useState("");

  const [mainImage, setMainImage] = useState<Img | null>(null);
  const [gallery, setGallery] = useState<Img[]>([]);
  const [galleryOpen, setGalleryOpen] = useState(false);
  const [activeGallery, setActiveGallery] = useState<Img | null>(null);

  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // State‌های مودال و فرم
  const [catModalOpen, setCatModalOpen] = useState(false);
  const [galleryModalOpen, setGalleryModalOpen] = useState(false);
  const [newCatParent, setNewCatParent] = useState<number | 0>(0);
  const [expandedCats, setExpandedCats] = useState<Record<number, boolean>>({});
  const [showAddCatForm, setShowAddCatForm] = useState(false);

  // تابع پاک‌کننده خودکار پیام بعد از ۳ ثانیه
  useEffect(() => {
    if (message) {
      const timer = setTimeout(() => setMessage(""), 3000);
      return () => clearTimeout(timer);
    }
  }, [message]);

  useEffect(() => {
    Promise.all([
      fetch("/api/categories").then((r) => r.json()),
      fetch("/api/brands").then((r) => r.json()),
      fetch("/api/tags").then((r) => r.json()),
    ])
      .then(([c, b, t]) => {
        console.log("دسته‌ها دریافت شد:", c);
        setCategories(c.categories || []);
        setBrands(b.brands || []);
        setTags(t.tags || []);
        if (!c.categories || c.categories.length === 0) {
          setError("هیچ دسته‌ای از ووکامرس دریافت نشد. لطفاً API را بررسی کنید.");
        }
      })
      .catch((err) => {
        console.error("خطا در دریافت داده‌ها:", err);
        setError("خطا در دریافت اطلاعات از سرور");
      });
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

  async function createTerm(type: "categories" | "brands" | "tags", name: string) {
    const res = await fetch(`/api/${type}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data?.error || "ساخت مورد جدید ناموفق");
    return data as Item;
  }

  async function addCategory() {
    if (!newCat.trim()) return;
    try {
      const item = await createTerm("categories", newCat.trim());
      setCategories((prev) => [...prev, item]);
      setSelectedCats((prev) => [...prev, item.id]);
      setNewCat("");
      setMessage("دسته تشکیل شد");
      setTimeout(() => setMessage(""), 3000);
    } catch (e: any) {
      setError(e?.message || "خطا در ساخت دسته");
    }
  }

  async function addBrand() {
    if (!newBrand.trim()) return;
    try {
      const item = await createTerm("brands", newBrand.trim());
      setBrands((prev) => [...prev, item]);
      setSelectedBrands((prev) => [...prev, item.id]);
      setNewBrand("");
      setMessage("برند جدید اضافه شد");
    } catch (e: any) {
      setError(e?.message || "خطا در ساخت برند");
    }
  }

  async function addTag() {
    if (!newTag.trim()) return;
    try {
      const item = await createTerm("tags", newTag.trim());
      setTags((prev) => [...prev, item]);
      setSelectedTags((prev) => [...prev, item.id]);
      setNewTag("");
      setMessage("برچسب جدید اضافه شد");
    } catch (e: any) {
      setError(e?.message || "خطا در ساخت برچسب");
    }
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

      const res = await fetch("/api/products", {
        method: "POST",
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
      if (!res.ok) throw new Error(data?.error || "ساخت محصول ناموفق بود");
      setMessage("محصول ساخته شد");
      router.push(`/products/${data.id}`);
    } catch (e: any) {
      setError(e?.message || "خطا در ساخت محصول");
    } finally {
      setSaving(false);
    }
  }

  // کامپوننت بازگشتی برای درخت
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

  // تابع تولید گزینه‌های والد با تورفتگی
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

  return (
    <main className="p-4 space-y-4 pb-8">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>محصول جدید</h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>فرم کامل و واقعی</p>
        </div>
        <Link href="/products" className="text-sm" style={{ color: "var(--secondary)" }}>بازگشت</Link>
      </div>

      {error && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--danger)" }}>{error}</div>}
      {message && <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--success)" }}>{message}</div>}

      {/* ===== بخش تصویر اصلی + گالری ===== */}
      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">تصویر اصلی</h3>
        <UploadBox label="آپلود تصویر اصلی" previewUrl={mainImage?.src} onFiles={onMain} />
        {mainImage && (
          <div className="text-xs space-y-1" style={{ color: "var(--text-muted)" }}>
            <div>عنوان: {mainImage.title || mainImage.name}</div>
            <div className="break-all">لینک: {mainImage.src}</div>
          </div>
        )}

        {/* ===== گالری محصول (زیر عکس اصلی) ===== */}
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
          <input value={regularPrice} onChange={(e) => setRegularPrice(e.target.value)} placeholder="قیمت عادی" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
          <input value={salePrice} onChange={(e) => setSalePrice(e.target.value)} placeholder="قیمت ویژه" className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
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

      {/* ===== بخش دسته‌ها (با دکمه مدیریت) ===== */}
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
                <span key={id} className="text-xs px-2 py-1 rounded-full bg-slate-100">
                  {c?.name || id}
                </span>
              );
            })}
          </div>
        )}
      </section>

      {/* برندها */}
      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">برندها</h3>
        <div className="max-h-40 overflow-auto border rounded-xl p-3 space-y-2" style={{ borderColor: "var(--border)" }}>
          {brands.map((b) => (
            <label key={b.id} className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={selectedBrands.includes(b.id)} onChange={() => toggleId(selectedBrands, b.id, setSelectedBrands)} />
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

      {/* کد */}
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
        {codeTab === "html" && <CodeEditor value={htmlCode} onChange={setHtmlCode} />}
        {codeTab === "css" && <CodeEditor value={cssCode} onChange={setCssCode} />}
        {codeTab === "js" && <CodeEditor value={jsCode} onChange={setJsCode} />}
      </section>

      {/* سئو */}
      <section className="bg-white border rounded-2xl p-4 space-y-4" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">سئو (Rank Math)</h3>
        <div>
          <label className="text-sm font-medium block mb-1">۱) عنوان سئو</label>
          <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>حدود ۵۰ تا ۶۰ کاراکتر. مثال: خرید لنز هارد Boston XO2 | EzLens</p>
          <input value={seoTitle} onChange={(e) => setSeoTitle(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        </div>
        <div>
          <label className="text-sm font-medium block mb-1">۲) پیوند یکتا (Slug)</label>
          <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>انگلیسی، با خط تیره. مثال: boston-xo2-hard-lens</p>
          <input value={slug} onChange={(e) => setSlug(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)", direction: "ltr" }} />
        </div>
        <div>
          <label className="text-sm font-medium block mb-1">۳) توضیحات سئو</label>
          <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>حدود ۱۴۰ تا ۱۶۰ کاراکتر؛ فایده محصول را خلاصه بنویس.</p>
          <textarea value={seoDescription} onChange={(e) => setSeoDescription(e.target.value)} rows={3} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        </div>
        <div>
          <label className="text-sm font-medium block mb-1">۴) کلمات کلیدی</label>
          <p className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>کلمه اصلی + ۲-۳ کلمه مرتبط، با ویرگول.</p>
          <input value={seoKeywords} onChange={(e) => setSeoKeywords(e.target.value)} className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none" style={{ borderColor: "var(--border)" }} />
        </div>
      </section>

      <button onClick={save} disabled={saving || uploading} className="w-full py-3 rounded-xl text-white text-sm disabled:opacity-60" style={{ background: "var(--primary)" }}>
        {saving ? "در حال ایجاد..." : "ایجاد محصول در ووکامرس"}
      </button>

      {/* ===== مودال دسته‌ها ===== */}
      {catModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white w-full max-w-lg rounded-2xl p-4 space-y-3 max-h-[85vh] overflow-auto">
            <div className="flex items-center justify-between">
              <h3 className="font-bold">مدیریت دسته‌ها</h3>
              <button onClick={() => setCatModalOpen(false)} className="text-sm text-gray-500 hover:text-gray-700">بستن</button>
            </div>

            {/* لیست درختی */}
            <div className="border rounded-xl p-3 space-y-2 max-h-64 overflow-auto" style={{ borderColor: "var(--border)" }}>
              {categoryTree.length === 0 ? (
                <div className="text-sm text-gray-500">دسته‌ای وجود ندارد</div>
              ) : (
                categoryTree.map((root) => (
                  <CategoryTreeItem key={root.id} node={root} level={0} />
                ))
              )}
            </div>

            {/* افزودن دسته */}
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
                        setNewCat("");
                        setNewCatParent(0);
                        setShowAddCatForm(false);
                        setMessage("✅ دسته تشکیل شد"); // ✅ پیام جدید
                        setTimeout(() => setMessage(""), 3000); // پاک شدن خودکار
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

      {/* ===== مودال گالری ===== */}
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