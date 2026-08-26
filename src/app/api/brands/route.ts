import { NextResponse } from "next/server";

function wpAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const username = process.env.WP_USERNAME;
  const appPassword = process.env.WP_APP_PASSWORD;
  if (!baseUrl || !username || !appPassword) return { error: "تنظیمات وردپرس ناقص است" as const };
  const auth = Buffer.from(`${username}:${appPassword}`).toString("base64");
  return { baseUrl, auth };
}

export async function GET() {
  try {
    const cfg = wpAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/product_brand?per_page=100&hide_empty=false`, {
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت برندها", details: text.slice(0, 500) }, { status: res.status });
    }

    const data = await res.json();
    const brands = (Array.isArray(data) ? data : []).map((b: any) => ({
      id: b.id,
      name: b.name,
      slug: b.slug,
      parent: b.parent || 0,
    }));

    return NextResponse.json({ brands });
  } catch (e: any) {
    return NextResponse.json({ error: "خطای سرور", details: e?.message || "unknown" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const name = String(body?.name || "").trim();
    if (!name) return NextResponse.json({ error: "نام برند الزامی است" }, { status: 400 });

    const cfg = wpAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/product_brand`, {
      method: "POST",
      headers: {
        Authorization: `Basic ${cfg.auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name,
        parent: body.parent ? Number(body.parent) : 0,
      }),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "ساخت برند ناموفق بود", details: text.slice(0, 500) }, { status: res.status });
    }

    const b = await res.json();
    return NextResponse.json({ id: b.id, name: b.name, slug: b.slug, parent: b.parent || 0 });
  } catch (e: any) {
    return NextResponse.json({ error: "خطای سرور", details: e?.message || "unknown" }, { status: 500 });
  }
}