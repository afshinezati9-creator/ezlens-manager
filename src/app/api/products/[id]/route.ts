import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;
  if (!baseUrl || !key || !secret) return { error: "تنظیمات محیطی ووکامرس ناقص است" as const };
  const auth = Buffer.from(`${key}:${secret}`).toString("base64");
  return { baseUrl, auth };
}

function mapProduct(p: any) {
  const meta = Array.isArray(p.meta_data) ? p.meta_data : [];
  const getMeta = (key: string) => meta.find((m: any) => m.key === key)?.value || "";

  return {
    id: p.id,
    title: p.name,
    slug: p.slug,
    status: p.status,
    price: p.price,
    regular_price: p.regular_price,
    sale_price: p.sale_price,
    stock: p.stock_quantity,
    sku: p.sku,
    description: p.description,
    short_description: p.short_description,
    categories: (p.categories || []).map((c: any) => ({ id: c.id, name: c.name })),
    tags: (p.tags || []).map((t: any) => ({ id: t.id, name: t.name })),
    images: (p.images || []).map((img: any) => ({ id: img.id, src: img.src, name: img.name })),
    permalink: p.permalink,
    brand: getMeta("ezlens_brand"),
    description_css: getMeta("ezlens_desc_css"),
    description_js: getMeta("ezlens_desc_js"),
    seo_title: getMeta("rank_math_title"),
    seo_description: getMeta("rank_math_description"),
    seo_keywords: getMeta("rank_math_focus_keyword"),
  };
}

export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/wc/v3/products/${id}`, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت محصول", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const p = await res.json();
    return NextResponse.json(mapProduct(p));
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function PUT(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    // ساخت payload با پشتیبانی از brands و categories جدید
    const payload: any = {
      name: body.title,
      status: body.status,
      slug: body.slug || undefined,
      regular_price: body.regular_price ? String(body.regular_price) : "",
      sale_price: body.sale_price ? String(body.sale_price) : "",
      short_description: body.short_description || "",
      description: body.description_html || body.description || "",
      categories: Array.isArray(body.categories) ? body.categories.map((cid: number) => ({ id: cid })) : [],
      tags: Array.isArray(body.tags) ? body.tags.filter(Boolean).map((name: string) => ({ name: String(name).trim() })) : [],
      images: Array.isArray(body.images) ? body.images.map((img: any) => ({ id: img.id })) : undefined,
      meta_data: [
        { key: "ezlens_brand", value: body.brands && body.brands.length > 0 ? body.brands.join(",") : "" },
        { key: "ezlens_desc_css", value: body.description_css || "" },
        { key: "ezlens_desc_js", value: body.description_js || "" },
        { key: "rank_math_title", value: body.seo_title || "" },
        { key: "rank_math_description", value: body.seo_description || "" },
        { key: "rank_math_focus_keyword", value: body.seo_keywords || "" },
      ],
    };

    // مدیریت موجودی
    if (body.stock !== undefined && body.stock !== null && body.stock !== "") {
      payload.manage_stock = true;
      payload.stock_quantity = Number(body.stock);
      payload.stock_status = Number(body.stock) > 0 ? "instock" : "outofstock";
    }

    const res = await fetch(`${cfg.baseUrl}/wp-json/wc/v3/products/${id}`, {
      method: "PUT",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "ذخیره محصول ناموفق بود", status: res.status, details: text.slice(0, 800) }, { status: res.status });
    }

    const p = await res.json();
    return NextResponse.json({ ok: true, ...mapProduct(p) });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور در ذخیره", details: error?.message || "unknown" }, { status: 500 });
  }
}