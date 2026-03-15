import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SnackbarService } from '../../core/services/snackbar.service';

@Component({
  selector: 'app-snackbar',
  standalone: true,
  imports: [CommonModule],
  template: `
    @if (snackbar$ | async; as state) {
      <div class="snackbar" [class.success]="state.type === 'success'" [class.error]="state.type === 'error'" (click)="dismiss()">
        {{ state.message }}
      </div>
    }
    @if (loading$ | async) {
      <div class="loading-overlay" role="status" aria-live="polite">
        <div class="spinner"></div>
        <span class="loading-text">Loading...</span>
      </div>
    }
  `,
  styles: [`
    :host { display: contents; }
    .snackbar {
      position: fixed;
      bottom: 1.5rem;
      left: 50%;
      transform: translateX(-50%);
      padding: 0.75rem 1.5rem;
      border-radius: 8px;
      color: #fff;
      font-weight: 500;
      font-size: 0.9rem;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 9999;
      max-width: 90vw;
      cursor: pointer;
      animation: slideUp 0.3s ease;
    }
    .snackbar.success { background: #22c55e; }
    .snackbar.error { background: #dc3545; }
    @keyframes slideUp {
      from { opacity: 0; transform: translateX(-50%) translateY(1rem); }
      to { opacity: 1; transform: translateX(-50%) translateY(0); }
    }
    .loading-overlay {
      position: fixed;
      inset: 0;
      background: rgba(255,255,255,0.85);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 0.75rem;
      z-index: 9998;
    }
    .spinner {
      width: 40px;
      height: 40px;
      border: 3px solid #e5e7eb;
      border-top-color: #1a1a2e;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    .loading-text { font-size: 0.9rem; color: #555; font-weight: 500; }
    @keyframes spin { to { transform: rotate(360deg); } }
  `],
})
export class SnackbarComponent implements OnInit {
  private snackbarService = inject(SnackbarService);
  snackbar$ = this.snackbarService.snackbar;
  loading$ = this.snackbarService.loading;

  ngOnInit() {}

  dismiss() {
    this.snackbarService.dismiss();
  }
}
