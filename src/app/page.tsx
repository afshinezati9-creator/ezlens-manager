"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";

export default function SplashPage() {
  const router = useRouter();

  useEffect(() => {
    const timer = setTimeout(() => {
      router.push("/login");
    }, 1500);

    return () => clearTimeout(timer);
  }, [router]);

  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-white">
      <div className="flex flex-col items-center gap-4">
		<img
		  src="https://ezlens.ir/wp-content/uploads/2026/07/logo-500x500-1.webp"
		  alt="EzLens"
		  width={120}
		  height={120}
		  className="rounded-2xl"
		/>
        <p className="text-sm" style={{ color: "var(--text-muted)" }}>
          در حال آماده‌سازی...
        </p>
      </div>
    </main>
  );
}