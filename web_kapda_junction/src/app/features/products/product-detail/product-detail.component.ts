import { Component, OnInit, HostListener, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { CartActions } from '../../../core/features/cart/store/cart.actions';
import { WhatsAppButtonComponent } from '../../../shared/whatsapp-button/whatsapp-button.component';
import { ApiService } from '../../../core/services/api.service';
import { SettingsService } from '../../../core/services/settings.service';
import { SnackbarService } from '../../../core/services/snackbar.service';
import { map, switchMap } from 'rxjs/operators';
import { of } from 'rxjs';

@Component({
  selector: 'app-product-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, WhatsAppButtonComponent],
  template: `
    <div class="container">
      @if (loading) { <div class="loading">Loading...</div> }
      @else if (product) {
        <div class="detail">
          <div class="gallery">
            <button type="button" class="main-img-wrap" (click)="openLightbox()" [class.clickable]="product.images?.length > 1">
              <img [src]="selectedImage || product.images?.[0] || 'https://via.placeholder.com/400'" [alt]="product.name" />
              @if (product.images?.length > 1) {
                <span class="gallery-hint">Click to view gallery</span>
              }
            </button>
            @if (product.images?.length > 1) {
              <div class="thumbnails">
                @for (img of product.images; track img; let i = $index) {
                  <button type="button" class="thumb" [class.active]="selectedImage === img" (click)="selectImage(img); openLightbox(); $event.stopPropagation()">
                    <img [src]="img" [alt]="product.name" />
                  </button>
                }
              </div>
            }
          </div>
          <!-- Image lightbox -->
          @if (lightboxOpen && product.images?.length) {
            <div class="lightbox-overlay" (click)="closeLightbox()" (keydown.escape)="closeLightbox()">
              <button type="button" class="lightbox-close" (click)="closeLightbox()" aria-label="Close">×</button>
              @if (product.images.length > 1) {
                <button type="button" class="lightbox-prev" (click)="lightboxPrev(); $event.stopPropagation()" aria-label="Previous">‹</button>
                <button type="button" class="lightbox-next" (click)="lightboxNext(); $event.stopPropagation()" aria-label="Next">›</button>
              }
              <div class="lightbox-content" (click)="$event.stopPropagation()">
                <img [src]="lightboxImage" [alt]="product.name" />
              </div>
              @if (product.images.length > 1) {
                <div class="lightbox-dots">
                  @for (img of product.images; track img; let i = $index) {
                    <button type="button" class="lightbox-dot" [class.active]="lightboxIndex === i" (click)="goToLightboxImage(i); $event.stopPropagation()" [attr.aria-label]="'Image ' + (i+1)"></button>
                  }
                </div>
              }
            </div>
          }
          <div class="info">
            <h1>{{ product.name }}</h1>
            <div class="price-block">
              @if (product.compareAtPrice && product.compareAtPrice > product.price) {
                <span class="price-original">₹{{ product.compareAtPrice }}</span>
                <span class="price-offer">₹{{ product.price }}</span>
                <span class="price-off-badge">{{ getDiscountPercent() }}% OFF</span>
              } @else {
                <span class="price-single">₹{{ product.price }}</span>
              }
            </div>
            <p class="desc">{{ product.description || "Premium men's wear." }}</p>

            @if (product.variants?.length) {
              <div class="variants">
                @if (hasMultipleColors) {
                  <div class="variant-group">
                    <label>Color</label>
                    <div class="chips">
                      @for (v of uniqueColors; track v) {
                        <button type="button" class="chip" [class.active]="selectedColor === v" [class.sold-out]="getColorStock(v) === 0" (click)="selectColor(v)">
                          {{ v }}
                        </button>
                      }
                    </div>
                  </div>
                }
                @if (hasMultipleSizes) {
                  <div class="variant-group">
                    <label>Size</label>
                    <div class="chips">
                      @for (v of uniqueSizes; track v) {
                        <button type="button" class="chip" [class.active]="selectedSize === v" [class.sold-out]="getSizeStock(v) === 0" (click)="selectSize(v)">
                          {{ v }}
                        </button>
                      }
                    </div>
                  </div>
                }
              </div>
            }

            <div class="btn-row">
              <button class="btn-add" (click)="addToCart()" [disabled]="!canAddToCart">
                {{ canAddToCart ? 'Add to Cart' : 'Sold Out' }}
              </button>
              <app-whatsapp-button
                [product]="product"
                [showLabel]="true"
                [label]="canAddToCart ? 'Inquiry' : 'Notify when restocked'"
                [customMessage]="getInquiryMessage()">
              </app-whatsapp-button>
            </div>
            <div class="share-row">
              <button type="button" class="btn-share" (click)="copyShareLink()">
                {{ shareCopied ? '✓ Copied!' : 'Share Link' }}
              </button>
              <button type="button" class="btn-share-wa" (click)="shareOnWhatsApp()">Share on WhatsApp</button>
            </div>
            <a routerLink="/" class="back">← Back to Home</a>
          </div>
        </div>
      }
      @else { <p class="not-found">Product not found.</p> }
    </div>
  `,
  styles: [`
    .loading, .not-found { padding: 3rem; text-align: center; color: var(--text-secondary); }
    .detail {
      display: grid;
      grid-template-columns: 1fr;
      gap: 1.5rem;
      max-width: 900px;
      margin: 0 auto;
    }
    @media (min-width: 768px) {
      .detail { grid-template-columns: 1fr 1fr; gap: 2rem; }
    }
    .main-img-wrap { background: none; border: none; padding: 0; cursor: default; position: relative; display: block; width: 100%; }
    .main-img-wrap.clickable { cursor: pointer; }
    .main-img-wrap img { width: 100%; border-radius: var(--radius); aspect-ratio: 1; object-fit: cover; }
    .gallery-hint { position: absolute; bottom: 0.5rem; left: 50%; transform: translateX(-50%); font-size: 0.75rem; background: rgba(0,0,0,0.6); color: #fff; padding: 0.25rem 0.5rem; border-radius: 4px; white-space: nowrap; }
    .lightbox-overlay {
      position: fixed; inset: 0; background: rgba(0,0,0,0.92); z-index: 1000;
      display: flex; align-items: center; justify-content: center; padding: 2rem;
    }
    .lightbox-close { position: absolute; top: 1rem; right: 1rem; background: rgba(255,255,255,0.2); border: none; color: #fff; font-size: 2rem; width: 44px; height: 44px; border-radius: 50%; cursor: pointer; line-height: 1; transition: background 0.2s; }
    .lightbox-close:hover { background: rgba(255,255,255,0.35); }
    .lightbox-prev, .lightbox-next { position: absolute; top: 50%; transform: translateY(-50%); background: rgba(255,255,255,0.2); border: none; color: #fff; font-size: 2.5rem; width: 48px; height: 48px; cursor: pointer; line-height: 1; border-radius: 50%; transition: background 0.2s; }
    .lightbox-prev { left: 0.5rem; }
    .lightbox-next { right: 0.5rem; }
    .lightbox-prev:hover, .lightbox-next:hover { background: rgba(255,255,255,0.4); }
    .lightbox-content { max-width: 90vw; max-height: 85vh; display: flex; align-items: center; justify-content: center; }
    .lightbox-content img { max-width: 100%; max-height: 85vh; object-fit: contain; border-radius: 8px; }
    .lightbox-dots { position: absolute; bottom: 1.5rem; left: 50%; transform: translateX(-50%); display: flex; gap: 0.5rem; }
    .lightbox-dot { width: 10px; height: 10px; border-radius: 50%; border: 2px solid rgba(255,255,255,0.6); background: transparent; cursor: pointer; padding: 0; transition: all 0.2s; }
    .lightbox-dot:hover, .lightbox-dot.active { background: #fff; border-color: #fff; }
    .price-block { display: flex; flex-wrap: wrap; align-items: center; gap: 0.5rem 0.75rem; margin-bottom: 1rem; }
    .price-original { font-size: 1.1rem; color: #999; text-decoration: line-through; }
    .price-offer { font-size: 1.5rem; font-weight: 700; color: var(--color-primary); }
    .price-off-badge { font-size: 0.8rem; font-weight: 600; background: #dc3545; color: #fff; padding: 0.2rem 0.5rem; border-radius: 4px; }
    .price-single { font-size: 1.5rem; font-weight: 700; color: var(--color-primary); }
    .main-img-wrap { position: relative; display: block; width: 100%; padding: 0; border: none; background: none; cursor: default; }
    .main-img-wrap.clickable { cursor: pointer; }
    .main-img-wrap img { width: 100%; border-radius: var(--radius); aspect-ratio: 1; object-fit: cover; display: block; }
    .gallery-hint { position: absolute; bottom: 0.5rem; left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.6); color: #fff; font-size: 0.75rem; padding: 0.25rem 0.5rem; border-radius: 4px; }
    .thumbnails { display: flex; gap: 0.5rem; margin-top: 0.75rem; flex-wrap: wrap; }
    .thumb { width: 56px; height: 56px; padding: 0; border-radius: var(--radius-sm); overflow: hidden; border: 2px solid transparent; cursor: pointer; }
    .thumb.active { border-color: var(--color-accent); }
    .thumb img { width: 100%; height: 100%; object-fit: cover; }
    .info h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .price { font-size: 1.5rem; font-weight: 700; color: var(--color-primary); margin-bottom: 1rem; }
    .desc { color: var(--text-secondary); margin-bottom: 1.5rem; line-height: 1.6; }
    .variants { margin-bottom: 1.5rem; }
    .variant-group { margin-bottom: 1rem; }
    .variant-group label { display: block; font-weight: 600; font-size: 0.9rem; margin-bottom: 0.5rem; }
    .chips { display: flex; flex-wrap: wrap; gap: 0.5rem; }
    .chip {
      padding: 0.4rem 0.75rem;
      border: 1px solid var(--border);
      background: var(--bg-card);
      border-radius: var(--radius-sm);
      font-size: 0.9rem;
      cursor: pointer;
      transition: all var(--transition);
    }
    .chip:hover:not(.sold-out) { border-color: var(--color-primary); }
    .chip.active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
    .chip.sold-out {
      opacity: 0.6;
      color: #999;
      text-decoration: line-through;
      -webkit-text-decoration: line-through;
      text-decoration-thickness: 1px;
      cursor: not-allowed;
      pointer-events: none;
    }
    .btn-row {
      display: flex;
      gap: 0.75rem;
      align-items: stretch;
      flex-wrap: wrap;
      margin-bottom: 1rem;
    }
    .btn-add {
      flex: 1;
      min-width: 140px;
      padding: 0.875rem 1.5rem;
      background: var(--color-primary);
      color: #fff;
      font-weight: 600;
      border-radius: var(--radius);
      cursor: pointer;
      transition: opacity var(--transition);
    }
    .btn-add:hover:not(:disabled) { opacity: 0.9; }
    .btn-add:disabled { opacity: 0.6; cursor: not-allowed; background: var(--color-soldout); }
    .btn-row .btn-add { flex: 1; min-width: 140px; margin-bottom: 0; }
    .share-row { display: flex; gap: 0.75rem; margin-bottom: 1rem; flex-wrap: wrap; }
    .btn-share, .btn-share-wa {
      flex: 1; min-width: 120px; padding: 0.6rem 1rem;
      border: 1px solid var(--border); border-radius: var(--radius-sm);
      background: var(--bg-card); font-weight: 500; cursor: pointer;
      transition: all var(--transition);
    }
    .btn-share:hover, .btn-share-wa:hover { background: var(--bg-body); border-color: var(--color-primary); }
    .btn-share-wa { background: #25d366; color: #fff; border-color: #25d366; }
    .btn-share-wa:hover { background: #20bd5a; border-color: #20bd5a; }
    .back { color: var(--color-primary); text-decoration: none; font-weight: 500; }
    .main-img-wrap { position: relative; padding: 0; border: none; background: none; cursor: default; width: 100%; display: block; }
    .main-img-wrap.clickable { cursor: pointer; }
    .main-img-wrap img { width: 100%; border-radius: var(--radius); aspect-ratio: 1; object-fit: cover; display: block; }
    .gallery-hint { position: absolute; bottom: 0.5rem; left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.6); color: #fff; font-size: 0.75rem; padding: 0.25rem 0.5rem; border-radius: 4px; }
    .price-block { display: flex; flex-wrap: wrap; align-items: center; gap: 0.5rem 1rem; margin-bottom: 1rem; }
    .price-original { font-size: 1rem; color: #999; text-decoration: line-through; }
    .price-offer { font-size: 1.5rem; font-weight: 700; color: var(--color-primary); }
    .price-off-badge { font-size: 0.8rem; font-weight: 600; background: #dc3545; color: #fff; padding: 0.2rem 0.5rem; border-radius: 4px; }
    .price-single { font-size: 1.5rem; font-weight: 700; color: var(--color-primary); }
    .lightbox-overlay {
      position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 9999; display: flex; align-items: center; justify-content: center; padding: 2rem;
    }
    .lightbox-close { position: absolute; top: 1rem; right: 1rem; background: rgba(255,255,255,0.2); color: #fff; border: none; width: 44px; height: 44px; border-radius: 50%; font-size: 1.5rem; cursor: pointer; z-index: 10001; }
    .lightbox-close:hover { background: rgba(255,255,255,0.35); }
    .lightbox-prev, .lightbox-next { position: absolute; top: 50%; transform: translateY(-50%); background: rgba(255,255,255,0.2); color: #fff; border: none; width: 48px; height: 48px; border-radius: 50%; font-size: 2rem; cursor: pointer; z-index: 10001; line-height: 1; }
    .lightbox-prev { left: 0.5rem; }
    .lightbox-next { right: 0.5rem; }
    .lightbox-prev:hover, .lightbox-next:hover { background: rgba(255,255,255,0.35); }
    .lightbox-content { max-width: 90vw; max-height: 85vh; }
    .lightbox-content img { max-width: 100%; max-height: 85vh; object-fit: contain; border-radius: 8px; }
    .lightbox-dots { position: absolute; bottom: 1rem; left: 50%; transform: translateX(-50%); display: flex; gap: 0.5rem; z-index: 10001; }
    .lightbox-dot { width: 10px; height: 10px; border-radius: 50%; background: rgba(255,255,255,0.5); border: none; cursor: pointer; padding: 0; }
    .lightbox-dot.active { background: #fff; }
  `],
})
export class ProductDetailComponent implements OnInit {
  product: any = null;
  loading = true;
  selectedImage: string | null = null;
  selectedColor: string | null = null;
  selectedSize: string | null = null;

  shareCopied = false;
  lightboxOpen = false;
  lightboxIndex = 0;
  private settings = inject(SettingsService);
  private snackbar = inject(SnackbarService);

  get lightboxImage(): string {
    const imgs = this.product?.images ?? [];
    return imgs[this.lightboxIndex] ?? imgs[0] ?? '';
  }

  selectImage(img: string) {
    this.selectedImage = img;
    const idx = this.product?.images?.indexOf(img) ?? 0;
    this.lightboxIndex = idx >= 0 ? idx : 0;
  }

  openLightbox() {
    if (!this.product?.images?.length) return;
    this.lightboxIndex = this.product.images.indexOf(this.selectedImage ?? this.product.images[0]);
    if (this.lightboxIndex < 0) this.lightboxIndex = 0;
    this.lightboxOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeLightbox() {
    this.lightboxOpen = false;
    document.body.style.overflow = '';
  }

  lightboxPrev() {
    const n = this.product?.images?.length ?? 1;
    this.lightboxIndex = (this.lightboxIndex - 1 + n) % n;
    this.selectedImage = this.product.images[this.lightboxIndex];
  }

  lightboxNext() {
    const n = this.product?.images?.length ?? 1;
    this.lightboxIndex = (this.lightboxIndex + 1) % n;
    this.selectedImage = this.product.images[this.lightboxIndex];
  }

  goToLightboxImage(i: number) {
    this.lightboxIndex = i;
    this.selectedImage = this.product?.images?.[i] ?? null;
  }

  getDiscountPercent(): number {
    const p = this.product?.price;
    const c = this.product?.compareAtPrice;
    if (!c || !p || c <= p) return 0;
    return Math.round(((c - p) / c) * 100);
  }

  constructor(
    private route: ActivatedRoute,
    private store: Store,
    private api: ApiService
  ) {}

  get uniqueColors(): string[] {
    const set = new Set<string>();
    this.product?.variants?.forEach((v: any) => set.add(v.color));
    return Array.from(set);
  }
  get uniqueSizes(): string[] {
    const set = new Set<string>();
    this.product?.variants?.forEach((v: any) => {
      const sizeStr = (v.size || '').trim();
      if (sizeStr.includes(',')) {
        sizeStr.split(/\s*,\s*/).forEach((s: string) => set.add(s.trim()));
      } else if (sizeStr) set.add(sizeStr);
    });
    return Array.from(set);
  }
  get hasMultipleColors(): boolean { return this.uniqueColors.length > 1; }
  get hasMultipleSizes(): boolean { return this.uniqueSizes.length > 1; }

  getColorStock(color: string): number {
    return this.product?.variants?.filter((v: any) => v.color === color).reduce((s: number, v: any) => s + (v.stock || 0), 0) ?? 0;
  }
  getSizeStock(size: string): number {
    return (this.product?.variants ?? []).filter((v: any) => {
      const vs = (v.size || '').trim();
      if (vs === size) return true;
      return vs.split(/\s*,\s*/).map((x: string) => x.trim()).includes(size);
    }).reduce((s: number, v: any) => s + (v.stock || 0), 0) ?? 0;
  }

  get selectedVariant(): any {
    if (!this.product?.variants?.length) return null;
    const color = this.selectedColor ?? this.uniqueColors[0];
    const size = this.selectedSize ?? this.uniqueSizes[0];
    return this.product.variants.find((v: any) => {
      if (v.color !== color) return false;
      const vs = (v.size || '').trim();
      if (vs === size) return true;
      return vs.split(/\s*,\s*/).map((x: string) => x.trim()).includes(size);
    });
  }
  get canAddToCart(): boolean {
    if (!this.product?.variants?.length) return !this.product.soldOut;
    const v = this.selectedVariant;
    return v && (v.stock ?? 0) > 0;
  }

  selectColor(c: string) {
    this.selectedColor = c;
    // Reset size to first available for this color
    const avail = this.uniqueSizes.find((s) => this.getSizeStockForColor(c, s) > 0);
    this.selectedSize = avail ?? this.uniqueSizes[0] ?? null;
  }
  selectSize(s: string) { this.selectedSize = s; }

  /** Stock for given color+size combo (for variant matching) */
  getSizeStockForColor(color: string, size: string): number {
    return (this.product?.variants ?? []).filter((v: any) => {
      if (v.color !== color) return false;
      const vs = (v.size || '').trim();
      return vs === size || vs.split(/\s*,\s*/).map((x: string) => x.trim()).includes(size);
    }).reduce((s: number, v: any) => s + (v.stock || 0), 0) ?? 0;
  }

  /** Set selectedColor and selectedSize to first available (in-stock) variant. */
  selectFirstAvailableVariant() {
    if (!this.product?.variants?.length) return;
    const inStock = this.product.variants.find((v: any) => (v.stock ?? 0) > 0);
    if (inStock) {
      this.selectedColor = inStock.color;
      const sizeStr = (inStock.size || '').trim();
      this.selectedSize = sizeStr.includes(',')
        ? sizeStr.split(/\s*,\s*/).map((s: string) => s.trim())[0]
        : sizeStr;
    } else {
      this.selectedColor = this.uniqueColors[0] ?? null;
      this.selectedSize = this.uniqueSizes[0] ?? null;
    }
  }

  getInquiryMessage(): string | undefined {
    if (this.canAddToCart) return undefined; // use default inquiry
    const name = this.product?.name ?? 'this product';
    const v = this.selectedVariant;
    if (v?.color || v?.size) {
      const parts = [name, v.color, v.size].filter(Boolean);
      return `Hi! Please notify me when ${parts.join(' ')} is back in stock.`;
    }
    return `Hi! Please notify me when ${name} is back in stock.`;
  }

  ngOnInit() {
    this.route.paramMap.pipe(
      map((p) => p.get('id')),
      switchMap((id) => (id ? this.api.get<any>(`/products/${id}`) : of(null)))
    ).subscribe({
      next: (p) => {
        this.product = p;
        this.selectedImage = p?.images?.[0] ?? null;
        this.selectFirstAvailableVariant();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
      },
    });
  }

  addToCart() {
    if (!this.product || !this.canAddToCart) return;
    const variant = this.selectedVariant;
    this.store.dispatch(CartActions.addItem({
      product: this.product,
      quantity: 1,
      variant: this.product.variants?.length ? { color: variant?.color, size: variant?.size } : undefined
    }));
    this.snackbar.showSuccess('Added to cart');
  }

  copyShareLink() {
    if (!this.product?._id) return;
    const url = this.settings.getShareProductUrl(this.product._id);
    navigator.clipboard?.writeText(url).then(() => {
      this.shareCopied = true;
      setTimeout(() => (this.shareCopied = false), 2000);
    });
  }

  shareOnWhatsApp() {
    if (!this.product?._id) return;
    const shareUrl = this.settings.getShareProductUrl(this.product._id);
    this.settings.getWhatsapp().subscribe((num) => {
      const href = this.settings.getWhatsappShareUrl(num, shareUrl);
      window.open(href, '_blank');
    });
  }
}
