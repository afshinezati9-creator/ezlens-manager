"use client";

type Props = {
  label: string;
  previewUrl?: string;
  multiple?: boolean;
  onFiles: (files: FileList) => void;
};

export default function UploadBox({ label, previewUrl, multiple, onFiles }: Props) {
  return (
    <label className="block cursor-pointer">
      <div
        className="rounded-2xl border border-dashed overflow-hidden min-h-36 flex items-center justify-center relative"
        style={{ borderColor: "var(--border)", background: "#f8fafc" }}
      >
        {previewUrl ? (
          <img src={previewUrl} alt="preview" className="w-full h-44 object-cover" />
        ) : (
          <div className="text-center p-4">
            <div className="text-2xl mb-2">⬆</div>
            <div className="text-sm font-medium">{label}</div>
            <div className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>کلیک برای انتخاب</div>
          </div>
        )}
      </div>
      <input
        type="file"
        accept="image/*"
        multiple={multiple}
        className="hidden"
        onChange={(e) => {
          if (e.target.files?.length) onFiles(e.target.files);
          e.currentTarget.value = "";
        }}
      />
    </label>
  );
}