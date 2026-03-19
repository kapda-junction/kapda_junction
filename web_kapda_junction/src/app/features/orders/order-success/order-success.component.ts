import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-order-success',
  standalone: true,
  imports: [CommonModule, RouterLink],
  template: `
    <div class="container success-wrap">
      <div class="success-card">
        <h1>Order Placed Successfully!</h1>
        <p>Thank you for your order. We'll process it shortly.</p>
        <a routerLink="/products" class="btn-continue">Continue Shopping</a>
      </div>
    </div>
  `,
  styles: [`
    .success-wrap { min-height: 50vh; display: flex; align-items: center; justify-content: center; }
    .success-card { text-align: center; padding: 2rem; background: var(--bg-card); border-radius: var(--radius); box-shadow: var(--shadow-sm); max-width: 400px; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; color: var(--color-accent); }
    p { color: var(--text-secondary); margin-bottom: 1.5rem; }
    .btn-continue { display: inline-block; padding: 0.75rem 1.5rem; background: var(--color-primary); color: #fff; font-weight: 600; border-radius: var(--radius); }
  `],
})
export class OrderSuccessComponent {}
