import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import { Observable } from 'rxjs';

export interface Color {
  _id: string;
  name: string;
}

@Injectable({ providedIn: 'root' })
export class ColorService {
  constructor(private api: ApiService) {}

  getAll(): Observable<Color[]> {
    return this.api.get<Color[]>('/colors');
  }

  create(data: { name: string }): Observable<Color> {
    return this.api.post<Color>('/colors', data);
  }

  update(id: string, data: { name: string }): Observable<Color> {
    return this.api.put<Color>(`/colors/${id}`, data);
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/colors/${id}`);
  }
}
