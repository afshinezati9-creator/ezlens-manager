import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(req: NextRequest) {
  // نام کوکی لاگین خود را چک کنید (در سیستم لاگین خودتان باید همین نام را ست کنید)
  const token = req.cookies.get('token')?.value;

  // اگر کاربر لاگین نکرده و وارد مسیرهای پنل شده، به صفحه لاگین بفرست
  if (!token) {
    const loginUrl = new URL('/login', req.url);
    // اگر درخواست برای مسیرهای داخلی بود، آنها را هم به لاگین بفرست
    if (req.nextUrl.pathname.startsWith('/dashboard') || 
        req.nextUrl.pathname.startsWith('/orders') ||
        req.nextUrl.pathname.startsWith('/users') ||
        req.nextUrl.pathname.startsWith('/media') ||
        req.nextUrl.pathname.startsWith('/notes') ||
        req.nextUrl.pathname.startsWith('/settings')) {
      return NextResponse.redirect(loginUrl);
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/orders/:path*', '/users/:path*', '/media/:path*', '/notes/:path*', '/settings/:path*'],
};