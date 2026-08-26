import { NextResponse } from "next/server";

export async function GET() {
  try {
    const baseUrl = process.env.WP_BASE_URL;
    if (!baseUrl) {
      return NextResponse.json({ error: "WP_BASE_URL تنظیم نشده" }, { status: 500 });
    }

    // ✅ درخواست عمومی بدون احراز هویت
    const url = `${baseUrl}/wp-json/wp/v2/categories?per_page=100&hide_empty=false&orderby=name&order=asc`;
    const res = await fetch(url, {
      headers: {
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        {
          error: "خطا در دریافت دسته‌بندی مقالات",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    const data = await res.json();
    const categories = (Array.isArray(data) ? data : []).map((c: any) => ({
      id: c.id,
      name: c.name,
      parent: c.parent || 0,
      slug: c.slug,
    }));

    return NextResponse.json({ categories });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در دریافت دسته‌بندی مقالات",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}