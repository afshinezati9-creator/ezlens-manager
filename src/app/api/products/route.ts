import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;

  if (!baseUrl || !key || !secret) {
    return { error: "تنظیمات محیطی ووکامرس ناقص است" as const };
  }

  const auth = Buffer.from(`${key}:${secret}`).toString("base64");
  return { baseUrl, auth };
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get("page") || "1";
    const perPage = searchParams.get("per_page") || "10";
    const search = searchParams.get("search") || "";
    const category = searchParams.get("category") || "";
    const status = searchParams.get("status") || "";

    const cfg = getAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const url = new URL(`${cfg.baseUrl}/wp-json/wc/v3/products`);
    url.searchParams.set("page", page);
    url.searchParams.set("per_page", perPage);
    if (search) url.searchParams.set("search", search);
    if (category) url.searchParams.set("category", category);
    if (status) url.searchParams.set("status", status);

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
          error: "خطا در دریافت محصولات از ووکامرس",
          status: res.status,
          details: text.slice(0, 500),
        },
        { status: res.status }
      );
    }

    const data = await res.json();
    const total = res.headers.get("X-WP-Total");
    const totalPages = res.headers.get("X-WP-TotalPages");

    let isFirst = true;

    const products = (Array.isArray(data) ? data : []).map((p: any) => {
      // استخراج متا فیلدها
      const meta = Array.isArray(p.meta_data) ? p.meta_data : [];
      
      // ✅ لاگ کامل متا فیلدها برای اولین محصول (برای دیباگ)
      if (isFirst) {
        console.log("🔍 === متا فیلدهای محصول اول (برای شناسایی کلیدهای بازدید و فروش) ===");
        if (meta.length === 0) {
          console.log("⚠️ هیچ متا فیلدی برای این محصول وجود ندارد!");
        } else {
          meta.forEach((m: any) => {
            console.log(`  ${m.key}: ${typeof m.value === 'string' ? m.value.substring(0, 150) : JSON.stringify(m.value)}`);
          });
        }
        console.log("🔍 ================================================");
        isFirst = false;
      }

      const getMeta = (key: string) => {
        const found = meta.find((m: any) => m.key === key);
        return found ? found.value : "";
      };

      // ✅ جستجو در متا فیلدها برای یافتن بازدید و فروش با کلیدهای مختلف
      let totalSales = 0;
      let views = 0;

      // کلیدهای احتمالی برای تعداد فروش
      const salesKeys = [
        "total_sales",           // ووکامرس پیش‌فرض (در بعضی نسخه‌ها)
        "_total_sales",          // برخی پلاگین‌ها
        "wc_total_sales",        // برخی پلاگین‌ها
        "order_count",           // برخی پلاگین‌ها
        "purchase_count",        // برخی پلاگین‌ها
      ];

      // کلیدهای احتمالی برای تعداد بازدید
      const viewsKeys = [
        "post_views_count",      // Rank Math / Jetpack
        "_post_views_count",     // برخی پلاگین‌ها
        "views",                 // برخی پلاگین‌ها
        "rank_math_post_views",  // Rank Math
        "wp_post_views",         // برخی پلاگین‌ها
        "total_views",           // برخی پلاگین‌ها
      ];

      for (const key of salesKeys) {
        const val = getMeta(key);
        if (val && Number(val) > 0) {
          totalSales = Number(val);
          break;
        }
      }

      for (const key of viewsKeys) {
        const val = getMeta(key);
        if (val && Number(val) > 0) {
          views = Number(val);
          break;
        }
      }

      return {
        id: p.id,
        title: p.name,
        status: p.status,
        price: p.price,
        regular_price: p.regular_price,
        sale_price: p.sale_price,
        stock: p.stock_quantity,
        sku: p.sku,
        categories: (p.categories || []).map((c: any) => c.name),
        permalink: p.permalink,
        total_sales: totalSales,
        views: views,
      };
    });

    return NextResponse.json({
      products,
      total: total ? Number(total) : products.length,
      totalPages: totalPages ? Number(totalPages) : 1,
      page: Number(page),
    });
  } catch (error: any) {
    console.error("❌ خطا در GET /api/products:", error?.message);
    return NextResponse.json(
      {
        error: "خطای سرور در ارتباط با ووکامرس",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const cfg = getAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    if (!body?.title || !String(body.title).trim()) {
      return NextResponse.json({ error: "عنوان محصول الزامی است" }, { status: 400 });
    }

    const payload: any = {
      name: String(body.title).trim(),
      type: "simple",
      status: body.status || "draft",
      regular_price: body.regular_price ? String(body.regular_price) : "",
      sale_price: body.sale_price ? String(body.sale_price) : "",
      short_description: body.short_description || "",
      description: body.description_html || body.description || "",
      slug: body.slug || undefined,
      categories: Array.isArray(body.categories)
        ? body.categories.map((id: number) => ({ id }))
        : [],
      brands: Array.isArray(body.brands)
        ? body.brands.map((id: number) => ({ id }))
        : [],
      tags: Array.isArray(body.tags)
        ? body.tags.filter(Boolean).map((name: string) => ({ name: String(name).trim() }))
        : [],
      images: Array.isArray(body.images)
        ? body.images.map((img: any) => ({ id: img.id }))
        : [],
      meta_data: [
        { key: "ezlens_brand", value: body.brands && body.brands.length > 0 ? body.brands.join(",") : "" },
        { key: "ezlens_desc_css", value: body.description_css || "" },
        { key: "ezlens_desc_js", value: body.description_js || "" },
        { key: "rank_math_title", value: body.seo_title || "" },
        { key: "rank_math_description", value: body.seo_description || "" },
        { key: "rank_math_focus_keyword", value: body.seo_keywords || "" },
      ],
    };

    if (body.stock !== undefined && body.stock !== null && body.stock !== "") {
      payload.manage_stock = true;
      payload.stock_quantity = Number(body.stock);
      payload.stock_status = Number(body.stock) > 0 ? "instock" : "outofstock";
    }

    const res = await fetch(`${cfg.baseUrl}/wp-json/wc/v3/products`, {
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
          error: "ساخت محصول ناموفق بود",
          status: res.status,
          details: text.slice(0, 800),
        },
        { status: res.status }
      );
    }

    const p = await res.json();
    return NextResponse.json({
      ok: true,
      id: p.id,
      title: p.name,
      status: p.status,
      permalink: p.permalink,
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        error: "خطای سرور در ساخت محصول",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    if (!id) {
      return NextResponse.json({ error: "شناسه محصول الزامی است" }, { status: 400 });
    }

    const cfg = getAuth();
    if ("error" in cfg) {
      return NextResponse.json({ error: cfg.error }, { status: 500 });
    }

    const res = await fetch(`${cfg.baseUrl}/wp-json/wc/v3/products/${id}`, {
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
          error: "حذف محصول ناموفق بود",
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
        error: "خطای سرور در حذف محصول",
        details: error?.message || "unknown",
      },
      { status: 500 }
    );
  }
}