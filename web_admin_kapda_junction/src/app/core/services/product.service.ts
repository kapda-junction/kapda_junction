import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';

export interface ProductVariant {
  _id?: string;
  color: string;
  size: string;
  stock: number;
  sku?: string;
}

export interface Product {
  _id?: string;
  name: string;
  slug?: string;
  description?: string;
  price: number;
  compareAtPrice?: number;
  category: string;
  subcategory?: string;
  images: string[];
  variants: ProductVariant[];
  soldOut?: boolean;
  isActive: boolean;
  isFeatured?: boolean;
  heroTag?: string;
  heroOrder?: number;
}

@Injectable({ providedIn: 'root' })
export class ProductService {
  constructor(private api: ApiService) {}

  getAll(params?: { page?: number; limit?: number; category?: string; search?: string }): Observable<{ products: Product[]; total: number; page: number; totalPages: number }> {
    const p: Record<string, string> = {};
    if (params?.page) p['page'] = String(params.page);
    if (params?.limit) p['limit'] = String(params.limit);
    if (params?.category) p['category'] = params.category;
    if (params?.search) p['search'] = params.search;
    return this.api.get<any>('/products', Object.keys(p).length ? p : undefined);
  }

  getOne(id: string): Observable<Product> {
    return this.api.get<Product>(`/products/${id}`);
  }

  create(data: Partial<Product>): Observable<Product> {
    return this.api.post<Product>('/products', data);
  }

  update(id: string, data: Partial<Product>): Observable<Product> {
    return this.api.put<Product>(`/products/${id}`, data);
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/products/${id}`);
  }
}
