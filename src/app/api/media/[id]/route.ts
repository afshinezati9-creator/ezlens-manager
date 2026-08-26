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

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/media/${id}`, {
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "رسانه پیدا نشد", status: res.status, details: text.slice(0, 500) },
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
    if (typeof body.title === "string") payload.title = body.title;
    if (typeof body.alt === "string") payload.alt_text = body.alt;

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/media/${id}`, {
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
      return NextResponse.json(
        { error: "ویرایش رسانه ناموفق بود", status: res.status, details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    return NextResponse.json({ ok: true, media: await res.json() });
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

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/media/${id}?force=true`, {
      method: "DELETE",
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "حذف ناموفق بود", status: res.status, details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    return NextResponse.json({ ok: true, id: Number(id) });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}