import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;
  if (!baseUrl || !key || !secret) return { error: "تنظیمات محیطی ووکامرس ناقص است" as const };
  const auth = Buffer.from(`${key}:${secret}`).toString("base64");
  return { baseUrl, auth };
}

// دریافت یادداشت‌های سفارش (GET)
export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/orders/${id}/notes`;
    const res = await fetch(url, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت یادداشت‌ها", status: res.status, details: text.slice(0, 300) }, { status: res.status });
    }

    const notes = await res.json();
    return NextResponse.json(notes);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

// افزودن یادداشت خصوصی (POST) - customer_note: false = برای مشتری ارسال نمیشه
export async function POST(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    // نکته: customer_note: false یعنی یادداشت خصوصی (برای مشتری ایمیل و نمایش داده نمیشه)
    const payload = {
      note: body.note || "",
      customer_note: false, // این خط مهمه: یادداشت خصوصی
    };

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/orders/${id}/notes`;
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در ثبت یادداشت", status: res.status, details: text.slice(0, 300) }, { status: res.status });
    }

    const note = await res.json();
    return NextResponse.json(note);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}