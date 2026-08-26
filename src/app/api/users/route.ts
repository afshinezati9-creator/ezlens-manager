import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;
  if (!baseUrl || !key || !secret) return { error: "تنظیمات محیطی ووکامرس ناقص است" as const };
  const auth = Buffer.from(`${key}:${secret}`).toString("base64");
  return { baseUrl, auth };
}

export async function GET(request: Request) {
  try {
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search") || "";

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers?search=${search}&per_page=100&role=all`;
    const res = await fetch(url, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت کاربران", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    let customers = await res.json();
    // مخفی کردن مدیر اصلی
    customers = customers.filter((c: any) => c.email !== "info@ezlens.ir" && c.id !== 1);
    return NextResponse.json(customers);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const body = await request.json();

    // اعتبارسنجی
    if (!body.email) return NextResponse.json({ error: "ایمیل الزامی است" }, { status: 400 });
    if (!body.phone) return NextResponse.json({ error: "شماره موبایل الزامی است" }, { status: 400 });

    // نام کاربری = شماره موبایل
    const payload: any = {
      email: body.email,
      first_name: body.first_name || "",
      last_name: body.last_name || "",
      username: body.phone,
      role: body.role || "customer",
      billing: {
        first_name: body.first_name || "",
        last_name: body.last_name || "",
        phone: body.phone,
        address_1: body.billing?.address_1 || "",
        city: body.billing?.city || "",
        postcode: body.billing?.postcode || "",
      },
      shipping: body.shipping || {
        first_name: body.first_name || "",
        last_name: body.last_name || "",
        address_1: body.billing?.address_1 || "",
        city: body.billing?.city || "",
        postcode: body.billing?.postcode || "",
      },
    };

    if (body.password) payload.password = body.password;

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers`;
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      let errorMessage = "خطا در ایجاد کاربر";
      try {
        const errorData = JSON.parse(text);
        errorMessage = errorData?.message || errorMessage;
      } catch {}
      return NextResponse.json({ error: errorMessage, details: text.slice(0, 500) }, { status: res.status });
    }

    const customer = await res.json();
    return NextResponse.json(customer, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    if (id === "1") {
      return NextResponse.json({ error: "امکان حذف مدیر اصلی وجود ندارد" }, { status: 403 });
    }

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers/${id}?force=true`;
    const res = await fetch(url, {
      method: "DELETE",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در حذف کاربر", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    return NextResponse.json({ ok: true });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}