import { NextResponse } from "next/server";
import { promises as fs } from "fs";
import path from "path";

const SETTINGS_PATH = path.join(process.cwd(), "src/data/settings.json");

// تنظیمات پیش‌فرض
const DEFAULT_SETTINGS = {
  siteName: "EzLens Manager",
  siteLogo: "",
  fontFamily: "vazirmatn",
  theme: "light",
  apiBaseUrl: "https://ezlens.ir",
  notifications: {
    orders: true,
    comments: true,
    notes: false
  },
  dateFormat: "fa-IR",
  currency: "تومان"
};

async function ensureSettingsFile() {
  try {
    await fs.access(SETTINGS_PATH);
  } catch {
    await fs.mkdir(path.dirname(SETTINGS_PATH), { recursive: true });
    await fs.writeFile(SETTINGS_PATH, JSON.stringify(DEFAULT_SETTINGS, null, 2), "utf-8");
  }
}

export async function GET() {
  await ensureSettingsFile();
  try {
    const data = await fs.readFile(SETTINGS_PATH, "utf-8");
    return NextResponse.json(JSON.parse(data));
  } catch (error: any) {
    return NextResponse.json(DEFAULT_SETTINGS);
  }
}

export async function PUT(request: Request) {
  await ensureSettingsFile();
  try {
    const body = await request.json();
    const current = JSON.parse(await fs.readFile(SETTINGS_PATH, "utf-8"));
    const newSettings = { ...current, ...body };
    await fs.writeFile(SETTINGS_PATH, JSON.stringify(newSettings, null, 2), "utf-8");
    return NextResponse.json(newSettings);
  } catch (error: any) {
    return NextResponse.json({ error: "خطا در ذخیره تنظیمات" }, { status: 500 });
  }
}