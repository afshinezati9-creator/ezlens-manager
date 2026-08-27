import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;
  if (!baseUrl || !key || !secret) return { error: "تنظیمات محیطی ووکامرس ناقص است" as const };
  const auth = Buffer.from(`${key}:${secret}`).toString("base64");
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

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers/${id}`;
    const res = await fetch(url, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت کاربر", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const customer = await res.json();
    return NextResponse.json(customer);
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

    const payload: any = {};
    if (body.first_name) payload.first_name = body.first_name;
    if (body.last_name) payload.last_name = body.last_name;
    if (body.email) payload.email = body.email;
    if (body.role) payload.role = body.role;
    if (body.password) payload.password = body.password;
    if (body.billing) payload.billing = body.billing;
    if (body.shipping) payload.shipping = body.shipping;
    if (body.meta_data) payload.meta_data = body.meta_data;
    
    if (body.avatar_url) {
      payload.meta_data = [
        ...(payload.meta_data || []),
        { key: "_ezlens_avatar_url", value: body.avatar_url }
      ];
    }

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers/${id}`;
    const res = await fetch(url, {
      method: "PUT",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در ویرایش کاربر", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const customer = await res.json();
    return NextResponse.json(customer);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}