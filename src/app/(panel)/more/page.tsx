import Link from "next/link";

const items = [
  { href: "/users", label: "کاربران" },
  { href: "/media", label: "رسانه" },
  { href: "/comments", label: "نظرات" },
  { href: "/requests", label: "درخواست‌ها" },
  { href: "/notes", label: "دفترچه یادداشت" },
  { href: "/settings", label: "تنظیمات" },
];

export default function MorePage() {
  return (
    <main className="p-4 space-y-3">
      <h2 className="text-lg font-bold" style={{ color: "var(--primary)" }}>بیشتر</h2>
      <div className="grid grid-cols-2 gap-3">
        {items.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="bg-white border rounded-2xl p-4 text-center text-sm font-medium"
            style={{ borderColor: "var(--border)" }}
          >
            {item.label}
          </Link>
        ))}
      </div>
    </main>
  );
}
