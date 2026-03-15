import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface SnackbarState {
  message: string;
  type: 'success' | 'error';
}

@Injectable({ providedIn: 'root' })
export class SnackbarService {
  snackbar = new BehaviorSubject<SnackbarState | null>(null);

  private dismissTimer: ReturnType<typeof setTimeout> | null = null;

  showSuccess(message: string) {
    this.clearDismissTimer();
    this.snackbar.next({ message, type: 'success' });
    this.dismissTimer = setTimeout(() => this.dismiss(), 3500);
  }

  showError(message: string) {
    this.clearDismissTimer();
    this.snackbar.next({ message, type: 'error' });
    this.dismissTimer = setTimeout(() => this.dismiss(), 4500);
  }

  dismiss() {
    this.clearDismissTimer();
    this.snackbar.next(null);
  }

  private clearDismissTimer() {
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer);
      this.dismissTimer = null;
    }
  }
}
