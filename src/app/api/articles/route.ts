import { NextResponse } from "next/server";

function getWPAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const username =
    process.env.WP_USERNAME ||
    process.env.WP_APP_USERNAME ||
    "";
  const password = process.env.WP_APP_PASSWORD || "";

  if (!baseUrl || !username || !password) {
    return { error: "تنظیمات محیطی وردپرس ناقص است" as const };
  }

  const auth = Buffer.from(`${username}:${password}`).toString("base64");
  return { baseUrl, auth };
}

function mapArticle(post: any) {
  const meta = post.meta || {};
  const getMeta = (key: string) => {
    if (meta && typeof meta === "object" && !Array.isArray(meta)) {
      return meta[key] || "";
    }
    if (Array.isArray(meta)) {
      return meta.find((m: any) => m.key === key)?.value || "";
    }
    return "";
  };

  return {
    id: post.id,
    title: post.title?.rendered || post.title || "",
    slug: post.slug || "",
    status: post.status || "draft",
    date: post.date ? new Date(post.date).toLocaleDateString("fa-IR") : "",
    modified: post.modified ? new Date(post.modified).toLocaleDateString("fa-IR") : "",
    content: post.content?.rendered || post.content || "",
    excerpt: post.excerpt?.rendered || post.excerpt || "",
    categories: post.categories || [],
    tags: post.tags || [],
    featured_media: post.featured_media || 0,
    permalink: post.link || "",
    views: parseInt(String(getMeta("post_views_count") || "0")) || 0,
    description_css: getMeta("ezlens_article_css") || "",
    description_js: getMeta("ezlens_article_js") || "",
    seo_title: getMeta("rank_math_title") || "",
    seo_description: getMeta("rank_math_description") || "",
    seo_keywords: getMeta("rank_math_focus_keyword") || "",
  };
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get("page") || "1";
    const perPage = searchParams.get("per_page") || "10";
    const search = searchParams.get("search") || "";
    const category = searchParams.get("category") || "";
    const status = searchParams.get("status") || "";

    const baseUrl = process.env.WP_BASE_URL;
    if (!baseUrl) {
      return NextResponse.json({ error: "WP_BASE_URL تنظیم نشده" }, { status: 500 });
    }

    const url = new URL(`${baseUrl}/wp-json/wp/v2/posts`);
    url.searchParams.set("page", page);
    url.searchParams.set("per_page", perPage);
    url.searchParams.set("_embed", "1");
    if (search) url.searchParams.set("search", search);
    if (category) url.searchParams.set("categories", category);
    if (status) {
      url.searchParams.set("status", status);
    } else {
      url.searchParams.set("status", "any");
    }

    // برای status=any یا draft نیاز به auth داریم
    const cfg = getWPAuth();
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (!("error" in cfg)) {
      headers.Authorization = `Basic ${cfg.auth}`;
    }

    const res = await fetch(url.toString(), {
      headers,
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        {
          error: "خطا در دریافت مقالات از وردپرس",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    const data = await res.json();
    const total = res.headers.get("X-WP-Total");
    const totalPages = res.headers.get("X-WP-TotalPages");

    const articles = (Array.isArray(data) ? data : []).map((post: any) => {
      const mapped: any = mapArticle(post);

      if (post._embedded?.["wp:featuredmedia"]?.[0]) {
        const media = post._embedded["wp:featuredmedia"][0];
        mapped.featured_image = {
          id: media.id,
          src: media.source_url || media.media_details?.sizes?.medium?.source_url || "",
          name: media.title?.rendered || media.slug || "",
        };
      }

      if (post._embedded?.["wp:term"]?.[0]) {
        mapped.categories_data = post._embedded["wp:term"][0].map((cat: any) => ({
          id: cat.id,
          name: cat.name,
        }));
      }

      return mapped;
    });

    return NextResponse.json({
      articles,
      total: total ? Number(total) : articles.length,
      totalPages: totalPages ? Number(totalPages) : 1,
      page: Number(page),
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در ارتباط با وردپرس",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const cfg = getWPAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    if (!body?.title || !String(body.title).trim()) {
      return NextResponse.json({ error: "عنوان مقاله الزامی است" }, { status: 400 });
    }

    const payload: any = {
      title: String(body.title).trim(),
      status: body.status || "draft",
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

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/posts`, {
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
          error: "ساخت مقاله ناموفق بود",
          status: res.status,
          details: text.slice(0, 800),
        },
        { status: res.status }
      );
    }

    const post = await res.json();
    return NextResponse.json({
      ok: true,
      id: post.id,
      title: post.title?.rendered || post.title,
      status: post.status,
      permalink: post.link,
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در ساخت مقاله",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}