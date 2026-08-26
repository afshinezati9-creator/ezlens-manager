const fs = require("fs");
const path = require("path");
const root = process.cwd();

function write(rel, content) {
  const full = path.join(root, rel);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, content.trim() + "\n", "utf8");
  console.log("✓", rel);
}

const settingsPage = `
"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

const exportItems = [
  { key: "products", label: "محصولات", count: 10 },
  { key: "articles", label: "مقالات", count: 7 },
  { key: "orders", label: "سفارشات", count: 7 },
  { key: "requests", label: "درخواست‌ها", count: 7 },
  { key: "users", label: "کاربران", count: 6 },
  { key: "comments", label: "نظرات", count: 6 },
  { key: "notes", label: "یادداشت‌ها", count: 4 },
  { key: "planning", label: "برنامه‌ریزی اجرا", count: 4 },
];

// داده نمونه برای خروجی
const sampleData: Record<string, any[]> = {
  products: [
    { id: 1, title: "لنز روزانه Acuvue Oasys", price: 1250000, stock: 120 },
    { id: 2, title: "عینک طبی Ray-Ban 5154", price: 3200000, stock: 15 },
  ],
  articles: [
    { id: 1, title: "قوز قرنیه چیست؟", status: "publish" },
    { id: 2, title: "راهنمای انتخاب لنز", status: "publish" },
  ],
  orders: [
    { id: 1, code: "EZ-1524", total: 2450000, status: "processing" },
  ],
  requests: [
    { id: 1, formTitle: "فرم مشاوره لنز", name: "رضا محمدی", status: "new" },
  ],
  users: [
    { id: 1, name: "مدیر اصلی", role: "administrator", phone: "09198421069" },
  ],
  comments: [
    { id: 1, author: "رضا", content: "کیفیت عالی بود", status: "approved" },
  ],
  notes: [
    { id: 1, text: "موجودی لنز اسکلرال چک شود", cat: "موجودی" },
  ],
  planning: [
    { id: 1, title: "اتصال API محصولات", section: "فنی نرم‌افزار", status: "queued" },
  ],
};

function downloadFile(filename: string, content: string, mime: string) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function toCSV(rows: any[]) {
  if (!rows.length) return "";
  const keys = Object.keys(rows[0]);
  const lines = [keys.join(",")];
  rows.forEach((row) => {
    lines.push(keys.map((k) => JSON.stringify(row[k] ?? "")).join(","));
  });
  return lines.join("\\n");
}

export default function SettingsPage() {
  const router = useRouter();
  const [message, setMessage] = useState("");

  function exportData(key: string, format: "json" | "csv") {
    const data = sampleData[key] || [];
    if (!data.length) {
      setMessage("داده‌ای برای خروجی وجود ندارد");
      return;
    }

    if (format === "json") {
      downloadFile(key + ".json", JSON.stringify(data, null, 2), "application/json");
      setMessage("خروجی JSON آماده شد: " + key + ".json");
      return;
    }

    downloadFile(key + ".csv", toCSV(data), "text/csv");
    setMessage("خروجی CSV آماده شد: " + key + ".csv");
  }

  function logout() {
    router.push("/login");
  }

  return (
    <main className="p-4 space-y-4 pb-8">
      <div>
        <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>تنظیمات</h2>
        <p className="text-sm" style={{ color: "var(--text-muted)" }}>
          خروجی داده و تنظیمات پنل
        </p>
      </div>

      {message && (
        <div className="rounded-xl px-3 py-2 text-sm text-white" style={{ background: "var(--success)" }}>
          {message}
        </div>
      )}

      <section className="bg-white border rounded-2xl p-4 space-y-2" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">وضعیت اپ</h3>
        <div className="text-sm">نسخه: 0.1.0-demo</div>
        <div className="text-sm">حالت: شبیه‌سازی UI (بدون اتصال واقعی به وردپرس)</div>
        <div className="text-sm">مسیر نهایی پیشنهادی: ezlens.ir/app یا app.ezlens.ir</div>
      </section>

      <section className="space-y-3">
        <h3 className="font-bold text-sm">خروجی گرفتن از داده‌ها</h3>
        {exportItems.map((item) => (
          <div
            key={item.key}
            className="bg-white border rounded-2xl p-4 flex items-center justify-between gap-3"
            style={{ borderColor: "var(--border)" }}
          >
            <div>
              <div className="font-medium text-sm">{item.label}</div>
              <div className="text-xs" style={{ color: "var(--text-muted)" }}>
                {item.count.toLocaleString("fa-IR")} مورد نمونه
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => exportData(item.key, "json")}
                className="px-3 py-1.5 rounded-lg text-xs border"
                style={{ borderColor: "var(--border)" }}
              >
                JSON
              </button>
              <button
                onClick={() => exportData(item.key, "csv")}
                className="px-3 py-1.5 rounded-lg text-xs border"
                style={{ borderColor: "var(--border)" }}
              >
                CSV
              </button>
            </div>
          </div>
        ))}
      </section>

      <section className="bg-white border rounded-2xl p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
        <h3 className="font-bold text-sm">حساب کاربری</h3>
        <button
          onClick={logout}
          className="w-full py-2.5 rounded-xl text-sm text-white"
          style={{ background: "var(--cta)" }}
        >
          خروج از پنل
        </button>
      </section>
    </main>
  );
}
`;

console.log("Creating settings module...\\n");
write("src/app/(panel)/settings/page.tsx", settingsPage);
console.log("\\nDone.");