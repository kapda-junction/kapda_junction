import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { ProductActions } from '../../../core/features/products/store/product.actions';
import { selectAllProducts, selectProductsLoading } from '../../../core/features/products/store/product.selectors';
import { CartActions } from '../../../core/features/cart/store/cart.actions';
import { WhatsAppButtonComponent } from '../../../shared/whatsapp-button/whatsapp-button.component';
import { ProductImageSliderComponent } from '../../../shared/product-image-slider/product-image-slider.component';

@Component({
  selector: 'app-product-list',
  standalone: true,
  imports: [CommonModule, RouterLink, WhatsAppButtonComponent, ProductImageSliderComponent],
  template: `
    <div class="container">
      <h1 class="page-title">Men's Wear</h1>
      @if (loading$ | async) {
        <div class="loading">Loading...</div>
      } @else {
        <div class="grid">
          @for (p of products$ | async; track p._id) {
            <div class="card" [class.sold-out]="isFullySoldOut(p)">
              <a [routerLink]="['/products', p._id]" class="card-link">
                <div class="img-wrap">
                  <app-product-image-slider [images]="p.images" [alt]="p.name" />
                  @if (isFullySoldOut(p)) { <span class="badge-soldout">Sold Out</span> }
                  <div class="card-actions">
                    <app-whatsapp-button [product]="p" [inline]="true"></app-whatsapp-button>
                  </div>
                </div>
                <h3>{{ p.name }}</h3>
              </a>
              <p class="price">₹{{ p.price }}</p>
              @if (hasVariants(p)) {
                <a [routerLink]="['/products', p._id]" class="btn-select">View Product</a>
              } @else {
                <button (click)="addToCart(p)" [disabled]="isFullySoldOut(p)">Add to Cart</button>
              }
            </div>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .page-title { font-size: 1.75rem; margin-bottom: 1.5rem; color: var(--text-primary); }
    .loading { padding: 3rem; text-align: center; color: var(--text-secondary); }
    .grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 1rem;
    }
    @media (min-width: 640px) {
      .grid { grid-template-columns: repeat(3, 1fr); gap: 1.25rem; }
    }
    @media (min-width: 1024px) {
      .grid { grid-template-columns: repeat(4, 1fr); gap: 1.5rem; }
    }
    .card {
      background: var(--bg-card);
      border-radius: var(--radius);
      overflow: hidden;
      box-shadow: var(--shadow-sm);
      transition: box-shadow var(--transition);
    }
    .card:hover { box-shadow: var(--shadow); }
    .card.sold-out { opacity: 0.85; }
    .card-link { display: block; padding: 0; }
    .img-wrap { position: relative; aspect-ratio: 1; overflow: hidden; }
    .card img { width: 100%; height: 100%; object-fit: cover; }
    .badge-soldout {
      position: absolute; inset: 0;
      display: flex; align-items: center; justify-content: center;
      background: var(--bg-overlay);
      color: #fff; font-weight: 600; font-size: 0.9rem;
    }
    .card h3 { padding: 0.75rem 1rem 0; font-size: 1rem; }
    .price { padding: 0 1rem; font-weight: 700; color: var(--color-primary); }
    button {
      width: 100%; margin: 0.75rem 1rem 1rem; padding: 0.6rem;
      background: var(--color-primary);
      color: #fff; border-radius: var(--radius-sm);
      font-weight: 500; cursor: pointer;
      transition: opacity var(--transition);
    }
    button:hover:not(:disabled) { opacity: 0.9; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .btn-select {
      display: block; width: 100%; margin: 0.75rem 1rem 1rem; padding: 0.6rem;
      background: var(--color-primary); color: #fff; text-align: center;
      border-radius: var(--radius-sm); font-weight: 500; text-decoration: none; font-size: 0.9rem;
    }
    .btn-select:hover { opacity: 0.9; color: #fff; }
  `],
})
export class ProductListComponent implements OnInit {
  private store = inject(Store);
  products$ = this.store.select(selectAllProducts);
  loading$ = this.store.select(selectProductsLoading);

  ngOnInit() {
    this.store.dispatch(ProductActions.loadProductsRequest());
  }

  hasVariants(p: any): boolean {
    return !!(p?.variants?.length);
  }

  isFullySoldOut(p: any): boolean {
    if (!p?.variants?.length) return !!p?.soldOut;
    return p.variants.every((v: any) => (v?.stock ?? 0) <= 0);
  }

  addToCart(p: any) {
    this.store.dispatch(CartActions.addItem({ product: p, quantity: 1 }));
  }
}
