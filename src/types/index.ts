export type PublishStatus = "publish" | "draft";

export type Product = {
  id: number;
  title: string;
  cat: string;
  brand: string;
  price: number;
  sale: number | null;
  stock: number;
  views: number;
  status: PublishStatus;
};
