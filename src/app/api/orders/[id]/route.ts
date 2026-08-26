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

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/orders/${id}`;
    const res = await fetch(url, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت سفارش", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const order = await res.json();
    return NextResponse.json(order);
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
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const body = await request.json();
    
    // نکته: برای تغییر وضعیت، فقط status را ارسال می‌کنیم تا از تغییرات ناخواسته جلوگیری شود
    const payload: any = {};
    if (body.status) payload.status = body.status;
    if (body.customer_note !== undefined) payload.customer_note = body.customer_note;
    
    // اگر فیلدهای دیگری هم خواستی ویرایش کنی، اضافه کن
    // if (body.billing) payload.billing = body.billing;

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/orders/${id}`;
    const res = await fetch(url, {
      method: "PUT",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در ویرایش سفارش", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const order = await res.json();
    return NextResponse.json(order);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}