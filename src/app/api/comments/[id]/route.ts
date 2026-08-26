import { NextResponse } from "next/server";

function wpAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const username = process.env.WP_APP_USERNAME || process.env.WP_USERNAME;
  const appPassword = process.env.WP_APP_PASSWORD;
  if (!baseUrl || !username || !appPassword) {
    return { error: "تنظیمات وردپرس ناقص است" as const };
  }
  const auth = Buffer.from(`${username}:${appPassword}`).toString("base64");
  return { baseUrl, auth };
}

export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = wpAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments/${id}`, {
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "نظر پیدا نشد", status: res.status, details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    return NextResponse.json(await res.json());
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
    const cfg = wpAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const payload: any = {};
    if (typeof body.status === "string") payload.status = body.status; // approved, unapproved, spam, trash
    if (typeof body.content === "string") payload.content = body.content;

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments/${id}`, {
      method: "POST", // وردپرس برای آپدیت از POST استفاده می‌کند
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "ویرایش نظر ناموفق بود", status: res.status, details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    return NextResponse.json({ ok: true, comment: await res.json() });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function DELETE(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = wpAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments/${id}?force=true`, {
      method: "DELETE",
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "حذف نظر ناموفق بود", status: res.status, details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    return NextResponse.json({ ok: true, id: Number(id) });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}