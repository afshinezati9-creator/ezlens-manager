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

export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/ei/v1/requests/${id}`, {
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "درخواست پیدا نشد", status: res.status, details: text.slice(0, 500) }, { status: res.status });
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
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/ei/v1/requests/${id}`, {
      method: "PUT",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify({ status: body.status }),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در تغییر وضعیت", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    return NextResponse.json({ ok: true });
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
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const res = await fetch(`${cfg.baseUrl}/wp-json/ei/v1/requests/${id}`, {
      method: "DELETE",
      headers: { Authorization: `Basic ${cfg.auth}` },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در حذف درخواست", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    return NextResponse.json({ ok: true });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}