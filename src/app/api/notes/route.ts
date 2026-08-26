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

    const res = await fetch(`${cfg.baseUrl}/wp-json/ei/v1/notes`, {
      headers: {
        Authorization: `Basic ${cfg.auth}`,
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت یادداشت‌ها", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    // پلاگین وردپرس یک آبجکت برمی‌گرداند: { items: [...], total: ... }
    const data = await res.json();

    // اگر آبجکت است و items دارد، همان را برگردان
    if (data && typeof data === "object" && !Array.isArray(data) && data.items) {
      return NextResponse.json(data.items);
    }

    // اگر آرایه است، همان را برگردان
    return NextResponse.json(Array.isArray(data) ? data : []);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const body = await request.json();
    const payload = {
      title: body.title || "یادداشت جدید",
      content: body.content || "",
      color: body.color || "yellow",
      priority: body.priority || "low",
      checklist: body.checklist || [],
      files: body.files || [],
      pinned: body.pinned || false,
    };

    const res = await fetch(`${cfg.baseUrl}/wp-json/ei/v1/notes`, {
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
      return NextResponse.json({ error: "خطا در ایجاد یادداشت", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const note = await res.json();
    return NextResponse.json(note, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}