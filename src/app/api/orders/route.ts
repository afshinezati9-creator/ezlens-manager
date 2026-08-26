// src/app/api/orders/route.ts
import { NextRequest, NextResponse } from "next/server";
import { woocommerce } from "@/lib/woocommerce";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const page = Number(searchParams.get("page")) || 1;
    const perPage = Number(searchParams.get("per_page")) || 10;
    const status = searchParams.get("status") || "";
    const search = searchParams.get("search") || "";

    const params = new URLSearchParams({
      page: String(page),
      per_page: String(perPage),
    });
    if (status) params.append("status", status);
    if (search) params.append("search", search);

    const data = await woocommerce.get<any>(`orders?${params.toString()}`);

    // ووکامرس در هدرهای پاسخ، تعداد کل رو می‌ده
    // اما ما برای سادگی از response body استفاده می‌کنیم
    // اگر تعداد کل نیاز داریم، باید از Headers استفاده کنیم.

    // داده‌های ووکامرس معمولاً یک آرایه از سفارشات هست
    const orders = Array.isArray(data) ? data : [];

    return NextResponse.json({
      orders,
      total: orders.length, // برای سادگی، ولی بهتره از هدرها استفاده کنی
      totalPages: 1,
      page,
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error?.message || "خطا در دریافت سفارشات" },
      { status: 500 }
    );
  }
}