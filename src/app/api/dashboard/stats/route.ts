import { NextResponse } from "next/server";

function getWooAuth() {
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;
  if (!key || !secret) return null;
  return Buffer.from(`${key}:${secret}`).toString("base64");
}

function getWpAuth() {
  const username = process.env.WP_APP_USERNAME || process.env.WP_USERNAME;
  const password = process.env.WP_APP_PASSWORD;
  if (!username || !password) return null;
  return Buffer.from(`${username}:${password}`).toString("base64");
}

export async function GET() {
  try {
    const wooAuth = getWooAuth();
    const wpAuth = getWpAuth();

    const stats = {
      products: 0,
      orders: 0,
      users: 0,
      media: 0,
      comments: 0,
      notes: 0,
      requests: 0,
      totalRevenue: 0,
      dailyRevenue: 0,
      monthlyRevenue: 0,
      visitsToday: 0,
      visitsMonth: 0,
      visitsAll: 0,
      latestProducts: [],
      latestOrders: [],
      latestNotes: [],
      latestPosts: [],
      mostViewedProducts: [],
      mostViewedPosts: [],
    };

    async function fetchCount(endpoint: string, auth: string | null) {
      if (!auth) return 0;
      try {
        const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/${endpoint}?per_page=1`, {
          headers: { Authorization: `Basic ${auth}` },
          cache: "no-store",
        });
        if (!res.ok) return 0;
        const total = res.headers.get("X-WP-Total");
        return total ? Number(total) : 0;
      } catch {
        return 0;
      }
    }

    const results = await Promise.allSettled([
      fetchCount("wc/v3/products", wooAuth),
      fetchCount("wc/v3/orders", wooAuth),
      fetchCount("wc/v3/customers?role=all", wooAuth),
      fetchCount("wp/v2/media", wpAuth),
      fetchCount("wp/v2/comments", wpAuth),

      (async () => {
        if (!wooAuth) return 0;
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wc/v3/orders?status=completed&per_page=100`, {
            headers: { Authorization: `Basic ${wooAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return Array.isArray(data) ? data.reduce((sum, o) => sum + Number(o.total || 0), 0) : 0;
        } catch { return 0; }
      })(),

      (async () => {
        if (!wooAuth) return 0;
        try {
          const todayStart = new Date();
          todayStart.setHours(0, 0, 0, 0);
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wc/v3/orders?status=completed&after=${todayStart.toISOString()}&per_page=100`, {
            headers: { Authorization: `Basic ${wooAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return Array.isArray(data) ? data.reduce((sum, o) => sum + Number(o.total || 0), 0) : 0;
        } catch { return 0; }
      })(),

      (async () => {
        if (!wooAuth) return 0;
        try {
          const today = new Date();
          const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wc/v3/orders?status=completed&after=${monthStart.toISOString()}&per_page=100`, {
            headers: { Authorization: `Basic ${wooAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return Array.isArray(data) ? data.reduce((sum, o) => sum + Number(o.total || 0), 0) : 0;
        } catch { return 0; }
      })(),

      (async () => {
        if (!wpAuth) return 0;
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/ei/v1/notes`, {
            headers: { Authorization: `Basic ${wpAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return Array.isArray(data) ? data.length : (data.items ? data.items.length : 0);
        } catch { return 0; }
      })(),

      (async () => {
        if (!wpAuth) return 0;
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/ei/v1/requests`, {
            headers: { Authorization: `Basic ${wpAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return Array.isArray(data) ? data.length : (data.items ? data.items.length : 0);
        } catch { return 0; }
      })(),

      // جدیدترین محصولات
      (async () => {
        if (!wooAuth) return [];
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wc/v3/products?per_page=5&orderby=date&order=desc`, {
            headers: { Authorization: `Basic ${wooAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return (Array.isArray(data) ? data : []).map((p) => ({
            id: p.id,
            title: p.name,
            href: `/products/${p.id}`,
            image: p.images?.[0]?.src || "",
          }));
        } catch { return []; }
      })(),

      // جدیدترین سفارش‌ها
      (async () => {
        if (!wooAuth) return [];
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wc/v3/orders?per_page=5&orderby=date&order=desc`, {
            headers: { Authorization: `Basic ${wooAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return (Array.isArray(data) ? data : []).map((o) => ({
            id: o.id,
            title: `سفارش #${o.id}`,
            total: Number(o.total || 0),
            href: `/orders/${o.id}`,
          }));
        } catch { return []; }
      })(),

      // پربازدیدترین محصولات
      (async () => {
        if (!wooAuth) return [];
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wc/v3/products?per_page=5&orderby=popularity`, {
            headers: { Authorization: `Basic ${wooAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return (Array.isArray(data) ? data : []).map((p) => ({
            id: p.id,
            title: p.name,
            total_sales: p.total_sales || 0,
            href: `/products/${p.id}`,
            image: p.images?.[0]?.src || "",
          }));
        } catch { return []; }
      })(),

      // جدیدترین مقالات
      (async () => {
        if (!wpAuth) return [];
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wp/v2/posts?per_page=5&orderby=date&order=desc`, {
            headers: { Authorization: `Basic ${wpAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return (Array.isArray(data) ? data : []).map((p) => ({
            id: p.id,
            title: p.title?.rendered?.replace(/<[^>]*>/g, "") || "بدون عنوان",
            href: `/articles/${p.id}`,
          }));
        } catch { return []; }
      })(),

      // پربازدیدترین مقالات (بر اساس تعداد نظرات)
      (async () => {
        if (!wpAuth) return [];
        try {
          const res = await fetch(`${process.env.WP_BASE_URL}/wp-json/wp/v2/posts?per_page=5&orderby=comment_count&order=desc`, {
            headers: { Authorization: `Basic ${wpAuth}` },
            cache: "no-store",
          });
          const data = await res.json();
          return (Array.isArray(data) ? data : []).map((p) => ({
            id: p.id,
            title: p.title?.rendered?.replace(/<[^>]*>/g, "") || "بدون عنوان",
            comments: p.comment_count || 0,
            href: `/articles/${p.id}`,
          }));
        } catch { return []; }
      })(),
    ]);

    const assign = (index: number, fallback: any) => {
      const result = results[index];
      return result && result.status === "fulfilled" ? result.value : fallback;
    };

    stats.products = assign(0, 0);
    stats.orders = assign(1, 0);
    stats.users = assign(2, 0);
    stats.media = assign(3, 0);
    stats.comments = assign(4, 0);
    stats.totalRevenue = assign(5, 0);
    stats.dailyRevenue = assign(6, 0);
    stats.monthlyRevenue = assign(7, 0);
    stats.notes = assign(8, 0);
    stats.requests = assign(9, 0);
    stats.latestProducts = assign(10, []);
    stats.latestOrders = assign(11, []);
    stats.mostViewedProducts = assign(12, []);
    stats.latestPosts = assign(13, []);
    stats.mostViewedPosts = assign(14, []);

    return NextResponse.json(stats);
  } catch (error: any) {
    return NextResponse.json({
      products: 0,
      orders: 0,
      users: 0,
      media: 0,
      comments: 0,
      notes: 0,
      requests: 0,
      totalRevenue: 0,
      dailyRevenue: 0,
      monthlyRevenue: 0,
      visitsToday: 0,
      visitsMonth: 0,
      visitsAll: 0,
      latestProducts: [],
      latestOrders: [],
      latestNotes: [],
      latestPosts: [],
      mostViewedProducts: [],
      mostViewedPosts: [],
    });
  }
}