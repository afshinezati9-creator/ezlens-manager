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

function mapMedia(item: any) {
  const mime = item.mime_type || "";
  const type = mime.startsWith("image/")
    ? "image"
    : mime.startsWith("video/")
      ? "video"
      : mime.startsWith("audio/")
        ? "audio"
        : "file";

  const bytes = Number(item.media_details?.filesize || 0);
  const sizeLabel =
    bytes > 1024 * 1024
      ? `${(bytes / (1024 * 1024)).toFixed(1)} MB`
      : bytes > 0
        ? `${Math.max(1, Math.round(bytes / 1024))} KB`
        : "—";

  return {
    id: item.id,
    title: item.title?.rendered || item.slug || `media-${item.id}`,
    alt: item.alt_text || "",
    caption: item.caption?.rendered || "",
    description: item.description?.rendered || "",
    mime,
    type,
    url: item.source_url,
    link: item.link,
    date: item.date,
    modified: item.modified,
    size: sizeLabel,
    bytes,
    width: item.media_details?.width || null,
    height: item.media_details?.height || null,
    author: item.author || null,
  };
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get("page") || "1";
    const perPage = searchParams.get("per_page") || "20";
    const search = searchParams.get("search") || "";
    const mediaType = searchParams.get("media_type") || "";
    const mime = searchParams.get("mime") || "";

    const cfg = wpAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const url = new URL(`${cfg.baseUrl}/wp-json/wp/v2/media`);
    url.searchParams.set("page", page);
    url.searchParams.set("per_page", perPage);
    url.searchParams.set("orderby", "date");
    url.searchParams.set("order", "desc");
    if (search) url.searchParams.set("search", search);
    if (mime) url.searchParams.set("media_type", mime);

    if (mediaType === "image") url.searchParams.set("media_type", "image");
    if (mediaType === "video") url.searchParams.set("media_type", "video");
    if (mediaType === "audio") url.searchParams.set("media_type", "audio");
    if (mediaType === "file") url.searchParams.set("media_type", "application");

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
          error: "خطا در دریافت رسانه‌ها",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    const data = await res.json();
    const total = res.headers.get("X-WP-Total");
    const totalPages = res.headers.get("X-WP-TotalPages");
    const items = (Array.isArray(data) ? data : []).map(mapMedia);

    return NextResponse.json({
      items,
      total: total ? Number(total) : items.length,
      totalPages: totalPages ? Number(totalPages) : 1,
      page: Number(page),
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "خطای سرور", details: error?.message || "unknown" },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const cfg = wpAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const form = await request.formData();
    const file = form.get("file");
    const title = String(form.get("title") || "");

    if (!(file instanceof File)) {
      return NextResponse.json({ error: "فایل ارسال نشده" }, { status: 400 });
    }

    const bytes = await file.arrayBuffer();
    const res = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/media`, {
      method: "POST",
      headers: {
        Authorization: `Basic ${cfg.auth}`,
        "Content-Disposition": `attachment; filename="${encodeURIComponent(file.name)}"`,
        "Content-Type": file.type || "application/octet-stream",
      },
      body: Buffer.from(bytes),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json(
        { error: "آپلود ناموفق بود", status: res.status, details: text.slice(0, 800) },
        { status: res.status }
      );
    }

    let item = await res.json();

    if (title.trim()) {
      const upd = await fetch(`${cfg.baseUrl}/wp-json/wp/v2/media/${item.id}`, {
        method: "POST",
        headers: {
          Authorization: `Basic ${cfg.auth}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ title: title.trim() }),
        cache: "no-store",
      });
      if (upd.ok) item = await upd.json();
    }

    return NextResponse.json(mapMedia(item));
  } catch (error: any) {
    return NextResponse.json(
      { error: "خطای سرور در آپلود", details: error?.message || "unknown" },
      { status: 500 }
    );
  }
}