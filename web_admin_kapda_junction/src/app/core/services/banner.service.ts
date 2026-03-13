import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';

export interface BannerProduct {
  _id: string;
  name: string;
  price: number;
  images?: string[];
}

export interface Banner {
  _id?: string;
  image: string;
  products: BannerProduct[];
  sortOrder?: number;
  isActive?: boolean;
}

export interface BannerPayload {
  image: string;
  products: string[];  // product IDs
  isActive?: boolean;
  sortOrder?: number;
}

@Injectable({ providedIn: 'root' })
export class BannerService {
  constructor(private api: ApiService) {}

  getAll(): Observable<Banner[]> {
    return this.api.get<Banner[]>('/banners', { _: String(Date.now()) });
  }

  getActive(): Observable<{ banners: Banner[] }> {
    return this.api.get<{ banners: Banner[] }>('/banners/active');
  }

  create(data: BannerPayload): Observable<Banner> {
    return this.api.post<Banner>('/banners', data);
  }

  update(id: string, data: BannerPayload): Observable<Banner> {
    return this.api.put<Banner>(`/banners/${id}`, data);
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/banners/${id}`);
  }
}
