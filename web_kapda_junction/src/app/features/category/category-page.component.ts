import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { Store } from '@ngrx/store';
import { CartActions } from '../../core/features/cart/store/cart.actions';
import { WhatsAppButtonComponent } from '../../shared/whatsapp-button/whatsapp-button.component';
import { ProductImageSliderComponent } from '../../shared/product-image-slider/product-image-slider.component';

@Component({
  selector: 'app-category-page',
  standalone: true,
  imports: [CommonModule, RouterLink, WhatsAppButtonComponent, ProductImageSliderComponent],
  template: `
    <div class="container layout">
      <aside class="sidebar">
        <h3>Filters</h3>
        <div class="filter-group">
          <label>Price</label>
          <div class="price-inputs">
            <input type="number" placeholder="Min" [value]="minPrice" (input)="minPrice = $any($event.target).value" />
            <span>–</span>
            <input type="number" placeholder="Max" [value]="maxPrice" (input)="maxPrice = $any($event.target).value" />
          </div>
          <button type="button" class="btn-apply" (click)="load()">Apply</button>
        </div>
        @if (subcategories().length) {
          <div class="filter-group">
            <label>Subcategory</label>
            <div class="chips">
              <button type="button" class="chip" [class.active]="!selectedSub()" (click)="selectSub(null)">All</button>
              @for (s of subcategories(); track s._id) {
                <button type="button" class="chip" [class.active]="selectedSub() === s._id" (click)="selectSub(s._id)">
                  {{ s.name }}
                </button>
              }
            </div>
          </div>
        }
        <button type="button" class="btn-clear" (click)="clearFilters()">Clear filters</button>
      </aside>
      <main class="main">
        <h1 class="page-title">{{ categoryName() }}</h1>
        @if (loading()) { <div class="loading">Loading...</div> }
        @else if (products().length === 0) { <p class="empty">No products found.</p> }
        @else {
          <div class="grid">
            @for (p of products(); track p._id) {
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
                  <button (click)="addToCart(p); $event.preventDefault()" [disabled]="isFullySoldOut(p)">Add to Cart</button>
                }
              </div>
            }
          </div>
          @if (total() > products().length) {
            <div class="load-more">
              <button type="button" (click)="loadMore()">Load More</button>
            </div>
          }
        }
      </main>
    </div>
  `,
  styles: [`
    .layout {
      display: grid;
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }
    @media (min-width: 1024px) {
      .layout { grid-template-columns: 220px 1fr; }
    }
    .sidebar {
      background: var(--bg-card);
      padding: 1.25rem;
      border-radius: var(--radius);
      box-shadow: var(--shadow-sm);
      height: fit-content;
    }
    .sidebar h3 { font-size: 1rem; margin-bottom: 1rem; }
    .filter-group { margin-bottom: 1rem; }
    .filter-group label { display: block; font-size: 0.85rem; font-weight: 600; margin-bottom: 0.5rem; }
    .price-inputs { display: flex; align-items: center; gap: 0.5rem; }
    .price-inputs input { width: 70px; padding: 0.4rem; border: 1px solid var(--border); border-radius: var(--radius-sm); }
    .btn-apply { margin-top: 0.5rem; padding: 0.4rem 0.75rem; font-size: 0.85rem; background: var(--color-primary); color: #fff; border-radius: var(--radius-sm); }
    .chips { display: flex; flex-wrap: wrap; gap: 0.35rem; }
    .chip {
      padding: 0.3rem 0.6rem;
      font-size: 0.85rem;
      border: 1px solid var(--border);
      background: var(--bg-body);
      border-radius: var(--radius-sm);
      cursor: pointer;
    }
    .chip.active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
    .btn-clear { margin-top: 0.5rem; font-size: 0.85rem; color: var(--text-secondary); }
    .btn-clear:hover { color: var(--color-primary); }
    .page-title { font-size: 1.5rem; margin-bottom: 1rem; }
    .loading, .empty { padding: 2rem; text-align: center; color: var(--text-secondary); }
    .grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 1rem;
    }
    @media (min-width: 640px) { .grid { grid-template-columns: repeat(3, 1fr); } }
    @media (min-width: 1024px) { .grid { grid-template-columns: repeat(4, 1fr); } }
    .card {
      background: var(--bg-card);
      border-radius: var(--radius);
      overflow: hidden;
      box-shadow: var(--shadow-sm);
    }
    .img-wrap { position: relative; aspect-ratio: 1; overflow: hidden; }
    .img-wrap:hover .card-actions { opacity: 1; }
    .card-actions { position: absolute; bottom: 0.5rem; right: 0.5rem; opacity: 0; transition: opacity var(--transition); }
    .card img { width: 100%; height: 100%; object-fit: cover; }
    .badge-soldout {
      position: absolute; inset: 0;
      display: flex; align-items: center; justify-content: center;
      background: var(--bg-overlay);
      color: #fff; font-weight: 600; font-size: 0.85rem;
    }
    .card h3 { padding: 0.6rem 0.75rem 0; font-size: 0.95rem; }
    .price { padding: 0 0.75rem; font-weight: 700; color: var(--color-primary); }
    button {
      width: 100%; margin: 0.5rem 0.75rem 0.75rem; padding: 0.5rem;
      background: var(--color-primary);
      color: #fff; border-radius: var(--radius-sm);
      font-weight: 500; cursor: pointer; font-size: 0.85rem;
    }
    button:hover:not(:disabled) { opacity: 0.9; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .load-more { text-align: center; margin-top: 2rem; }
    .load-more button { width: auto; padding: 0.6rem 1.5rem; }
    .btn-select {
      display: block; width: 100%; margin: 0.5rem 0.75rem 0.75rem; padding: 0.5rem;
      background: var(--color-primary); color: #fff; text-align: center;
      border-radius: var(--radius-sm); font-weight: 500; text-decoration: none; font-size: 0.85rem;
    }
    .btn-select:hover { opacity: 0.9; color: #fff; }
  `],
})
export class CategoryPageComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private api = inject(ApiService);
  private store = inject(Store);

  categoryId = '';
  categoryName = signal('');
  subcategories = signal<any[]>([]);
  products = signal<any[]>([]);
  total = signal(0);
  loading = signal(true);
  page = signal(1);
  minPrice = '';
  maxPrice = '';
  selectedSub = signal<string | null>(null);

  ngOnInit() {
    this.route.paramMap.subscribe((params) => {
      this.categoryId = params.get('id') ?? '';
      this.page.set(1);
      this.loadCategory();
      this.load();
    });
  }

  loadCategory() {
    if (!this.categoryId) return;
    this.api.get<any>(`/categories/${this.categoryId}`).subscribe({
      next: (cat) => {
        this.categoryName.set(cat?.name ?? 'Category');
      },
    });
    this.api.get<any[]>('/categories').subscribe({
      next: (list) => {
        const subs = (list ?? []).filter(
          (c: any) => String(c.parent?._id ?? c.parent ?? '') === this.categoryId
        );
        this.subcategories.set(subs);
      },
    });
  }

  load() {
    if (!this.categoryId) return;
    this.loading.set(true);
    const params: Record<string, string> = {
      category: this.categoryId,
      page: '1',
      limit: '12',
    };
    if (this.minPrice) params['minPrice'] = this.minPrice;
    if (this.maxPrice) params['maxPrice'] = this.maxPrice;
    const sub = this.selectedSub();
    if (sub) params['subcategory'] = sub;
    this.api.get<{ products: any[]; total: number; totalPages: number }>('/products', params).subscribe({
      next: (res) => {
        const prods = (res as any)?.products ?? [];
        this.products.set(prods);
        this.total.set((res as any)?.total ?? 0);
        this.page.set(1);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  loadMore() {
    const p = this.page() + 1;
    this.loading.set(true);
    const params: Record<string, string> = {
      category: this.categoryId,
      page: String(p),
      limit: '12',
    };
    if (this.minPrice) params['minPrice'] = this.minPrice;
    if (this.maxPrice) params['maxPrice'] = this.maxPrice;
    const sub = this.selectedSub();
    if (sub) params['subcategory'] = sub;
    this.api.get<{ products: any[] }>('/products', params).subscribe({
      next: (res) => {
        const prods = (res as any)?.products ?? [];
        this.products.update((prev) => [...prev, ...prods]);
        this.page.set(p);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  selectSub(id: string | null) {
    this.selectedSub.set(id);
    this.load();
  }

  clearFilters() {
    this.minPrice = '';
    this.maxPrice = '';
    this.selectedSub.set(null);
    this.load();
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
