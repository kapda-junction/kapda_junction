import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, map } from 'rxjs/operators';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ProductActions } from '../../../core/features/products/store/product.actions';
import { selectAllProducts, selectProductsLoading } from '../../../core/features/products/store/product.selectors';
import { CartActions } from '../../../core/features/cart/store/cart.actions';
import { WhatsAppButtonComponent } from '../../../shared/whatsapp-button/whatsapp-button.component';
import { ProductImageSliderComponent } from '../../../shared/product-image-slider/product-image-slider.component';
import { ProductPriceComponent } from '../../../shared/product-price/product-price.component';

@Component({
  selector: 'app-product-list',
  standalone: true,
  imports: [CommonModule, RouterLink, WhatsAppButtonComponent, ProductImageSliderComponent, ProductPriceComponent],
  template: `
    <div class="container">
      <h1 class="page-title">Men's Wear</h1>
      <div class="search-row">
        <label class="sr-only" for="shop-search">Search products</label>
        <input
          id="shop-search"
          type="search"
          class="search-input"
          placeholder="Search by name or description..."
          autocomplete="off"
          [value]="listSearchValue"
          (input)="onSearchInput($event)"
        />
      </div>
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
              <p class="price"><app-product-price [price]="p.price" [compareAtPrice]="p.compareAtPrice" /></p>
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
    .page-title { font-size: 1.75rem; margin-bottom: 0.75rem; color: var(--text-primary); }
    .search-row { margin-bottom: 1.25rem; }
    .search-input {
      width: 100%; max-width: 28rem;
      padding: 0.65rem 0.9rem;
      border: 1px solid var(--border-color, #e2e8f0);
      border-radius: var(--radius-sm);
      font-size: 1rem;
      background: var(--bg-card);
      color: var(--text-primary);
    }
    .search-input:focus { outline: 2px solid var(--color-primary); outline-offset: 1px; }
    .sr-only {
      position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px;
      overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0;
    }
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
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private destroyRef = inject(DestroyRef);
  private searchTerms = new Subject<string>();

  products$ = this.store.select(selectAllProducts);
  loading$ = this.store.select(selectProductsLoading);
  listSearchValue = '';

  constructor() {
    this.searchTerms
      .pipe(debounceTime(350), distinctUntilChanged(), takeUntilDestroyed())
      .subscribe((term) => {
        const t = term.trim();
        this.router.navigate(['/products'], {
          queryParams: t ? { search: t } : {},
          replaceUrl: true,
        });
      });
  }

  ngOnInit() {
    this.route.queryParamMap
      .pipe(
        map((p) => p.get('search') || ''),
        distinctUntilChanged(),
        takeUntilDestroyed(this.destroyRef)
      )
      .subscribe((term) => {
        this.listSearchValue = term;
        this.store.dispatch(
          ProductActions.loadProductsRequest({ params: term ? { search: term } : {} })
        );
      });
  }

  onSearchInput(ev: Event) {
    const v = (ev.target as HTMLInputElement)?.value ?? '';
    this.listSearchValue = v;
    this.searchTerms.next(v);
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
