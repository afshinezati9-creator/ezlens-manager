import { NextResponse } from "next/server";

function wcAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;
  if (!baseUrl || !key || !secret) return { error: "تنظیمات ووکامرس ناقص است" as const };
  const auth = Buffer.from(`${key}:${secret}`).toString("base64");
  return { baseUrl, auth };
}

export async function GET() {
  try {
    const cfg = wcAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/wc/v3/products/tags?per_page=100`, {
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت برچسب‌ها", details: text.slice(0, 500) }, { status: res.status });
    }

    const data = await res.json();
    const tags = (Array.isArray(data) ? data : []).map((t: any) => ({
      id: t.id,
      name: t.name,
      slug: t.slug,
    }));

    return NextResponse.json({ tags });
  } catch (e: any) {
    return NextResponse.json({ error: "خطای سرور", details: e?.message || "unknown" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const name = String(body?.name || "").trim();
    if (!name) return NextResponse.json({ error: "نام برچسب الزامی است" }, { status: 400 });

    const cfg = wcAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/wc/v3/products/tags`, {
      method: "POST",
      headers: {
        Authorization: `Basic ${cfg.auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name }),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "ساخت برچسب ناموفق بود", details: text.slice(0, 500) }, { status: res.status });
    }

    const t = await res.json();
    return NextResponse.json({ id: t.id, name: t.name, slug: t.slug });
  } catch (e: any) {
    return NextResponse.json({ error: "خطای سرور", details: e?.message || "unknown" }, { status: 500 });
  }
}