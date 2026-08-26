// src/lib/woocommerce.ts
const BASE_URL = (process.env.WP_BASE_URL || "https://ezlens.ir").replace(/\/$/, "");
const CONSUMER_KEY = process.env.WC_CONSUMER_KEY!;
const CONSUMER_SECRET = process.env.WC_CONSUMER_SECRET!;

async function wooRequest<T>(
  endpoint: string,
  method: "GET" | "POST" | "PUT" | "DELETE" = "GET",
  body?: any
): Promise<T> {
  const cleanEndpoint = endpoint.replace(/^\/+/, "");
  const url = `${BASE_URL}/wp-json/wc/v3/${cleanEndpoint}`;

  // چاپ آدرس درخواستی برای دیباگ
  console.log(`[WooCommerce] Requesting: ${method} ${url}`);

  // احراز هویت با Basic Auth (کلید عمومی و محرمانه ووکامرس)
  const authHeader = "Basic " + Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString("base64");

  const res = await fetch(url, {
    method,
    headers: {
      "Authorization": authHeader,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`WooCommerce API Error: ${res.status} - ${text}`);
  }

  return res.json();
}

export const woocommerce = {
  get: <T>(endpoint: string) => wooRequest<T>(endpoint, "GET"),
  post: <T>(endpoint: string, body: any) => wooRequest<T>(endpoint, "POST", body),
  put: <T>(endpoint: string, body: any) => wooRequest<T>(endpoint, "PUT", body),
  delete: <T>(endpoint: string) => wooRequest<T>(endpoint, "DELETE"),
};