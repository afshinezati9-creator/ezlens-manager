"use client";

import { useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import Image from "next/image";
import { Eye, EyeOff, RefreshCw } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  // کپچا
  const [num1, setNum1] = useState(0);
  const [num2, setNum2] = useState(0);
  const [captchaAnswer, setCaptchaAnswer] = useState("");
  const [captchaError, setCaptchaError] = useState("");

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  // تولید کپچای جدید
  const generateCaptcha = () => {
    const a = Math.floor(Math.random() * 10) + 1;
    const b = Math.floor(Math.random() * 10) + 1;
    setNum1(a);
    setNum2(b);
    setCaptchaAnswer("");
    setCaptchaError("");
  };

  // اجرای کپچا در اولین رندر
  useEffect(() => {
    generateCaptcha();
  }, []);

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setCaptchaError("");

    // بررسی پاسخ کپچا
    const correctAnswer = num1 + num2;
    if (parseInt(captchaAnswer) !== correctAnswer) {
      setCaptchaError("پاسخ کپچا اشتباه است. دوباره تلاش کنید.");
      generateCaptcha();
      return;
    }

    setLoading(true);
    try {
      // اگر API لاگین دارید، اینجا صدا بزنید
      // const res = await fetch("/api/auth/login", { ... });
      // اگر موفق بود، توکن را ذخیره کنید و به داشبورد بروید

      // فعلاً ساده: اگر نام کاربری و رمز غیر خالی بود وارد شو (برای تست)
      if (!username.trim() || !password.trim()) {
        throw new Error("نام کاربری و رمز عبور را وارد کنید");
      }

      // ذخیره توکن فرضی (در سیستم واقعی توکن از API می‌آید)
      document.cookie = `token=${username}; path=/; max-age=86400`;

      router.push("/dashboard");
    } catch (err: any) {
      setError(err.message || "خطا در ورود");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-6 bg-slate-50">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-lg border border-slate-200 p-8 space-y-6">
        {/* لوگو */}
        <div className="text-center space-y-2">
          <img
            src="https://ezlens.ir/wp-content/uploads/2026/07/logo-500x500-1.webp"
            alt="EzLens"
            width={88}
            height={88}
            className="mx-auto rounded-2xl"
          />
          <h1 className="text-xl font-bold" style={{ color: "var(--primary)" }}>
            ورود به پنل مدیریت
          </h1>
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>
            EzLens Manager
          </p>
        </div>

        {/* پیام خطا */}
        {error && (
          <div className="bg-red-50 text-red-600 px-4 py-3 rounded-xl text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4 text-right">
          {/* نام کاربری */}
          <div>
            <label className="block text-sm mb-1">نام کاربری</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full border rounded-xl px-3 py-2.5 outline-none focus:ring-2 focus:ring-blue-500"
              style={{ borderColor: "var(--border)" }}
              placeholder="admin"
            />
          </div>

          {/* رمز عبور */}
          <div>
            <label className="block text-sm mb-1">رمز عبور</label>
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full border rounded-xl px-3 py-2.5 outline-none focus:ring-2 focus:ring-blue-500 pl-10"
                style={{ borderColor: "var(--border)" }}
                placeholder="••••••••"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          {/* کپچای ریاضی */}
          <div className="bg-slate-50 rounded-xl p-3 border border-slate-200">
            <div className="flex items-center gap-2 mb-2">
              <span className="text-sm text-slate-600">حاصل جمع زیر را وارد کنید:</span>
              <button
                type="button"
                onClick={generateCaptcha}
                className="text-blue-600 hover:text-blue-800"
                title="کپچای جدید"
              >
                <RefreshCw className="w-4 h-4" />
              </button>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-lg font-bold text-slate-800 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
                {num1} + {num2} =
              </span>
              <input
                type="number"
                value={captchaAnswer}
                onChange={(e) => setCaptchaAnswer(e.target.value)}
                className="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="پاسخ"
              />
            </div>
            {captchaError && (
              <p className="text-red-500 text-xs mt-1">{captchaError}</p>
            )}
          </div>

          {/* دکمه ورود */}
          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 rounded-xl text-white font-medium disabled:opacity-50 transition"
            style={{ background: "var(--primary)" }}
          >
            {loading ? "در حال ورود..." : "ورود"}
          </button>
        </form>

        {/* کپی رایت */}
        <p className="text-center text-xs text-slate-400">
          © {new Date().getFullYear()} EzLens Manager
        </p>
      </div>
    </main>
  );
}