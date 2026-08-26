"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";

type ReqStatus = "new" | "reviewed" | "replied";

const mockDetails: Record<string, any> = {
  "1": {
    formTitle: "فرم مشاوره لنز",
    sourcePage: "/consultation",
    date: "1405/05/20 11:20",
    status: "new",
    fields: {
      "نام و نام خانوادگی": "رضا محمدی",
      "شماره تماس": "09121234567",
      "ایمیل": "reza@mail.com",
      "نوع لنز موردنظر": "روزانه",
      "توضیحات": "برای آستیگمات مشورت می‌خواهم",
    },
    files: [{ name: "eye-scan.jpg", size: "320 KB" }],
    notes: [
      { author: "admin", text: "باید با اپتومتریست هماهنگ شود", date: "1405/05/20 12:00" },
    ],
  },
};

const statusLabel: Record<ReqStatus, string> = {
  new: "جدید",
  reviewed: "بررسی‌شده",
  replied: "پاسخ‌داده‌شده",
};

export default function RequestDetailPage() {
  const params = useParams();
  const id = String(params.id || "1");
  const data = mockDetails[id] || mockDetails["1"];

  const [status, setStatus] = useState<ReqStatus>(data.status);
  const [notes, setNotes] = useState(data.notes || []);
  const [noteText, setNoteText] = useState("");
  const [message, setMessage] = useState("");

  function saveStatus() {
    setMessage("وضعیت درخواست ذخیره شد (شبیه‌سازی)");
  }

  function addNote() {
    if (!noteText.trim()) return;
    const now = new Date().toLocaleTimeString("fa-IR", { hour: "2-digit", minute: "2-digit" });
    setNotes((prev: any[]) => [
      { author: "admin", text: noteText.trim(), date: "امروز " + now },
      ...prev,
    ]);
    setNoteText("");
    setMessage("یادداشت داخلی ثبت شد");
  }

  function removeRequest() {
    if (!confirm("حذف این درخواست؟")) return;
    setMessage("درخواست حذف شد (شبیه‌سازی) - در نسخه واقعی به لیست برمی‌گردد");
  }

  return (
    <main className="p-4 space-y-4 pb-8">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>جزئیات درخواست</h2>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>{data.formTitle}</p>
        </div>
        <Link href="/requests" className="text-sm" style={{ color: "var(--secondary)" }}>بازگشت</Link>
      </div>

      {message && (
        <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--success)" }}>
          {message}
        </div>
      )}

      <section className="bg-white border rounded-2xl p-4 space-y-2 text-sm" style={{ borderColor: "var(--border)" }}>
        <div>تاریخ: {data.date}</div>
        <div>صفحه منبع: {data.sourcePage}</div>
        <div>وضعیت فعلی: {statusLabel[status]}</div>
      </section>

      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">تغییر وضعیت</h3>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value as ReqStatus)}
          className="w-full border rounded-xl px-3 py-2.5 text-sm outline-none"
          style={{ borderColor: "var(--border)" }}
        >
          <option value="new">جدید</option>
          <option value="reviewed">بررسی‌شده</option>
          <option value="replied">پاسخ‌داده‌شده</option>
        </select>
        <button onClick={saveStatus} className="w-full py-2.5 rounded-xl text-white text-sm" style={{ background: "var(--primary)" }}>
          ذخیره وضعیت
        </button>
      </section>

      <section className="bg-white border rounded-2xl p-4 space-y-2" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">اطلاعات ارسال‌شده</h3>
        {Object.entries(data.fields).map(([k, v]) => (
          <div key={k} className="text-sm flex justify-between gap-3 border-b py-2" style={{ borderColor: "var(--border)" }}>
            <span style={{ color: "var(--text-muted)" }}>{k}</span>
            <span className="text-left font-medium">{String(v)}</span>
          </div>
        ))}
      </section>

      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">فایل‌های آپلودی</h3>
        {(!data.files || data.files.length === 0) && (
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>فایلی ندارد</p>
        )}
        {data.files?.map((f: any, idx: number) => (
          <div key={idx} className="flex items-center justify-between gap-3 text-sm bg-slate-50 rounded-xl p-3">
            <span>📎 {f.name} ({f.size})</span>
            <button
              className="px-3 py-1.5 rounded-lg border text-xs"
              style={{ borderColor: "var(--border)" }}
              onClick={() => setMessage("دانلود " + f.name + " (شبیه‌سازی)")}
            >
              دانلود
            </button>
          </div>
        ))}
      </section>

      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">یادداشت داخلی تیم</h3>
        <textarea
          value={noteText}
          onChange={(e) => setNoteText(e.target.value)}
          rows={3}
          placeholder="یادداشت داخلی برای پیگیری..."
          className="w-full border rounded-xl px-3 py-2 text-sm outline-none"
          style={{ borderColor: "var(--border)" }}
        />
        <button onClick={addNote} className="px-3 py-2 rounded-xl text-sm text-white" style={{ background: "var(--primary)" }}>
          ثبت یادداشت
        </button>

        <div className="space-y-2">
          {notes.map((n: any, idx: number) => (
            <div key={idx} className="rounded-xl p-3 text-sm" style={{ background: "var(--bg-secondary)" }}>
              <div className="text-xs mb-1" style={{ color: "var(--text-muted)" }}>
                {n.author} · {n.date}
              </div>
              <div>{n.text}</div>
            </div>
          ))}
        </div>
      </section>

      <button onClick={removeRequest} className="w-full py-2.5 rounded-xl text-sm border" style={{ borderColor: "var(--border)", color: "var(--danger)" }}>
        حذف درخواست
      </button>
    </main>
  );
}
