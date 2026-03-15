import { Component, OnInit, ChangeDetectorRef, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { BannerService, BannerPayload } from '../../core/services/banner.service';
import { ProductService } from '../../core/services/product.service';
import { UploadService } from '../../core/services/upload.service';
import { SnackbarService } from '../../core/services/snackbar.service';

interface BannerItem {
  _id?: string;
  image: string;
  products: { _id?: string; name: string; price: number; images?: string[] }[];
  sortOrder?: number;
  isActive: boolean;
}

@Component({
  selector: 'app-banner-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  template: `
    <div class="page-header">
      <h1>Banners</h1>
      <button class="btn primary" (click)="openForm()">+ Add Banner</button>
    </div>
    <p class="hint">Upload a dedicated banner image, then add up to 4 clickable product patches (Instagram-style). Customers see the banner with product thumbnails overlaid.</p>

    @if (loadError) {
      <p class="error">{{ loadError }} <button class="btn small" (click)="load()">Retry</button></p>
    }
    @else if (loading) { <p class="loading">Loading...</p> }
    @else if (banners.length) {
      <div class="banner-grid">
        @for (b of banners; track b._id || b.image || $index) {
          <div class="banner-card">
            <div class="banner-preview" [style.backgroundImage]="'url(' + b.image + ')'"></div>
            <div class="banner-meta">
              <span class="product-count">{{ b.products.length || 0 }} products</span>
              <label class="toggle">
                <input type="checkbox" [checked]="b.isActive" (change)="toggleActive(b)" />
                Active
              </label>
            </div>
            <div class="actions">
              <button class="btn small" (click)="openForm(b)">Edit</button>
              <button class="btn small danger" (click)="deleteBanner(b)">Delete</button>
            </div>
          </div>
        }
      </div>
    }
    @else if (!loading && !loadError) { <p class="empty">No banners. Add a banner to show on the home page.</p> }

    @if (showForm) {
      <div class="modal-overlay" (click)="closeForm()">
        <div class="modal" (click)="$event.stopPropagation()">
          <h2>{{ editing ? 'Edit Banner' : 'Add Banner' }}</h2>
          <form (ngSubmit)="save()">
            <div class="field">
              <label>Banner Image *</label>
              <p class="hint">Upload any image – auto-resized to <strong>1920×1080 (16:9)</strong>. Easy to find: search "1920x1080 banner" or "full HD banner" on Google/Pexels/Unsplash.</p>
              <input type="file" #fileInput accept="image/*" (change)="onBannerSelect($event)" />
              @if (form.image) {
                <div class="img-preview"><img [src]="form.image" alt="Banner" /></div>
              }
            </div>
            <div class="field">
              <label>Products (max 4, clickable patches)</label>
              <p class="hint">Select products to show as clickable thumbnails on the banner.</p>
              <input type="text" [(ngModel)]="productSearch" name="search" placeholder="Search products..." (input)="searchProducts()" />
              @if (productResults.length) {
                <div class="product-results">
                  @for (p of productResults; track p._id) {
                    <label class="product-option" [class.selected]="selectedProductIds.includes(p._id)">
                      <input type="checkbox" [checked]="selectedProductIds.includes(p._id)" (change)="toggleProduct(p._id)" [disabled]="!selectedProductIds.includes(p._id) && selectedProductIds.length >= 4" />
                      <img [src]="p.images?.[0] || ''" alt="" class="thumb" />
                      <span>{{ p.name }} - ₹{{ p.price }}</span>
                    </label>
                  }
                </div>
              }
              @if (selectedProductIds.length) {
                <div class="selected-list">
                  <strong>Selected ({{ selectedProductIds.length }}/4):</strong>
                  @for (pid of selectedProductIds; track pid) {
                    @let p = getProductById(pid);
                    @if (p) {
                      <span class="chip">{{ p.name }} <button type="button" (click)="removeProduct(pid)">×</button></span>
                    }
                  }
                </div>
              }
            </div>
            <div class="field">
              <label><input type="checkbox" [(ngModel)]="form.isActive" name="isActive" /> Active</label>
            </div>
            <div class="modal-actions">
              <button type="button" class="btn" (click)="closeForm()">Cancel</button>
              <button type="submit" class="btn primary" [disabled]="!form.image || selectedProductIds.length === 0">Save</button>
            </div>
          </form>
        </div>
      </div>
    }
  `,
  styles: [`
    .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
    .hint { font-size: 0.9rem; color: #666; margin-bottom: 1rem; }
    .btn { padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; border: 1px solid #ddd; background: #fff; }
    .btn.primary { background: #1a1a2e; color: #fff; border-color: #1a1a2e; }
    .btn.small { padding: 0.25rem 0.5rem; font-size: 0.85rem; }
    .btn.danger { color: #dc3545; border-color: #dc3545; }
    .loading, .empty { padding: 2rem; text-align: center; color: #666; }
    .error { padding: 2rem; color: #dc3545; display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap; }
    .banner-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1.5rem; }
    .banner-card {
      background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08);
      display: flex; flex-direction: column;
    }
    .banner-preview { height: 120px; background-size: cover; background-position: center; background-color: #eee; }
    .banner-meta { padding: 0.75rem 1rem; display: flex; justify-content: space-between; align-items: center; }
    .product-count { font-size: 0.9rem; color: #666; }
    .toggle { display: flex; align-items: center; gap: 0.5rem; font-size: 0.9rem; cursor: pointer; }
    .actions { padding: 0 1rem 1rem; display: flex; gap: 0.5rem; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; overflow-y: auto; padding: 2rem; }
    .modal { background: #fff; padding: 2rem; border-radius: 12px; max-width: 520px; width: 100%; max-height: 90vh; overflow-y: auto; }
    .field { margin-bottom: 1.25rem; }
    .field label { display: block; font-weight: 500; margin-bottom: 0.35rem; font-size: 0.9rem; }
    .field .hint { margin: 0.25rem 0 0.5rem; font-size: 0.85rem; }
    .field input[type="text"], .field input[type="file"] { width: 100%; padding: 0.5rem; border: 1px solid #ddd; border-radius: 6px; }
    .img-preview { margin-top: 0.5rem; border-radius: 8px; overflow: hidden; max-height: 150px; }
    .img-preview img { width: 100%; height: auto; display: block; }
    .product-results { max-height: 160px; overflow-y: auto; border: 1px solid #eee; border-radius: 6px; margin-top: 0.5rem; }
    .product-option { display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem 0.75rem; cursor: pointer; border-bottom: 1px solid #f0f0f0; }
    .product-option:last-child { border-bottom: none; }
    .product-option:hover { background: #f9f9f9; }
    .product-option.selected { background: #e8f4fd; }
    .product-option .thumb { width: 36px; height: 36px; object-fit: cover; border-radius: 4px; }
    .product-option span { flex: 1; font-size: 0.9rem; }
    .selected-list { margin-top: 0.75rem; font-size: 0.9rem; }
    .selected-list .chip { display: inline-flex; align-items: center; gap: 0.25rem; background: #e8f4fd; padding: 0.25rem 0.5rem; border-radius: 4px; margin-right: 0.5rem; margin-bottom: 0.5rem; }
    .selected-list .chip button { background: none; border: none; cursor: pointer; padding: 0 0.25rem; font-size: 1rem; line-height: 1; }
    .modal-actions { display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid #eee; }
  `],
})
export class BannerListComponent implements OnInit {
  private bannerService = inject(BannerService);
  private productService = inject(ProductService);
  private snackbar = inject(SnackbarService);
  private uploadService = inject(UploadService);
  private cdr = inject(ChangeDetectorRef);

  banners: BannerItem[] = [];
  loading = false;
  loadError = '';
  showForm = false;
  editing: BannerItem | null = null;
  form: { image: string; isActive: boolean } = { image: '', isActive: true };
  selectedProductIds: string[] = [];
  allProducts: { _id: string; name: string; price: number; images?: string[] }[] = [];
  productSearch = '';
  productResults: { _id: string; name: string; price: number; images?: string[] }[] = [];
  searchDebounce: ReturnType<typeof setTimeout> | null = null;
  uploading = false;

  ngOnInit() {
    this.load();
    this.productService.getAll({ limit: 200 }).subscribe({
      next: (res) => {
        this.allProducts = (res.products || [])
          .filter((p) => p._id != null)
          .map((p) => ({ _id: p._id!, name: p.name, price: p.price, images: p.images }));
      }
    });
  }

  load() {
    this.loading = true;
    this.loadError = '';
    this.bannerService.getAll().subscribe({
      next: (data) => {
        const arr = Array.isArray(data) ? data : (data && typeof data === 'object' && 'banners' in data ? (data as { banners: unknown[] }).banners : []);
        this.banners = [...(Array.isArray(arr) ? arr : []).map((b: unknown) => ({
          ...(b as object),
          isActive: (b as { isActive?: boolean })?.isActive ?? true
        }))] as BannerItem[];
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loading = false;
        this.loadError = err?.status === 401 ? 'Please log in to view banners.' : err?.error?.message || 'Failed to load banners.';
        this.cdr.detectChanges();
      }
    });
  }

  openForm(b?: BannerItem) {
    this.editing = b || null;
    this.form = {
      image: b?.image || '',
      isActive: b?.isActive ?? true
    };
    this.selectedProductIds = (b?.products || []).map((p: any) => p._id).filter(Boolean);
    this.productSearch = '';
    this.productResults = this.allProducts.slice(0, 20);
    this.showForm = true;
  }

  closeForm() {
    this.showForm = false;
    this.editing = null;
  }

  onBannerSelect(ev: Event) {
    const input = ev.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.uploading = true;
    this.uploadService.uploadBanner(file).subscribe({
      next: (res) => {
        this.form.image = res.url;
        this.uploading = false;
        input.value = '';
      },
      error: () => { this.uploading = false; }
    });
  }

  searchProducts() {
    if (this.searchDebounce) clearTimeout(this.searchDebounce);
    this.searchDebounce = setTimeout(() => {
      const q = (this.productSearch || '').toLowerCase().trim();
      if (!q) {
        this.productResults = this.allProducts.slice(0, 20);
      } else {
        this.productResults = this.allProducts.filter(
          (p) => p.name.toLowerCase().includes(q) || String(p.price).includes(q)
        ).slice(0, 20);
      }
      this.searchDebounce = null;
    }, 200);
  }

  toggleProduct(id: string) {
    const idx = this.selectedProductIds.indexOf(id);
    if (idx >= 0) {
      this.selectedProductIds.splice(idx, 1);
    } else if (this.selectedProductIds.length < 4) {
      this.selectedProductIds.push(id);
    }
  }

  removeProduct(id: string) {
    this.selectedProductIds = this.selectedProductIds.filter((x) => x !== id);
  }

  getProductById(id: string) {
    return this.allProducts.find((p) => p._id === id) || this.editing?.products?.find((p: any) => p._id === id);
  }

  save() {
    if (!this.form.image || this.selectedProductIds.length === 0) {
      this.snackbar.showError('Upload banner image and select at least one product.');
      return;
    }
    const payload: BannerPayload = {
      image: this.form.image,
      products: this.selectedProductIds,
      isActive: this.form.isActive
    };
    this.snackbar.setLoading(true);
    if (this.editing?._id) {
      this.bannerService.update(this.editing._id, payload).subscribe({
        next: () => {
          this.snackbar.setLoading(false);
          this.snackbar.showSuccess('Banner updated');
          this.closeForm();
          this.load();
        },
        error: (e: { error?: { message?: string } }) => {
          this.snackbar.setLoading(false);
          this.snackbar.showError(e.error?.message || 'Update failed');
        }
      });
    } else {
      this.bannerService.create(payload).subscribe({
        next: () => {
          this.snackbar.setLoading(false);
          this.snackbar.showSuccess('Banner added');
          this.closeForm();
          this.load();
        },
        error: (e: { error?: { message?: string } }) => {
          this.snackbar.setLoading(false);
          this.snackbar.showError(e.error?.message || 'Create failed');
        }
      });
    }
  }

  toggleActive(b: BannerItem) {
    if (!b._id) return;
    const productIds = (b.products || []).map((p) => p._id).filter((id): id is string => !!id);
    this.bannerService.update(b._id, { image: b.image, products: productIds, isActive: !b.isActive }).subscribe({
      next: () => { this.snackbar.showSuccess('Banner updated'); this.load(); },
      error: (e) => this.snackbar.showError(e.error?.message || 'Update failed')
    });
  }

  deleteBanner(b: BannerItem) {
    if (!b._id || !confirm('Delete this banner?')) return;
    this.bannerService.delete(b._id).subscribe({
      next: () => this.load(),
      error: (e: { error?: { message?: string } }) => alert(e.error?.message || 'Delete failed')
    });
  }
}
