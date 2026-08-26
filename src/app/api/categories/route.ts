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
    if ("error" in cfg) {
      console.error("❌ خطای تنظیمات:", cfg.error);
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    // ✅ per_page حداکثر ۱۰۰ است
    const url = `${cfg.baseUrl}/wp-json/wc/v3/products/categories?per_page=100&hide_empty=false&orderby=id&order=asc`;
    console.log("🔍 درخواست به:", url);

    const res = await fetch(url, {
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      console.error("❌ پاسخ ناموفق از ووکامرس:", res.status, text.slice(0, 300));
      return NextResponse.json(
        { error: "خطا در دریافت دسته‌ها", details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    const data = await res.json();
    console.log(`✅ تعداد دسته‌های دریافت شده: ${Array.isArray(data) ? data.length : '❌ داده آرایه نیست'}`);

    if (!Array.isArray(data)) {
      console.error("❌ داده دریافتی آرایه نیست:", typeof data, data);
      return NextResponse.json(
        { error: "ساختار داده نامعتبر", details: "داده دریافتی از ووکامرس آرایه نیست" },
        { status: 500 }
      );
    }

    const categories = data.map((c: any) => ({
      id: c.id,
      name: c.name,
      parent: c.parent || 0,
      slug: c.slug,
    }));

    return NextResponse.json({ categories });
  } catch (e: any) {
    console.error("❌ خطای سرور در GET /api/categories:", e?.message);
    return NextResponse.json(
      { error: "خطای سرور", details: e?.message || "unknown" },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const name = String(body?.name || "").trim();
    if (!name) {
      return NextResponse.json({ error: "نام دسته الزامی است" }, { status: 400 });
    }

    const cfg = wcAuth();
    if ("error" in cfg) {
      console.error("❌ خطای تنظیمات:", cfg.error);
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const payload = {
      name,
      parent: body.parent ? Number(body.parent) : 0,
    };
    console.log("📦 ارسال دسته جدید به ووکامرس:", payload);

    const res = await fetch(`${cfg.baseUrl}/wp-json/wc/v3/products/categories`, {
      method: "POST",
      headers: {
        Authorization: `Basic ${cfg.auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      console.error("❌ خطا در ساخت دسته:", res.status, text.slice(0, 300));
      return NextResponse.json(
        { error: "ساخت دسته ناموفق بود", details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    const c = await res.json();
    console.log("✅ دسته ساخته شد:", c);
    return NextResponse.json({ id: c.id, name: c.name, parent: c.parent || 0, slug: c.slug });
  } catch (e: any) {
    console.error("❌ خطای سرور در POST /api/categories:", e?.message);
    return NextResponse.json(
      { error: "خطای سرور", details: e?.message || "unknown" },
      { status: 500 }
    );
  }
}