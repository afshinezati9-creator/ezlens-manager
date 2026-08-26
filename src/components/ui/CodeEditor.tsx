"use client";

type Props = {
  value: string;
  onChange: (v: string) => void;
  rows?: number;
};

export default function CodeEditor({ value, onChange, rows = 12 }: Props) {
  const lines = Math.max(rows, value.split("\n").length);

  return (
    <div className="border rounded-xl overflow-hidden" style={{ borderColor: "var(--border)", direction: "ltr" }}>
      <div className="grid" style={{ gridTemplateColumns: "48px 1fr" }}>
        <div
          className="text-[11px] leading-6 py-3 px-2 select-none text-right"
          style={{ background: "#0f172a", color: "#94a3b8", fontFamily: "ui-monospace, monospace" }}
        >
          {Array.from({ length: lines }).map((_, i) => (
            <div key={i}>{i + 1}</div>
          ))}
        </div>
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          rows={lines}
          spellCheck={false}
          className="w-full py-3 px-3 text-[12px] leading-6 outline-none resize-y"
          style={{
            background: "#020617",
            color: "#e2e8f0",
            fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace",
            direction: "ltr",
            textAlign: "left",
            border: 0,
          }}
        />
      </div>
    </div>
  );
}