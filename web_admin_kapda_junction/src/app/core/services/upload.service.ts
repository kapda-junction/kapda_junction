import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class UploadService {
  private baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  uploadImage(file: File): Observable<{ url: string }> {
    const formData = new FormData();
    formData.append('image', file);
    return this.http.post<{ url: string }>(`${this.baseUrl}/upload/image`, formData);
  }

  uploadMultiple(files: File[]): Observable<{ urls: string[] }> {
    const formData = new FormData();
    files.forEach((f) => formData.append('images', f));
    return this.http.post<{ urls: string[] }>(`${this.baseUrl}/upload/images`, formData);
  }

  uploadBanner(file: File): Observable<{ url: string }> {
    const formData = new FormData();
    formData.append('image', file);
    return this.http.post<{ url: string }>(`${this.baseUrl}/upload/banner`, formData);
  }
}
