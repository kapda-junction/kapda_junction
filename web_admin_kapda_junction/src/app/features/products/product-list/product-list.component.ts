import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ProductService, Product } from '../../../core/services/product.service';
import { inject } from '@angular/core';

@Component({
  selector: 'app-product-list',
  standalone: true,
  imports: [CommonModule, RouterLink],
  template: `
    <div class="page-header">
      <h1>Products</h1>
      <a routerLink="/products/new" class="btn primary">+ Add Product</a>
    </div>

    @if (loading) { <p class="loading">Loading...</p> }
    @else if (products.length) {
      <!-- Mobile: card layout with gallery pattern -->
      <div class="product-cards">
        @for (p of products; track p._id) {
          <div class="card">
            <div class="card-gallery">
              <div class="card-main-img">
                @if (p.images && p.images.length) {
                  <img [src]="getMainImage(p)" [alt]="p.name" />
                } @else {
                  <span class="no-img">No image</span>
                }
              </div>
              @if (p.images && p.images.length > 1) {
                <div class="card-thumbs">
                  @for (img of p.images; track img; let i = $index) {
                    <button type="button" class="card-thumb" [class.active]="getSelectedIndex(p) === i" (click)="selectProductImage(p, i)">
                      <img [src]="img" [alt]="p.name" />
                    </button>
                  }
                </div>
              }
            </div>
            <div class="card-body">
              <h3 class="card-name">{{ p.name }}</h3>
              <p class="card-meta">{{ getCatName(p) }} · ₹{{ p.price }}</p>
              <p class="card-variants">{{ getVariantSummary(p) }}</p>
              <div class="card-badges">
                <span class="badge" [class.active]="p.isActive" [class.inactive]="!p.isActive">
                  {{ p.isActive ? 'Active' : 'Hidden' }}
                </span>
                @if (p.soldOut) {
                  <span class="badge sold">Sold Out</span>
                }
              </div>
              <a [routerLink]="['/products', p._id, 'edit']" class="btn small">Edit</a>
            </div>
          </div>
        }
      </div>

      <!-- Desktop: table -->
      <div class="table-wrap">
        <table class="table">
          <thead>
            <tr>
              <th>Image</th>
              <th>Name</th>
              <th>Category</th>
              <th>Price</th>
              <th>Variants / Stock</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            @for (p of products; track p._id) {
              <tr>
                <td>
                  @if (p.images && p.images.length) {
                    <img [src]="p.images[0]" [alt]="p.name" class="thumb" />
                  } @else {
                    <span class="no-img">—</span>
                  }
                </td>
                <td>{{ p.name }}</td>
                <td>{{ getCatName(p) }}</td>
                <td>₹{{ p.price }}</td>
                <td>
                  <span class="variants">{{ getVariantSummary(p) }}</span>
                </td>
                <td>
                  <span class="badge" [class.active]="p.isActive" [class.inactive]="!p.isActive">
                    {{ p.isActive ? 'Active' : 'Hidden' }}
                  </span>
                  @if (p.soldOut) {
                    <span class="badge sold">Sold Out</span>
                  }
                </td>
                <td>
                  <a [routerLink]="['/products', p._id, 'edit']" class="btn small">Edit</a>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>

      @if (totalPages > 1) {
        <div class="pagination">
          <button class="btn small" [disabled]="page <= 1" (click)="goPage(page - 1)">Prev</button>
          <span>Page {{ page }} of {{ totalPages }}</span>
          <button class="btn small" [disabled]="page >= totalPages" (click)="goPage(page + 1)">Next</button>
        </div>
      }
    }
    @else {
      <p class="empty">No products yet. <a routerLink="/products/new">Add your first product</a></p>
    }
  `,
  styles: [`
    .page-header { display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 1.5rem; }
    @media (min-width: 480px) { .page-header { flex-direction: row; justify-content: space-between; align-items: center; } }
    .btn { padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; border: 1px solid #ddd; background: #fff; text-decoration: none; color: inherit; }
    .btn.primary { background: #1a1a2e; color: #fff; border-color: #1a1a2e; }
    .btn.small { padding: 0.25rem 0.5rem; font-size: 0.85rem; }
    .btn:disabled { opacity: 0.5; cursor: not-allowed; }
    /* Mobile: card layout */
    .product-cards { display: grid; gap: 1rem; margin-bottom: 1rem; }
    @media (min-width: 768px) { .product-cards { display: none; } }
    .product-cards .card { background: #fff; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); overflow: hidden; display: flex; flex-direction: column; }
    .product-cards .card-gallery {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
      padding: 0.75rem;
      background: #f8f9fa;
    }
    .product-cards .card-main-img {
      width: 100%;
      aspect-ratio: 1;
      max-height: 240px;
      background: #fff;
      border-radius: 8px;
      overflow: hidden;
      position: relative;
    }
    .product-cards .card-main-img img { width: 100%; height: 100%; object-fit: contain; }
    .product-cards .card-main-img .no-img { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: #999; font-size: 0.8rem; }
    .product-cards .card-thumbs {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(48px, 1fr));
      gap: 0.4rem;
      justify-content: start;
    }
    .product-cards .card-thumb {
      width: 48px;
      height: 48px;
      padding: 0;
      border-radius: 6px;
      overflow: hidden;
      border: 2px solid transparent;
      cursor: pointer;
      flex-shrink: 0;
      background: #fff;
    }
    .product-cards .card-thumb.active { border-color: #1a1a2e; }
    .product-cards .card-thumb img { width: 100%; height: 100%; object-fit: cover; }
    .product-cards .card-body { padding: 1rem; display: flex; flex-direction: column; gap: 0.5rem; }
    .product-cards .card-name { margin: 0; font-size: 1rem; font-weight: 600; line-height: 1.3; }
    .product-cards .card-meta { margin: 0; font-size: 0.875rem; color: #555; }
    .product-cards .card-variants { margin: 0; font-size: 0.8rem; color: #777; }
    .product-cards .card-badges { display: flex; flex-wrap: wrap; gap: 0.25rem; }
    .product-cards .card-body .btn { align-self: flex-start; margin-top: 0.25rem; }
    /* Desktop: table */
    .table-wrap { display: none; }
    @media (min-width: 768px) { .table-wrap { display: block; background: #fff; border-radius: 8px; overflow-x: auto; overflow-y: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); -webkit-overflow-scrolling: touch; } }
    .table { width: 100%; min-width: 600px; border-collapse: collapse; }
    .table th, .table td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid #eee; }
    .table th { background: #f8f9fa; font-weight: 600; }
    .thumb { width: 50px; height: 50px; object-fit: cover; border-radius: 6px; }
    .no-img { color: #999; font-size: 0.9rem; }
    .variants { font-size: 0.85rem; color: #555; }
    .badge { font-size: 0.75rem; padding: 0.2rem 0.5rem; border-radius: 4px; margin-right: 0.25rem; }
    .badge.active { background: #d4edda; color: #155724; }
    .badge.inactive { background: #f8d7da; color: #721c24; }
    .badge.sold { background: #fff3cd; color: #856404; }
    .loading, .empty { padding: 2rem; text-align: center; color: #666; }
    .empty a { color: #1a1a2e; text-decoration: underline; }
    .pagination { display: flex; flex-wrap: wrap; align-items: center; justify-content: center; gap: 0.75rem; margin-top: 1.5rem; font-size: 0.9rem; }
  `],
})
export class ProductListComponent implements OnInit {
  private productService = inject(ProductService);
  products: Product[] = [];
  loading = false;
  page = 1;
  totalPages = 1;
  selectedImgIndex: Record<string, number> = {};

  getMainImage(p: Product): string {
    const imgs = (p as any).images ?? [];
    const key = p._id ?? '';
    const idx = this.selectedImgIndex[key] ?? 0;
    return imgs[idx] ?? imgs[0] ?? '';
  }

  getSelectedIndex(p: Product): number {
    const key = p._id ?? '';
    return this.selectedImgIndex[key] ?? 0;
  }

  selectProductImage(p: Product, i: number) {
    const key = p._id ?? '';
    this.selectedImgIndex = { ...this.selectedImgIndex, [key]: i };
  }

  ngOnInit() {
    this.load();
  }

  load() {
    this.loading = true;
    this.productService.getAll({ page: this.page, limit: 20 }).subscribe({
      next: (res) => {
        this.products = res.products || [];
        this.totalPages = res.totalPages || 1;
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  goPage(p: number) {
    this.page = p;
    this.load();
  }

  getCatName(p: Product): string {
    const cat = (p as any).category;
    if (!cat) return '—';
    return typeof cat === 'object' && cat?.name ? cat.name : '—';
  }

  getVariantSummary(p: Product): string {
    const v = p.variants || [];
    if (!v.length) return '—';
    const total = v.reduce((s, x) => s + (x.stock || 0), 0);
    return v.length + ' variant(s), ' + total + ' in stock';
  }
}
