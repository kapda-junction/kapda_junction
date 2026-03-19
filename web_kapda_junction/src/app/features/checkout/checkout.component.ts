import { Component, inject, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Store } from '@ngrx/store';
import { take } from 'rxjs';
import { CartActions } from '../../core/features/cart/store/cart.actions';
import { selectCartItems, selectCartTotal } from '../../core/features/cart/store/cart.selectors';
import { ApiService } from '../../core/services/api.service';

declare global {
  interface Window {
    Razorpay: any;
  }
}

@Component({
  selector: 'app-checkout',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
    <div class="container">
      <h1 class="page-title">Checkout</h1>
      @if ((items$ | async)?.length === 0) {
        <div class="empty">
          <p>Your cart is empty.</p>
          <a routerLink="/products" class="btn-shop">Continue Shopping</a>
        </div>
      } @else {
        <form [formGroup]="form" (ngSubmit)="onSubmit()">
          <div class="form-section">
            <h2>Shipping Address</h2>
            <input formControlName="name" placeholder="Full Name" />
            <input formControlName="phone" type="tel" placeholder="Phone" />
            <textarea formControlName="address" placeholder="Address (street, area)" rows="2"></textarea>
            <input formControlName="city" placeholder="City" />
            <input formControlName="state" placeholder="State" />
            <input formControlName="pincode" placeholder="Pincode" />
          </div>
          <div class="summary">
            <h3>Order Summary</h3>
            <p class="total">Total: ₹{{ total$ | async }}</p>
            <button type="submit" class="btn-pay" [disabled]="form.invalid || processing">
              {{ processing ? 'Processing...' : 'Pay ₹' + (total$ | async) }}
            </button>
            @if (error) { <p class="error">{{ error }}</p> }
          </div>
        </form>
      }
    </div>
  `,
  styles: [`
    .page-title { font-size: 1.75rem; margin-bottom: 1.5rem; }
    .empty { text-align: center; padding: 3rem; color: var(--text-secondary); }
    .btn-shop { display: inline-block; margin-top: 1rem; padding: 0.75rem 1.5rem; background: var(--color-primary); color: #fff; font-weight: 600; border-radius: var(--radius); }
    form { display: grid; gap: 2rem; max-width: 600px; }
    @media (min-width: 640px) { form { grid-template-columns: 1fr 280px; } }
    .form-section { display: flex; flex-direction: column; gap: 0.75rem; }
    .form-section h2, .summary h3 { font-size: 1.1rem; margin-bottom: 0.5rem; }
    input, textarea { padding: 0.75rem; border: 1px solid var(--border); border-radius: var(--radius-sm); }
    .summary { background: var(--bg-card); padding: 1.25rem; border-radius: var(--radius); height: fit-content; }
    .total { font-size: 1.25rem; font-weight: 600; margin: 1rem 0; }
    .btn-pay { padding: 0.75rem 1.5rem; background: var(--color-accent); color: #fff; font-weight: 600; border-radius: var(--radius); border: none; cursor: pointer; width: 100%; }
    .btn-pay:disabled { opacity: 0.6; cursor: not-allowed; }
    .error { color: var(--color-error); font-size: 0.875rem; margin-top: 0.5rem; }
  `],
})
export class CheckoutComponent implements OnInit, OnDestroy {
  private store = inject(Store);
  private router = inject(Router);
  private api = inject(ApiService);
  private fb = inject(FormBuilder);

  form = this.fb.group({
    name: ['', Validators.required],
    phone: ['', [Validators.required, Validators.pattern(/^[0-9]{10}$/)]],
    address: ['', Validators.required],
    city: ['', Validators.required],
    state: ['', Validators.required],
    pincode: ['', [Validators.required, Validators.pattern(/^[0-9]{6}$/)]],
  });

  items$ = this.store.select(selectCartItems);
  total$ = this.store.select(selectCartTotal);
  processing = false;
  error = '';

  private scriptLoaded = false;

  ngOnInit() {
    this.loadRazorpayScript();
  }

  ngOnDestroy() {}

  private loadRazorpayScript() {
    if (this.scriptLoaded || typeof window !== 'undefined') {
      if ((window as any).Razorpay) {
        this.scriptLoaded = true;
        return;
      }
    }
    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.async = true;
    document.head.appendChild(script);
    script.onload = () => { this.scriptLoaded = true; };
  }

  onSubmit() {
    this.error = '';
    if (this.form.invalid) return;
    this.processing = true;

    this.store.select(selectCartItems).pipe(take(1)).subscribe((items) => {
      if (!items?.length) {
        this.error = 'Cart is empty';
        this.processing = false;
        return;
      }
      const orderItems = items.map((i: any) => ({
        product: i.product._id,
        name: i.product.name,
        price: i.product.price,
        quantity: i.quantity,
        size: i.variant?.size || '',
        color: i.variant?.color || '',
      }));
      this.store.select(selectCartTotal).pipe(take(1)).subscribe((total) => {
        const shippingAddress = {
          name: this.form.value.name,
          phone: this.form.value.phone,
          address: this.form.value.address,
          city: this.form.value.city,
          state: this.form.value.state,
          pincode: this.form.value.pincode,
        };
        this.api
          .post<{ orderId: string; razorpayOrderId: string; amount: number; currency: string; key: string }>(
            '/orders/create-payment',
            { items: orderItems, totalAmount: total, shippingAddress }
          )
          .subscribe({
            next: (res) => {
              this.openRazorpay(res);
              this.processing = false;
            },
            error: (err) => {
              this.error = err.error?.message || 'Failed to create order';
              this.processing = false;
            },
          });
      });
    });
  }

  private openRazorpay(payload: { orderId: string; razorpayOrderId: string; amount: number; currency: string; key: string }) {
    if (!(window as any).Razorpay) {
      this.error = 'Payment module not loaded. Please refresh.';
      return;
    }
    const options = {
      key: payload.key,
      amount: payload.amount,
      currency: payload.currency,
      order_id: payload.razorpayOrderId,
      name: 'Kapda Junction',
      handler: (response: any) => {
        this.store.dispatch(CartActions.clearCart());
        this.router.navigate(['/orders', payload.orderId, 'success']);
      },
    };
    const rzp = new (window as any).Razorpay(options);
    rzp.on('payment.failed', () => {
      this.error = 'Payment failed. Please try again.';
    });
    rzp.open();
  }
}
