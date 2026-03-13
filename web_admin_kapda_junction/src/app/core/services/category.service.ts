import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';

export interface Category {
  _id: string;
  name: string;
  slug: string;
  description?: string;
  image?: string;
  parent?: string | null | { _id: string; name: string };
  metadata?: { metaTitle?: string; metaDescription?: string; keywords?: string[] };
  sortOrder: number;
  isActive: boolean;
  children?: Category[];
}

@Injectable({ providedIn: 'root' })
export class CategoryService {
  constructor(private api: ApiService) {}

  getAll(parentOnly?: boolean): Observable<Category[]> {
    const params = parentOnly ? { parentOnly: 'true' } : undefined;
    return this.api.get<Category[]>('/categories', params ? { parentOnly: 'true' } : undefined);
  }

  getTree(): Observable<Category[]> {
    return this.api.get<Category[]>('/categories/tree');
  }

  getOne(id: string): Observable<Category> {
    return this.api.get<Category>(`/categories/${id}`);
  }

  create(data: Partial<Category>): Observable<Category> {
    return this.api.post<Category>('/categories', data);
  }

  update(id: string, data: Partial<Category>): Observable<Category> {
    return this.api.put<Category>(`/categories/${id}`, data);
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/categories/${id}`);
  }
}
