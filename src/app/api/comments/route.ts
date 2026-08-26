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

function mapComment(item: any) {
  const embeddedPost = item._embedded?.["wp:post_type"]?.[0] || item._embedded?.up?.[0];
  const postType = embeddedPost?.type || "post";
  const postTitle = embeddedPost?.title?.rendered || `پست ${item.post}`;
  const postLink = embeddedPost?.link || "";

  const postTypeLabels: Record<string, string> = {
    post: "نوشته",
    page: "برگه",
    product: "محصول",
  };

  return {
    id: item.id,
    author: item.author || 0, // اینجا آی‌دی کاربر وردپرس را برمی‌گردانیم
    author_name: item.author_name || "ناشناس",
    author_email: item.author_email || "",
    author_url: item.author_url || "",
    author_avatar: item.author_avatar_urls?.["96"] || "",
    content: item.content?.rendered || "",
    date: item.date,
    status: item.status,
    link: item.link,
    post: item.post,
    post_title: postTitle,
    post_link: postLink,
    post_type: postType,
    post_type_label: postTypeLabels[postType] || postType,
    parent: item.parent || 0,
    ip: item.ip || "",
    user_agent: item.user_agent || "",
  };
}

export async function GET(request: Request) {
  try {
    const cfg = wpAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const { searchParams } = new URL(request.url);
    const page = searchParams.get("page") || "1";
    const perPage = searchParams.get("per_page") || "20";
    const search = searchParams.get("search") || "";
    const status = searchParams.get("status") || "any";
    const post = searchParams.get("post") || "";
    const after = searchParams.get("after") || "";
    const before = searchParams.get("before") || "";

    const url = new URL(`${cfg.baseUrl}/wp-json/wp/v2/comments`);
    url.searchParams.set("page", page);
    url.searchParams.set("per_page", perPage);
    url.searchParams.set("orderby", "date");
    url.searchParams.set("order", "desc");
    url.searchParams.set("_embed", "true");

    if (search) url.searchParams.set("search", search);
    if (status && status !== "any") url.searchParams.set("status", status);
    if (post) url.searchParams.set("post", post);
    if (after) url.searchParams.set("after", after);
    if (before) url.searchParams.set("before", before);

    const res = await fetch(url.toString(), {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "خطا در دریافت نظرات", status: res.status, details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    const data = await res.json();
    const total = res.headers.get("X-WP-Total");
    const totalPages = res.headers.get("X-WP-TotalPages");

    return NextResponse.json({
      items: Array.isArray(data) ? data.map(mapComment) : [],
      total: total ? Number(total) : 0,
      totalPages: totalPages ? Number(totalPages) : 1,
      page: Number(page),
    });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const cfg = wpAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const body = await request.json();
    const payload: any = {
      post: body.post || 0,
      content: body.content || "",
    };

    if (body.author_name) payload.author_name = body.author_name;
    if (body.author_email) payload.author_email = body.author_email;
    if (body.parent) payload.parent = body.parent;

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments`, {
      method: "POST",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "خطا در ایجاد نظر", status: res.status, details: text.slice(0, 500) },
        { status: res.status }
      );
    }

    return NextResponse.json(await res.json(), { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}