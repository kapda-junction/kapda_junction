import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { ProductService, Product, ProductVariant } from '../../../core/services/product.service';
import { CategoryService, Category } from '../../../core/services/category.service';
import { ColorService } from '../../../core/services/color.service';
import { SizeService } from '../../../core/services/size.service';
import { UploadService } from '../../../core/services/upload.service';

@Component({
  selector: 'app-product-form',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  template: `
    <div class="page-header">
      <h1>{{ id ? 'Edit Product' : 'Add Product' }}</h1>
      <a routerLink="/products" class="btn">← Back</a>
    </div>

    <form (ngSubmit)="save()" class="form-card">
      <div class="grid">
        <div class="section">
          <h3>Basic Info</h3>
          <div class="field">
            <label>Name *</label>
            <input [(ngModel)]="form.name" name="name" required />
          </div>
          <div class="field">
            <label>Description</label>
            <textarea [(ngModel)]="form.description" name="desc" rows="4"></textarea>
          </div>
          <div class="field-row">
            <div class="field">
              <label>Price (₹) *</label>
              <input type="number" [(ngModel)]="form.price" name="price" min="0" step="0.01" required />
            </div>
            <div class="field">
              <label>Compare at Price (₹)</label>
              <input type="number" [(ngModel)]="form.compareAtPrice" name="compareAtPrice" min="0" step="0.01" />
            </div>
          </div>
        </div>

        <div class="section">
          <h3>Category</h3>
          <div class="field">
            <label>Category *</label>
            <select [(ngModel)]="form.category" name="category" (ngModelChange)="onCategoryChange()" required>
              <option value="">-- Select --</option>
              @for (c of parentCategories; track c._id) {
                <option [ngValue]="c._id">{{ c.name }}</option>
              }
            </select>
          </div>
          <div class="field">
            <label>Subcategory</label>
            <select [(ngModel)]="form.subcategory" name="subcategory">
              <option [ngValue]="null">-- None --</option>
              @for (c of subcategories; track c._id) {
                <option [ngValue]="c._id">{{ c.name }}</option>
              }
            </select>
          </div>
          <div class="field">
            <label><input type="checkbox" [(ngModel)]="form.isActive" name="isActive" /> Visible to customers</label>
          </div>
          <p class="hint">To show products on the home banner, use <a routerLink="/banners">Banners</a>.</p>
        </div>
      </div>

      <div class="section">
        <h3>Images</h3>
        <p class="hint">You can select and upload multiple images at once. Product page will show a gallery; cards will use a slider.</p>
        <div class="field">
          <input type="file" #fileInput accept="image/*" multiple (change)="onImagesSelect($event)" />
        </div>
        <div class="image-preview">
          @for (url of form.images; track url) {
            <div class="thumb">
              <img [src]="url" alt="Product" />
              <button type="button" class="remove" (click)="removeImage(url)">×</button>
            </div>
          }
        </div>
      </div>

      <div class="section">
        <h3>Variants (Color × Size + Stock)</h3>
        <p class="hint">Select colors and sizes from the lists below. Add them first in <a routerLink="/colors">Colors</a> and <a routerLink="/sizes">Sizes</a> if empty. Set stock per combo — 0 = sold out.</p>
        <div class="variant-select-row">
          <div class="field">
            <label>Colors (multi-select)</label>
            <div class="checkbox-group">
              @for (c of colors; track c._id) {
                <label class="checkbox-label">
                  <input type="checkbox" [checked]="selectedColors.includes(c.name)" (change)="toggleColor(c.name)" />
                  {{ c.name }}
                </label>
              }
            </div>
            @if (!colors.length) { <span class="muted">Add colors first</span> }
          </div>
          <div class="field">
            <label>Sizes (multi-select)</label>
            <div class="checkbox-group">
              @for (s of sizes; track s._id) {
                <label class="checkbox-label">
                  <input type="checkbox" [checked]="selectedSizes.includes(s.name)" (change)="toggleSize(s.name)" />
                  {{ s.name }}
                </label>
              }
            </div>
            @if (!sizes.length) { <span class="muted">Add sizes first</span> }
          </div>
        </div>
        @if (selectedColors.length && selectedSizes.length) {
          <div class="stock-matrix">
            <h4>Stock per Color × Size</h4>
            <table class="variant-table">
              <thead>
                <tr><th>Color</th>
                  @for (sz of selectedSizes; track sz) { <th>{{ sz }}</th> }
                </tr>
              </thead>
              <tbody>
                @for (clr of selectedColors; track clr) {
                  <tr>
                    <td class="color-cell">{{ clr }}</td>
                    @for (sz of selectedSizes; track sz) {
                      <td>
                        <input type="number" [value]="getStock(clr, sz)" (input)="setStock(clr, sz, $any($event.target).value)" min="0" class="stock-input" />
                      </td>
                    }
                  </tr>
                }
              </tbody>
            </table>
          </div>
        }
      </div>

      <div class="form-actions">
        <button type="button" class="btn" routerLink="/products">Cancel</button>
        <button type="submit" class="btn primary" [disabled]="!form.name?.trim() || !form.category || !selectedColors.length || !selectedSizes.length">Save</button>
      </div>
    </form>
  `,
  styles: [`
    :host { display: block; width: 100%; min-width: 0; overflow-x: hidden; }
    .page-header { display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 1.5rem; align-items: flex-start; }
    @media (min-width: 480px) { .page-header { flex-direction: row; justify-content: space-between; align-items: center; } }
    .page-header h1 { font-size: 1.25rem; margin: 0; word-break: break-word; }
    @media (min-width: 480px) { .page-header h1 { font-size: 1.5rem; } }
    .btn { padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; border: 1px solid #ddd; background: #fff; text-decoration: none; color: inherit; font-size: 0.9rem; min-height: 44px; display: inline-flex; align-items: center; justify-content: center; }
    .btn.primary { background: #1a1a2e; color: #fff; border-color: #1a1a2e; }
    .btn.small { padding: 0.25rem 0.5rem; font-size: 0.85rem; min-height: 36px; }
    .btn.danger { color: #dc3545; border-color: #dc3545; }
    .form-card { background: #fff; padding: 1rem; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); width: 100%; max-width: 100%; min-width: 0; box-sizing: border-box; }
    @media (min-width: 640px) { .form-card { padding: 1.5rem; } }
    @media (min-width: 768px) { .form-card { padding: 2rem; } }
    .grid { display: block; margin-bottom: 1.5rem; }
    @media (min-width: 768px) { .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin-bottom: 2rem; } }
    .section { margin-bottom: 1.5rem; }
    @media (min-width: 768px) { .section { margin-bottom: 2rem; } }
    .section h3 { margin-bottom: 0.75rem; font-size: 1rem; }
    @media (min-width: 480px) { .section h3 { font-size: 1.1rem; margin-bottom: 1rem; } }
    .field { margin-bottom: 0.75rem; }
    @media (min-width: 480px) { .field { margin-bottom: 1rem; } }
    .field label { display: block; font-weight: 500; margin-bottom: 0.3rem; font-size: 0.875rem; }
    .field input, .field select, .field textarea { width: 100%; padding: 0.5rem 0.6rem; border: 1px solid #ddd; border-radius: 8px; font-size: 1rem; max-width: 100%; box-sizing: border-box; }
    .field input[type="file"] { font-size: 0.9rem; min-height: 44px; }
    .field textarea { min-height: 100px; resize: vertical; }
    .field-row { display: flex; flex-direction: column; gap: 0.75rem; }
    @media (min-width: 480px) { .field-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; } }
    .image-preview { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.5rem; }
    .thumb { position: relative; width: 72px; height: 72px; flex-shrink: 0; }
    @media (min-width: 480px) { .thumb { width: 80px; height: 80px; } }
    .thumb img { width: 100%; height: 100%; object-fit: cover; border-radius: 8px; }
    .thumb .remove { position: absolute; top: -4px; right: -4px; width: 22px; height: 22px; border-radius: 50%; background: #dc3545; color: #fff; border: none; cursor: pointer; font-size: 1rem; line-height: 1; }
    .hint { font-size: 0.8rem; color: #666; margin-bottom: 0.75rem; line-height: 1.4; }
    .hint a { color: #1a1a2e; text-decoration: underline; }
    .variant-table { width: 100%; border-collapse: collapse; min-width: 240px; }
    .variant-table th, .variant-table td { padding: 0.4rem 0.5rem; text-align: left; border-bottom: 1px solid #eee; font-size: 0.875rem; }
    .variant-table th { background: #f8f9fa; font-weight: 600; }
    .variant-table input { width: 100%; padding: 0.35rem; max-width: 56px; }
    .variant-select-row { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
    @media (min-width: 640px) { .variant-select-row { flex-direction: row; grid-template-columns: 1fr 1fr; gap: 1.5rem; display: grid; } }
    .checkbox-group { display: flex; flex-wrap: wrap; gap: 0.4rem 0.75rem; }
    .checkbox-label { display: inline-flex; align-items: center; gap: 0.35rem; cursor: pointer; font-size: 0.875rem; }
    .muted { color: #999; font-size: 0.85rem; }
    .stock-matrix { margin-top: 1rem; overflow-x: auto; -webkit-overflow-scrolling: touch; }
    .stock-matrix h4 { font-size: 0.95rem; margin-bottom: 0.5rem; }
    .stock-input { width: 52px; text-align: center; }
    @media (min-width: 480px) { .stock-input { width: 60px; } }
    .color-cell { font-weight: 500; }
    .form-actions { display: flex; flex-direction: column-reverse; gap: 0.75rem; margin-top: 1.5rem; padding-top: 1.25rem; border-top: 1px solid #eee; }
    @media (min-width: 480px) { .form-actions { flex-direction: row; justify-content: flex-end; gap: 1rem; margin-top: 2rem; padding-top: 1.5rem; } }
    .form-actions .btn { width: 100%; text-align: center; }
    @media (min-width: 480px) { .form-actions .btn { width: auto; } }
  `],
})
export class ProductFormComponent implements OnInit {
  private productService = inject(ProductService);
  private categoryService = inject(CategoryService);
  private colorService = inject(ColorService);
  private sizeService = inject(SizeService);
  private uploadService = inject(UploadService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  id: string | null = null;
  colors: { _id: string; name: string }[] = [];
  sizes: { _id: string; name: string }[] = [];
  selectedColors: string[] = [];
  selectedSizes: string[] = [];
  stockMatrix: Record<string, number> = {};

  form: Partial<Product> = {
    name: '',
    description: '',
    price: 0,
    compareAtPrice: undefined,
    category: '',
    subcategory: undefined,
    images: [],
    variants: [{ color: '', size: '', stock: 1 }],
    isActive: true,
  };
  parentCategories: Category[] = [];
  subcategories: Category[] = [];
  loading = false;
  uploading = false;

  ngOnInit() {
    this.id = this.route.snapshot.paramMap.get('id');
    this.loadColors();
    this.loadSizes();
    this.categoryService.getTree().subscribe({
      next: (data: any) => {
        this.parentCategories = Array.isArray(data) ? data : [];
        if (this.id) this.loadProduct();
        else this.onCategoryChange();
      },
    });
  }

  loadColors() {
    this.colorService.getAll().subscribe({
      next: (data) => { this.colors = data || []; },
      error: () => { this.colors = []; }
    });
  }

  loadSizes() {
    this.sizeService.getAll().subscribe({
      next: (data) => { this.sizes = data || []; },
      error: () => { this.sizes = []; }
    });
  }

  toggleColor(name: string) {
    const i = this.selectedColors.indexOf(name);
    if (i >= 0) this.selectedColors.splice(i, 1);
    else this.selectedColors.push(name);
  }

  toggleSize(name: string) {
    const i = this.selectedSizes.indexOf(name);
    if (i >= 0) this.selectedSizes.splice(i, 1);
    else this.selectedSizes.push(name);
  }

  stockKey(color: string, size: string): string {
    return `${color}|${size}`;
  }

  getStock(color: string, size: string): number {
    const v = this.stockMatrix[this.stockKey(color, size)];
    return typeof v === 'number' ? v : 0;
  }

  setStock(color: string, size: string, val: string | number) {
    const n = typeof val === 'string' ? parseInt(val, 10) : val;
    this.stockMatrix[this.stockKey(color, size)] = isNaN(n) ? 0 : Math.max(0, n);
  }

  buildVariantsFromMatrix(): ProductVariant[] {
    const out: ProductVariant[] = [];
    for (const c of this.selectedColors) {
      for (const s of this.selectedSizes) {
        const stock = this.getStock(c, s);
        out.push({ color: c, size: s, stock });
      }
    }
    return out;
  }

  loadCategories() {
    this.categoryService.getTree().subscribe({
      next: (data: any) => {
        this.parentCategories = Array.isArray(data) ? data : [];
        this.onCategoryChange();
      },
    });
  }

  /** Normalize ID - API may return object or string */
  private toId(v: any): string | undefined {
    if (v == null) return undefined;
    return typeof v === 'object' && v._id != null ? String(v._id) : String(v);
  }

  onCategoryChange() {
    const catId = this.form.category ? this.toId(this.form.category) : null;
    if (!catId) {
      this.subcategories = [];
      this.form.subcategory = undefined;
      return;
    }
    const parent = this.parentCategories.find((c) => this.toId(c._id) === catId);
    this.subcategories = parent?.children || [];
    const subId = this.form.subcategory ? this.toId(this.form.subcategory) : null;
    if (subId && !this.subcategories.some((c) => this.toId(c._id) === subId)) {
      this.form.subcategory = undefined;
    }
  }

  loadProduct() {
    if (!this.id) return;
    this.loading = true;
    this.productService.getOne(this.id).subscribe({
      next: (p: any) => {
        const catId = this.toId(p.category);
        const subId = this.toId(p.subcategory);

        // If category is a subcategory (in children), resolve to parent + sub
        let resolvedCategory = catId;
        let resolvedSubcategory = subId;
        const foundInParent = this.parentCategories.some((c) => this.toId(c._id) === catId);
        if (!foundInParent && catId) {
          for (const parent of this.parentCategories) {
            const child = parent.children?.find((ch: any) => this.toId(ch._id) === catId);
            if (child) {
              resolvedCategory = this.toId(parent._id);
              resolvedSubcategory = catId;
              break;
            }
          }
        }

        this.form = {
          ...p,
          category: resolvedCategory,
          subcategory: resolvedSubcategory,
          variants: (p.variants?.length ? p.variants : []) as ProductVariant[],
        };
        // Populate variant matrix from existing variants (handle legacy comma-separated sizes)
        this.selectedColors = [];
        this.selectedSizes = [];
        this.stockMatrix = {};
        const colorSet = new Set<string>();
        const sizeSet = new Set<string>();
        for (const v of p.variants || []) {
          const color = (v.color || '').trim();
          const sizeStr = (v.size || '').trim();
          if (!color || !sizeStr) continue;
          colorSet.add(color);
          // Split comma-separated sizes (legacy data) into individual sizes
          for (const sz of sizeStr.split(/\s*,\s*/).filter(Boolean)) {
            sizeSet.add(sz.trim());
            this.stockMatrix[`${color}|${sz.trim()}`] = v.stock ?? 0;
          }
          if (!sizeStr.includes(',')) sizeSet.add(sizeStr);
        }
        this.selectedColors = Array.from(colorSet);
        this.selectedSizes = Array.from(sizeSet);
        this.onCategoryChange();
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  addVariant() {
    this.form.variants = this.form.variants || [];
    this.form.variants.push({ color: '', size: '', stock: 1 });
  }

  removeVariant(i: number) {
    this.form.variants?.splice(i, 1);
  }

  onImagesSelect(ev: Event) {
    const input = ev.target as HTMLInputElement;
    const files = input.files;
    if (!files?.length) return;
    this.uploading = true;
    this.uploadService.uploadMultiple(Array.from(files)).subscribe({
      next: (res) => {
        this.form.images = [...(this.form.images || []), ...res.urls];
        this.uploading = false;
        input.value = '';
      },
      error: () => { this.uploading = false; }
    });
  }

  removeImage(url: string) {
    this.form.images = (this.form.images || []).filter((u) => u !== url);
  }

  save() {
    const variants = this.buildVariantsFromMatrix();
    if (!this.form.name?.trim() || !this.form.category || !this.selectedColors.length || !this.selectedSizes.length) return;
    if (variants.length === 0) {
      alert('Select at least one color and one size, then set stock.');
      return;
    }
    const payload = { ...this.form, variants };
    if (this.id) {
      this.productService.update(this.id, payload).subscribe({
        next: () => this.router.navigate(['/products']),
        error: (e) => alert(e.error?.message || 'Update failed'),
      });
    } else {
      this.productService.create(payload).subscribe({
        next: () => this.router.navigate(['/products']),
        error: (e) => alert(e.error?.message || 'Create failed'),
      });
    }
  }
}
