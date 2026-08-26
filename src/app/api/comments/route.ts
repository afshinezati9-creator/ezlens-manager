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
// ✅ نگاشت نظر از وردپرس به فرمت برنامه
// ============================================================
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
    author: item.author || 0,
    author_name: item.author_name || "ناشناس",
    author_email: item.author_email || "",
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

// ============================================================
// ✅ GET - دو حالت: لیست عمومی یا تودرتو (با post)
// ============================================================
export async function GET(request: Request) {
  try {
    const cfg = wpAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const { searchParams } = new URL(request.url);
    const postId = searchParams.get("post");

    // =========================================================
    // حالت اول: اگر post وجود دارد → نظرات تودرتو (مکالمه)
    // =========================================================
    if (postId) {
      const status = searchParams.get("status") || "any";
      const perPage = Number(searchParams.get("per_page")) || 100;

      const url = new URL(`${cfg.baseUrl}/wp-json/wp/v2/comments`);
      url.searchParams.set("post", postId);
      url.searchParams.set("per_page", String(perPage));
      url.searchParams.set("orderby", "date");
      url.searchParams.set("order", "asc");
      url.searchParams.set("_embed", "true");

      if (status !== "any") {
        url.searchParams.set("status", status);
      }

      const res = await fetch(url.toString(), {
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
            error: "خطا در دریافت نظرات از وردپرس",
            status: res.status,
            details: text.slice(0, 500),
          },
          { status: res.status }
        );
      }

      const data = await res.json();
      const allComments = Array.isArray(data) ? data.map(mapComment) : [];

      // ساخت درخت نظرات
      const commentMap = new Map<number, any>();
      const roots: any[] = [];

      allComments.forEach((c) => {
        commentMap.set(c.id, { ...c, children: [] });
      });

      allComments.forEach((c) => {
        const node = commentMap.get(c.id);
        if (c.parent && commentMap.has(c.parent)) {
          const parent = commentMap.get(c.parent);
          parent.children.push(node);
        } else {
          roots.push(node);
        }
      });

      // مرتب‌سازی فرزندان بر اساس تاریخ
      function sortChildren(comments: any[]) {
        comments.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
        comments.forEach((c) => {
          if (c.children && c.children.length > 0) {
            sortChildren(c.children);
          }
        });
      }
      sortChildren(roots);

      return NextResponse.json({
        comments: roots,
        total: allComments.length,
        post_id: Number(postId),
        mode: "threaded",
      });
    }

    // =========================================================
    // حالت دوم: اگر post وجود ندارد → لیست عمومی (صفحه‌بندی شده)
    // =========================================================
    const page = searchParams.get("page") || "1";
    const perPage = searchParams.get("per_page") || "20";
    const search = searchParams.get("search") || "";
    const status = searchParams.get("status") || "any";
    const after = searchParams.get("after") || "";
    const before = searchParams.get("before") || "";

    const url = new URL(`${cfg.baseUrl}/wp-json/wp/v2/comments`);
    url.searchParams.set("page", page);
    url.searchParams.set("per_page", perPage);
    url.searchParams.set("orderby", "date");
    url.searchParams.set("order", "desc");
    url.searchParams.set("_embed", "true");

    if (search) url.searchParams.set("search", search);
    if (status !== "any") url.searchParams.set("status", status);
    if (after) url.searchParams.set("after", after);
    if (before) url.searchParams.set("before", before);

    const res = await fetch(url.toString(), {
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
          error: "خطا در دریافت نظرات",
          status: res.status,
          details: text.slice(0, 500),
        },
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
      mode: "list",
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در دریافت نظرات",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

// ============================================================
// ✅ POST - ایجاد نظر جدید (با پشتیبانی از parent)
// ============================================================
export async function POST(request: Request) {
  try {
    const cfg = wpAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const body = await request.json();

    if (!body.post || !body.content) {
      return NextResponse.json(
        { error: "پست (post) و محتوا (content) الزامی هستند." },
        { status: 400 }
      );
    }

    const payload: any = {
      post: Number(body.post),
      content: body.content,
      status: body.status || "approved",
    };

    if (body.author_name) payload.author_name = body.author_name;
    if (body.author_email) payload.author_email = body.author_email;
    if (body.author_url) payload.author_url = body.author_url;
    if (body.parent) payload.parent = Number(body.parent);

    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/comments`, {
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
          error: "خطا در ایجاد نظر",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    const comment = await res.json();
    return NextResponse.json(
      {
        ok: true,
        id: comment.id,
        message: "نظر با موفقیت ایجاد شد",
        comment: mapComment(comment),
      },
      { status: 201 }
    );
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در ایجاد نظر",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}