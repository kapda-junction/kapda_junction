import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import { Observable } from 'rxjs';

export interface Size {
  _id: string;
  name: string;
}

@Injectable({ providedIn: 'root' })
export class SizeService {
  constructor(private api: ApiService) {}

  getAll(): Observable<Size[]> {
    return this.api.get<Size[]>('/sizes');
  }

  create(data: { name: string }): Observable<Size> {
    return this.api.post<Size>('/sizes', data);
  }

  update(id: string, data: { name: string }): Observable<Size> {
    return this.api.put<Size>(`/sizes/${id}`, data);
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/sizes/${id}`);
  }
}
