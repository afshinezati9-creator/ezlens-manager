"use client";

type Props = {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
};

export default function Pagination({ page, totalPages, onChange }: Props) {
  if (totalPages <= 1) return null;

  const pages = Array.from({ length: totalPages }, (_, i) => i + 1);

  return (
    <div className="flex items-center justify-center gap-2 pt-2">
      <button
        type="button"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
        className="px-3 py-1.5 rounded-lg text-sm border disabled:opacity-40"
        style={{ borderColor: "var(--border)" }}
      >
        قبلی
      </button>

      {pages.map((p) => (
        <button
          key={p}
          type="button"
          onClick={() => onChange(p)}
          className="w-9 h-9 rounded-lg text-sm"
          style={{
            background: p === page ? "var(--primary)" : "#fff",
            color: p === page ? "#fff" : "var(--text)",
            border: "1px solid var(--border)",
          }}
        >
          {p.toLocaleString("fa-IR")}
        </button>
      ))}

      <button
        type="button"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
        className="px-3 py-1.5 rounded-lg text-sm border disabled:opacity-40"
        style={{ borderColor: "var(--border)" }}
      >
        بعدی
      </button>
    </div>
  );
}
