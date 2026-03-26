import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

type RequestOptions = {
  headers?: Record<string, string>;
};

@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  get<T>(path: string, params?: Record<string, string>, options?: RequestOptions): Observable<T> {
    let httpParams = new HttpParams();
    if (params) Object.entries(params).forEach(([k, v]) => { httpParams = httpParams.set(k, v); });
    return this.http.get<T>(`${this.baseUrl}${path}`, { params: httpParams, headers: options?.headers });
  }

  post<T>(path: string, body: unknown, options?: RequestOptions): Observable<T> {
    return this.http.post<T>(`${this.baseUrl}${path}`, body, { headers: options?.headers });
  }

  put<T>(path: string, body: unknown, options?: RequestOptions): Observable<T> {
    return this.http.put<T>(`${this.baseUrl}${path}`, body, { headers: options?.headers });
  }

  delete<T>(path: string, options?: RequestOptions): Observable<T> {
    return this.http.delete<T>(`${this.baseUrl}${path}`, { headers: options?.headers });
  }
}
