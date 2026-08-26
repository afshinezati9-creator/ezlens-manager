import { NextResponse } from "next/server";

export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const baseUrl = process.env.WP_BASE_URL;
    if (!baseUrl) {
      return NextResponse.json({ error: "WP_BASE_URL تنظیم نشده" }, { status: 500 });
    }

    // ✅ دریافت مقاله با تمام متا فیلدها و تصاویر
    const url = new URL(`${baseUrl}/wp-json/wp/v2/posts/${id}`);
    url.searchParams.set("_embed", "1");

    const res = await fetch(url.toString(), {
      headers: {
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        {
          error: "خطا در دریافت مقاله",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    const post = await res.json();

    // ✅ استخراج داده‌ها
    const result: any = {
      id: post.id,
      title: post.title?.rendered || post.title || "",
      slug: post.slug || "",
      status: post.status || "draft",
      date: post.date ? new Date(post.date).toLocaleDateString("fa-IR") : "",
      modified: post.modified ? new Date(post.modified).toLocaleDateString("fa-IR") : "",
      content: post.content?.rendered || post.content || "",
      excerpt: post.excerpt?.rendered || post.excerpt || "",
      permalink: post.link || "",
    };

    // ✅ دریافت تصویر شاخص از _embedded
    if (post._embedded && post._embedded["wp:featuredmedia"] && post._embedded["wp:featuredmedia"][0]) {
      const media = post._embedded["wp:featuredmedia"][0];
      result.featured_image = {
        id: media.id,
        src: media.source_url || media.media_details?.sizes?.medium?.source_url || "",
        name: media.title?.rendered || media.slug || "",
      };
    } else {
      result.featured_image = null;
    }

    // ✅ دریافت دسته‌ها از _embedded
    if (post._embedded && post._embedded["wp:term"] && post._embedded["wp:term"][0]) {
      result.categories_data = post._embedded["wp:term"][0].map((cat: any) => ({
        id: cat.id,
        name: cat.name,
      }));
      result.categories = post._embedded["wp:term"][0].map((cat: any) => cat.id);
    } else {
      result.categories_data = [];
      result.categories = [];
    }

    // ✅ دریافت متا فیلدها (سئو و کدهای اختصاصی)
    const meta = post.meta || {};
    result.seo_title = meta.rank_math_title || "";
    result.seo_description = meta.rank_math_description || "";
    result.seo_keywords = meta.rank_math_focus_keyword || "";
    result.description_css = meta.ezlens_article_css || "";
    result.description_js = meta.ezlens_article_js || "";
    result.views = parseInt(meta.post_views_count) || 0;

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در دریافت مقاله",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const body = await request.json();

    const baseUrl = process.env.WP_BASE_URL;
    const username = process.env.WP_APP_USERNAME || "admin";
    const password = process.env.WP_APP_PASSWORD;

    if (!baseUrl || !password) {
      return NextResponse.json({ error: "تنظیمات وردپرس ناقص است" }, { status: 500 });
    }

    const auth = Buffer.from(`${username}:${password}`).toString("base64");

    const payload: any = {
      title: body.title,
      status: body.status,
      content: body.content_html || body.content || "",
      excerpt: body.excerpt || "",
      slug: body.slug || undefined,
      categories: Array.isArray(body.categories) ? body.categories : [],
      tags: Array.isArray(body.tags) ? body.tags : [],
      featured_media: body.featured_media || 0,
      meta: {
        ezlens_article_css: body.description_css || "",
        ezlens_article_js: body.description_js || "",
        rank_math_title: body.seo_title || "",
        rank_math_description: body.seo_description || "",
        rank_math_focus_keyword: body.seo_keywords || "",
      },
    };

    const res = await fetch(`${baseUrl}/wp-json/wp/v2/posts/${id}`, {
      method: "PUT",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        {
          error: "ویرایش مقاله ناموفق بود",
          status: res.status,
          details: text.slice(0, 800),
        },
        { status: res.status }
      );
    }

    const post = await res.json();

    // برگرداندن داده‌های به‌روز شده
    const result: any = {
      ok: true,
      id: post.id,
      title: post.title?.rendered || post.title || "",
      slug: post.slug || "",
      status: post.status || "draft",
      permalink: post.link || "",
    };

    // متا فیلدها
    const meta = post.meta || {};
    result.seo_title = meta.rank_math_title || "";
    result.seo_description = meta.rank_math_description || "";
    result.seo_keywords = meta.rank_math_focus_keyword || "";
    result.description_css = meta.ezlens_article_css || "";
    result.description_js = meta.ezlens_article_js || "";

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در ویرایش مقاله",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

export async function DELETE(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;

    const baseUrl = process.env.WP_BASE_URL;
    const username = process.env.WP_APP_USERNAME || "admin";
    const password = process.env.WP_APP_PASSWORD;

    if (!baseUrl || !password) {
      return NextResponse.json({ error: "تنظیمات وردپرس ناقص است" }, { status: 500 });
    }

    const auth = Buffer.from(`${username}:${password}`).toString("base64");

    const res = await fetch(`${baseUrl}/wp-json/wp/v2/posts/${id}?force=true`, {
      method: "DELETE",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        {
          error: "حذف مقاله ناموفق بود",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    return NextResponse.json({ ok: true, id: Number(id) });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در حذف مقاله",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}