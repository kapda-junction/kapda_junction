import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="settings-card">
      <h2>WhatsApp Inquiry</h2>
      <p class="hint">This number is shown on the customer website for product inquiries. Customers can contact you via WhatsApp.</p>
      <div class="form-group">
        <label>WhatsApp Number</label>
        <input
          type="tel"
          [(ngModel)]="whatsappNumber"
          placeholder="e.g. 9770525851"
          class="input"
          (keyup.enter)="save()"
        />
        <small>Enter 10-digit number without country code. For India, +91 will be added automatically.</small>
      </div>
      <hr class="divider">

      <h2>App Download Link</h2>
      <p class="hint">Paste your Google Drive / Play Store link here. Users who don't have the app will see a "Download App" button on product share pages.</p>
      <div class="form-group">
        <label>Download URL</label>
        <input
          type="url"
          [(ngModel)]="appDownloadUrl"
          placeholder="https://drive.google.com/..."
          class="input input-wide"
          (keyup.enter)="save()"
        />
      </div>

      <div class="actions">
        <button (click)="save()" [disabled]="saving" class="btn-save">
          {{ saving ? 'Saving...' : 'Save' }}
        </button>
        @if (message) {
          <span class="message" [class.error]="isError">{{ message }}</span>
        }
      </div>
    </div>
  `,
  styles: [`
    .settings-card {
      background: #fff;
      padding: 2rem;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      max-width: 480px;
    }
    .settings-card h2 { margin-bottom: 0.5rem; font-size: 1.25rem; }
    .hint { color: #666; font-size: 0.9rem; margin-bottom: 1.5rem; }
    .form-group { margin-bottom: 1.25rem; }
    .form-group label { display: block; font-weight: 600; margin-bottom: 0.5rem; font-size: 0.9rem; }
    .input {
      width: 100%;
      max-width: 280px;
      padding: 0.6rem 0.75rem;
      border: 1px solid #ddd;
      border-radius: 8px;
      font-size: 1rem;
    }
    .form-group small { display: block; margin-top: 0.35rem; color: #888; font-size: 0.8rem; }
    .input-wide { max-width: 100%; }
    .divider { border: none; border-top: 1px solid #eee; margin: 1.75rem 0; }
    .actions { display: flex; align-items: center; gap: 1rem; }
    .btn-save {
      padding: 0.6rem 1.25rem;
      background: #1a1a2e;
      color: #fff;
      border: none;
      border-radius: 8px;
      font-weight: 500;
      cursor: pointer;
    }
    .btn-save:hover:not(:disabled) { background: #2d2d44; }
    .btn-save:disabled { opacity: 0.7; cursor: not-allowed; }
    .message { font-size: 0.9rem; }
    .message.error { color: #dc2626; }
  `],
})
export class SettingsComponent implements OnInit {
  private api = inject(ApiService);

  whatsappNumber = '';
  appDownloadUrl = '';
  saving = false;
  message = '';
  isError = false;

  ngOnInit() {
    this.api.get<{ whatsappInquiryNumber: string; appDownloadUrl?: string }>('/settings').subscribe({
      next: (res) => {
        this.whatsappNumber  = res?.whatsappInquiryNumber ?? '';
        this.appDownloadUrl  = res?.appDownloadUrl ?? '';
      },
    });
  }

  save() {
    const trimmed = (this.whatsappNumber || '').trim();
    if (!trimmed) {
      this.message = 'Please enter a valid number';
      this.isError = true;
      return;
    }
    const digits = trimmed.replace(/\D/g, '');
    if (digits.length < 10) {
      this.message = 'Number must be at least 10 digits';
      this.isError = true;
      return;
    }
    this.saving = true;
    this.message = '';
    this.api.put<{ whatsappInquiryNumber: string; appDownloadUrl: string }>(
      '/settings',
      { whatsappInquiryNumber: digits, appDownloadUrl: this.appDownloadUrl.trim() }
    ).subscribe({
      next: (res) => {
        this.whatsappNumber = res?.whatsappInquiryNumber ?? trimmed;
        this.appDownloadUrl = res?.appDownloadUrl ?? this.appDownloadUrl;
        this.saving = false;
        this.message = 'Saved successfully';
        this.isError = false;
      },
      error: (err) => {
        this.saving = false;
        this.message = err?.error?.message ?? 'Failed to save';
        this.isError = true;
      },
    });
  }
}
