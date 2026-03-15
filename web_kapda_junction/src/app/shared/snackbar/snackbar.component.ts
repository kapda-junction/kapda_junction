import { Component, inject } from '@angular/core';
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
  `],
})
export class SnackbarComponent {
  private snackbarService = inject(SnackbarService);
  snackbar$ = this.snackbarService.snackbar;

  dismiss() {
    this.snackbarService.dismiss();
  }
}
