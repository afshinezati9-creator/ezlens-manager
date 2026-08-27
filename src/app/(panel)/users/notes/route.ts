import { NextResponse } from "next/server";

function getAuth() {
  const baseUrl = process.env.WP_BASE_URL;
  const key = process.env.WC_CONSUMER_KEY;
  const secret = process.env.WC_CONSUMER_SECRET;
  if (!baseUrl || !key || !secret) return { error: "تنظیمات محیطی ووکامرس ناقص است" as const };
  const auth = Buffer.from(`${key}:${secret}`).toString("base64");
  return { baseUrl, auth };
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    if (!id) {
      return NextResponse.json({ error: "شناسه کاربر الزامی است" }, { status: 400 });
    }

    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    const url = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers/${id}`;
    const res = await fetch(url, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: "خطا در دریافت کاربر", status: res.status, details: text.slice(0, 500) }, { status: res.status });
    }

    const customer = await res.json();
    const meta_data = customer.meta_data || [];
    const notesMeta = meta_data.find((m: any) => m.key === "_customer_notes");
    const notes = notesMeta ? (JSON.parse(notesMeta.value) || []) : [];

    return NextResponse.json(notes);
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    if (!id) {
      return NextResponse.json({ error: "شناسه کاربر الزامی است" }, { status: 400 });
    }

    const body = await request.json();
    const note = body.note;
    const author = body.author || "مدیر سیستم";

    if (!note || !note.trim()) {
      return NextResponse.json({ error: "متن یادداشت الزامی است" }, { status: 400 });
    }

    const cfg = getAuth();
    if ("error" in cfg) return NextResponse.json({ error: cfg.error }, { status: 500 });

    // دریافت مشتری فعلی
    const getUrl = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers/${id}`;
    const getRes = await fetch(getUrl, {
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      cache: "no-store",
    });

    if (!getRes.ok) {
      const text = await getRes.text();
      return NextResponse.json({ error: "خطا در دریافت کاربر", status: getRes.status, details: text.slice(0, 500) }, { status: getRes.status });
    }

    const customer = await getRes.json();
    const meta_data = customer.meta_data || [];
    const notesMetaIndex = meta_data.findIndex((m: any) => m.key === "_customer_notes");
    
    let notes = [];
    if (notesMetaIndex >= 0) {
      notes = JSON.parse(meta_data[notesMetaIndex].value) || [];
    }

    // ساخت یادداشت جدید
    const newNote = {
      id: Date.now(),
      author: author,
      note: note.trim(),
      date_created: new Date().toISOString(),
    };

    notes.push(newNote);

    // به‌روزرسانی متادیتا
    const updatedMeta = meta_data.map((m: any) => {
      if (m.key === "_customer_notes") {
        return { ...m, value: JSON.stringify(notes) };
      }
      return m;
    });

    if (notesMetaIndex < 0) {
      updatedMeta.push({ key: "_customer_notes", value: JSON.stringify(notes) });
    }

    const putUrl = `${cfg.baseUrl.replace(/\/$/, "")}/wp-json/wc/v3/customers/${id}`;
    const putRes = await fetch(putUrl, {
      method: "PUT",
      headers: { Authorization: `Basic ${cfg.auth}`, "Content-Type": "application/json" },
      body: JSON.stringify({ meta_data: updatedMeta }),
      cache: "no-store",
    });

    if (!putRes.ok) {
      const text = await putRes.text();
      return NextResponse.json({ error: "خطا در ذخیره یادداشت", status: putRes.status, details: text.slice(0, 500) }, { status: putRes.status });
    }

    return NextResponse.json(newNote, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: "خطای سرور", details: error?.message || "unknown" }, { status: 500 });
  }
}