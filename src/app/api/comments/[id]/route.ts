import { NextResponse } from "next/server";

// ============================================================
// ✅ احراز هویت وردپرس
// ============================================================
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

// ============================================================
// ✅ GET - دریافت یک نظر
// ============================================================
export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = wpAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments/${id}`, {
      headers: {
        Authorization: `Basic ${cfg.auth}`,
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        {
          error: "نظر یافت نشد",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    return NextResponse.json(await res.json());
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در دریافت نظر",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

// ============================================================
// ✅ PUT - ویرایش نظر (تغییر وضعیت یا محتوا)
// ============================================================
export async function PUT(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const cfg = wpAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const payload: any = {};

    // ✅ فقط فیلدهایی که ارسال شده‌اند را به‌روزرسانی کن
    if (body.status) {
      const validStatuses = ["approved", "pending", "spam", "trash"];
      if (!validStatuses.includes(body.status)) {
        return NextResponse.json(
          { error: `وضعیت نامعتبر. وضعیت‌های مجاز: ${validStatuses.join(", ")}` },
          { status: 400 }
        );
      }
      payload.status = body.status;
    }

    if (body.content) {
      payload.content = body.content;
    }

    if (Object.keys(payload).length === 0) {
      return NextResponse.json(
        { error: "حداقل یکی از فیلدهای status یا content باید ارسال شود." },
        { status: 400 }
      );
    }

    // ✅ وردپرس برای آپدیت از متد POST استفاده می‌کند
    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments/${id}`, {
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
        {
          error: "ویرایش نظر ناموفق بود",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    const comment = await res.json();
    return NextResponse.json({
      ok: true,
      id: comment.id,
      status: comment.status,
      message: "نظر با موفقیت ویرایش شد",
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در ویرایش نظر",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

// ============================================================
// ✅ DELETE - حذف نظر
// ============================================================
export async function DELETE(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const cfg = wpAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    // ✅ حذف دائمی با force=true
    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments/${id}?force=true`, {
      method: "DELETE",
      headers: {
        Authorization: `Basic ${cfg.auth}`,
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        {
          error: "حذف نظر ناموفق بود",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    return NextResponse.json({
      ok: true,
      id: Number(id),
      message: "نظر با موفقیت حذف شد",
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در حذف نظر",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}