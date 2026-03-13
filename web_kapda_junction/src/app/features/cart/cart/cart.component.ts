import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { selectCartItems, selectCartTotal } from '../../../core/features/cart/store/cart.selectors';
import { CartActions } from '../../../core/features/cart/store/cart.actions';

@Component({
  selector: 'app-cart',
  standalone: true,
  imports: [CommonModule, RouterLink],
  template: `
    <div class="container">
      <h1 class="page-title">Your Cart</h1>
      @if ((items$ | async)?.length === 0) {
        <div class="empty">
          <p>Your cart is empty.</p>
          <a routerLink="/products" class="btn-shop">Continue Shopping</a>
        </div>
      } @else {
        <div class="cart-list">
          @for (item of items$ | async; track trackItem(item)) {
            <div class="cart-item">
              <a [routerLink]="['/products', item.product._id]" class="item-img">
                <img [src]="item.product.images?.[0] || 'https://via.placeholder.com/80'" [alt]="item.product.name" />
              </a>
              <div class="item-info">
                <a [routerLink]="['/products', item.product._id]" class="item-name">{{ item.product.name }}</a>
                @if (item.variant && (item.variant.color || item.variant.size)) {
                  <span class="variant">{{ item.variant.color }}{{ item.variant.color && item.variant.size ? ', ' : '' }}{{ item.variant.size }}</span>
                }
                <p class="item-price">₹{{ item.product.price }} × {{ item.quantity }} = ₹{{ item.product.price * item.quantity }}</p>
              </div>
              <div class="item-actions">
                <div class="qty">
                  <button type="button" (click)="updateQty(item, -1)">−</button>
                  <span>{{ item.quantity }}</span>
                  <button type="button" (click)="updateQty(item, 1)">+</button>
                </div>
                <button type="button" class="remove" (click)="remove(item)">Remove</button>
              </div>
            </div>
          }
        </div>
        <div class="footer">
          <a routerLink="/products" class="link-back">← Continue Shopping</a>
          <div class="total-wrap">
            <strong>Total: ₹{{ total$ | async }}</strong>
            <button type="button" class="btn-checkout">Proceed to Checkout</button>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .page-title { font-size: 1.75rem; margin-bottom: 1.5rem; }
    .empty { text-align: center; padding: 3rem; color: var(--text-secondary); }
    .btn-shop { display: inline-block; margin-top: 1rem; padding: 0.75rem 1.5rem; background: var(--color-primary); color: #fff; font-weight: 600; border-radius: var(--radius); }
    .cart-list { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem; }
    .cart-item {
      display: grid;
      grid-template-columns: 80px 1fr auto;
      gap: 1rem;
      align-items: center;
      padding: 1rem;
      background: var(--bg-card);
      border-radius: var(--radius);
      box-shadow: var(--shadow-sm);
    }
    .item-img { width: 80px; height: 80px; border-radius: var(--radius-sm); overflow: hidden; }
    .item-img img { width: 100%; height: 100%; object-fit: cover; }
    .item-name { font-weight: 600; color: var(--text-primary); }
    .item-name:hover { color: var(--color-accent); }
    .variant { font-size: 0.85rem; color: var(--text-secondary); display: block; margin-top: 0.25rem; }
    .item-price { font-size: 0.9rem; margin-top: 0.25rem; color: var(--text-secondary); }
    .item-actions { display: flex; flex-direction: column; align-items: flex-end; gap: 0.5rem; }
    .qty { display: flex; align-items: center; gap: 0.25rem; border: 1px solid var(--border); border-radius: var(--radius-sm); overflow: hidden; }
    .qty button { padding: 0.35rem 0.6rem; font-size: 1rem; background: var(--bg-body); }
    .qty button:hover { background: var(--border); }
    .qty span { min-width: 1.5rem; text-align: center; font-weight: 500; }
    .remove { font-size: 0.85rem; color: var(--color-error); }
    .remove:hover { text-decoration: underline; }
    .footer { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 1rem; padding-top: 1rem; border-top: 1px solid var(--border); }
    .total-wrap { display: flex; flex-direction: column; align-items: flex-end; gap: 0.5rem; }
    .btn-checkout { padding: 0.75rem 1.5rem; background: var(--color-accent); color: #fff; font-weight: 600; border-radius: var(--radius); }
    .btn-checkout:hover { background: var(--color-accent-hover); }
  `],
})
export class CartComponent {
  private store = inject(Store);
  items$ = this.store.select(selectCartItems);
  total$ = this.store.select(selectCartTotal);

  trackItem(item: { product: any; variant?: { color?: string; size?: string } }) {
    return `${item.product._id}-${item.variant?.color ?? ''}-${item.variant?.size ?? ''}`;
  }

  updateQty(item: any, delta: number) {
    const qty = Math.max(1, item.quantity + delta);
    this.store.dispatch(CartActions.updateQuantity({
      productId: item.product._id,
      quantity: qty,
      variant: item.variant
    }));
  }

  remove(item: any) {
    this.store.dispatch(CartActions.removeItem({
      productId: item.product._id,
      variant: item.variant
    }));
  }
}
