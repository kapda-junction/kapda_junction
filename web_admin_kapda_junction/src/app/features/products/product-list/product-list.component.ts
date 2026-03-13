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
    .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
    .btn { padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; border: 1px solid #ddd; background: #fff; text-decoration: none; color: inherit; }
    .btn.primary { background: #1a1a2e; color: #fff; border-color: #1a1a2e; }
    .btn.small { padding: 0.25rem 0.5rem; font-size: 0.85rem; }
    .btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .table-wrap { background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .table { width: 100%; border-collapse: collapse; }
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
    .pagination { display: flex; align-items: center; gap: 1rem; margin-top: 1.5rem; }
  `],
})
export class ProductListComponent implements OnInit {
  private productService = inject(ProductService);
  products: Product[] = [];
  loading = false;
  page = 1;
  totalPages = 1;

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
