import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const username = process.env.WP_APP_USERNAME || process.env.WP_USERNAME;
  const appPassword = process.env.WP_APP_PASSWORD;
  if (!baseUrl || !username || !appPassword) {
    return { error: "تنظیمات وردپرس ناقص است" as const };
  }
  const auth = Buffer.from(`${username}:${appPassword}`).toString("base64");
  return { baseUrl, auth };
}

// تابع کمکی برای تبدیل آرایه آبجکت‌ها به CSV
function convertToCSV(objArray: any[]) {
  if (objArray.length === 0) return "";
  
  // استخراج کلیدهای ستون‌ها از اولین آیتم
  const array = typeof objArray !== "object" ? JSON.parse(objArray) : objArray;
  const keys = Object.keys(array[0]).filter(k => {
    // فقط مقادیر ساده را نگه می‌داریم (رشته، عدد، بولی)
    const val = array[0][k];
    return typeof val !== "object" || val === null;
  });

  const header = keys.join(",");
  const rows = array.map((obj: any) => {
    return keys.map(key => {
      let cell = obj[key] ?? "";
      if (typeof cell === "object") cell = JSON.stringify(cell);
      // فرار دادن کاما و نقل قول
      cell = String(cell).replace(/"/g, '""');
      if (cell.includes(",") || cell.includes('"') || cell.includes("\n")) {
        cell = `"${cell}"`;
      }
      return cell;
    }).join(",");
  });

  return [header, ...rows].join("\n");
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const type = searchParams.get("type") || "all";
    const format = searchParams.get("format") || "json"; // json یا csv
    const from = searchParams.get("from") || "";
    const to = searchParams.get("to") || "";
    
    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    // تبدیل تاریخ میلادی به فرمت استاندارد برای وردپرس (اگر شمسی بود، ما در کلاینت به میلادی تبدیل می‌کنیم)
    // در کلاینت dateFrom و dateTo به ISO تبدیل می‌شوند
    
    const exportData: Record<string, any> = {
      exported_at: new Date().toISOString(),
      type
    };

    async function fetchWP(endpoint: string) {
      let url = `${cfg.baseUrl}/wp-json/${endpoint}`;
      if (from) url += `&after=${new Date(from).toISOString()}`;
      if (to) url += `&before=${new Date(to).toISOString()}`;
      
      const res = await fetch(url, {
        headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
        cache: "no-store"
      });
      if (!res.ok) throw new Error(`خطا در دریافت ${endpoint}`);
      return await res.json();
    }

    try {
      if (type === "all" || type === "orders") {
        try {
          const orders = await fetchWP("wc/v3/orders?per_page=100");
          // برای CSV، داده‌ها را مسطح می‌کنیم
          const flatOrders = (Array.isArray(orders) ? orders : []).map((o: any) => ({
            id: o.id,
            status: o.status,
            total: o.total,
            email: o.billing?.email || "",
            first_name: o.billing?.first_name || "",
            last_name: o.billing?.last_name || "",
            date_created: o.date_created || ""
          }));
          exportData.orders = flatOrders;
        } catch { exportData.orders = []; }
      }

      if (type === "all" || type === "users") {
        try {
          const users = await fetchWP("wc/v3/customers?per_page=100&role=all");
          const flatUsers = (Array.isArray(users) ? users : []).map((u: any) => ({
            id: u.id,
            email: u.email || "",
            first_name: u.first_name || "",
            last_name: u.last_name || "",
            role: u.role || "",
            date_created: u.date_created || ""
          }));
          exportData.users = flatUsers;
        } catch { exportData.users = []; }
      }

      if (type === "all" || type === "media") {
        try {
          const media = await fetchWP("wp/v2/media?per_page=100");
          const flatMedia = (Array.isArray(media) ? media : []).map((m: any) => ({
            id: m.id,
            title: m.title?.rendered || "",
            mime_type: m.mime_type || "",
            date: m.date || ""
          }));
          exportData.media = flatMedia;
        } catch { exportData.media = []; }
      }

      if (type === "all" || type === "comments") {
        try {
          const comments = await fetchWP("wp/v2/comments?per_page=100");
          const flatComments = (Array.isArray(comments) ? comments : []).map((c: any) => ({
            id: c.id,
            author: c.author_name || "",
            email: c.author_email || "",
            content: c.content?.rendered?.replace(/<[^>]*>/g, "") || "",
            date: c.date || ""
          }));
          exportData.comments = flatComments;
        } catch { exportData.comments = []; }
      }

      if (type === "all" || type === "requests") {
        try {
          const requests = await fetchWP("ei/v1/requests");
          const flatRequests = (Array.isArray(requests) ? requests : []).map((r: any) => ({
            id: r.id,
            name: r.name || "",
            email: r.email || "",
            phone: r.phone || "",
            message: r.message || "",
            date: r.date || ""
          }));
          exportData.requests = flatRequests;
        } catch { exportData.requests = []; }
      }

      if (type === "all" || type === "notes") {
        try {
          const notes = await fetchWP("ei/v1/notes");
          const flatNotes = (Array.isArray(notes) ? notes : []).map((n: any) => ({
            id: n.id,
            title: n.title || "",
            content: n.content || "",
            color: n.color || "",
            author_name: n.author_name || "",
            date: n.date || ""
          }));
          exportData.notes = flatNotes;
        } catch { exportData.notes = []; }
      }
    } catch (e) {
      // ادامه بده
    }

    // اگر فرمت CSV درخواست شده باشد
    if (format === "csv") {
      // انتخاب اولین بخش موجود برای خروجی CSV (اگر type=all بود، ترکیب نمی‌کنیم و فقط اولین را می‌دهیم یا لیست را جدا می‌کنیم)
      // برای سادگی، اگر type=all باشد، یک فایل CSV با همه بخش‌ها (به صورت ستون‌های مختلف) نمی‌سازیم، فقط بخش اول را می‌دهیم
      let dataForExport: any[] = [];
      
      if (exportData.orders && exportData.orders.length > 0) dataForExport = exportData.orders;
      else if (exportData.users && exportData.users.length > 0) dataForExport = exportData.users;
      else if (exportData.media && exportData.media.length > 0) dataForExport = exportData.media;
      else if (exportData.comments && exportData.comments.length > 0) dataForExport = exportData.comments;
      else if (exportData.requests && exportData.requests.length > 0) dataForExport = exportData.requests;
      else if (exportData.notes && exportData.notes.length > 0) dataForExport = exportData.notes;

      const csv = convertToCSV(dataForExport);
      
      return new Response(csv, {
        headers: {
          "Content-Type": "text/csv; charset=utf-8",
          "Content-Disposition": `attachment; filename="backup-${type}-${new Date().toISOString().split("T")[0]}.csv"`
        }
      });
    }

    // در غیر این صورت JSON برمی‌گردانیم
    return NextResponse.json(exportData);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}