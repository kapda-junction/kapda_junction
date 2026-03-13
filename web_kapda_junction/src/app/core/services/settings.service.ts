import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, map, shareReplay } from 'rxjs/operators';
import { ApiService } from './api.service';
import { environment } from '../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class SettingsService {
  private cache$: Observable<{ whatsappInquiryNumber: string }> | null = null;

  constructor(private httpApi: ApiService) {}

  private normalizeNumber(num: string): string {
    const digits = num.replace(/\D/g, '');
    if (digits.startsWith('91') && digits.length >= 12) return digits;
    if (digits.length >= 10) return '91' + digits.slice(-10);
    return '919770525851';
  }

  getPublic(): Observable<{ whatsappInquiryNumber: string }> {
    if (!this.cache$) {
      this.cache$ = this.httpApi.get<{ whatsappInquiryNumber: string }>('/settings').pipe(
        catchError(() => of({ whatsappInquiryNumber: '9770525851' })),
        shareReplay(1)
      );
    }
    return this.cache$;
  }

  getWhatsapp(): Observable<string> {
    return this.getPublic().pipe(
      map((s) => s.whatsappInquiryNumber || '9770525851')
    );
  }

  getShareProductUrl(productId: string): string {
    const base = (environment as any).shareBaseUrl || '';
    const url = base ? `${base.replace(/\/$/, '')}/share/product/${productId}` : `${typeof window !== 'undefined' ? window.location.origin : ''}/share/product/${productId}`;
    return url;
  }

  getWhatsappShareUrl(num: string, shareUrl: string): string {
    const clean = this.normalizeNumber(num);
    const text = `Hi Kapda Junction I am interested in this product. ${shareUrl}`;
    return `https://wa.me/${clean}?text=${encodeURIComponent(text)}`;
  }

  getWhatsappUrl(num: string, product?: { name?: string; _id?: string }, customMessage?: string): string {
    const clean = this.normalizeNumber(num);
    let text = customMessage ?? '';
    if (!text && product?.name) {
      text = `Hi! I'm interested in: ${product.name}. Please share details.`;
    }
    if (!text) text = 'Hi! I would like to inquire about your products.';
    return `https://wa.me/${clean}?text=${encodeURIComponent(text)}`;
  }
}
