import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const username = process.env.WP_APP_USERNAME || process.env.WP_USERNAME;
  const appPassword = process.env.WP_APP_PASSWORD;

  if (!baseUrl || !username || !appPassword) {
    return { error: "تنظیمات وردپرس ناقص است" as const };
  }

  const auth = Buffer.from(`${username}:${appPassword}`).toString("base64");
  return { baseUrl, auth };
}

export async function GET(request: Request) {
  try {
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    // دریافت همه درخواست‌ها از API پلاگین
    const res = await fetch(`${cfg.baseUrl}/wp-json/ei/v1/requests`, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت درخواست‌ها", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const requests = await res.json();
    
    // اگر پاسخ آرایه نبود، به آرایه خالی تبدیل کن
    const list = Array.isArray(requests) ? requests : [];
    
    return NextResponse.json({
      items: list,
      total: list.length,
    });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const body = await request.json();
    
    const res = await fetch(`${cfg.baseUrl}/wp-json/ei/v1/requests`, {
      method: "POST",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(body),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در ایجاد درخواست", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    return NextResponse.json(await res.json(), { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}