import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { CartActions } from '../../core/features/cart/store/cart.actions';
import { Store } from '@ngrx/store';
import { WhatsAppButtonComponent } from '../../shared/whatsapp-button/whatsapp-button.component';
import { ProductImageSliderComponent } from '../../shared/product-image-slider/product-image-slider.component';

interface LandingSection {
  category: { _id: string; name: string; slug: string };
  products: any[];
  total: number;
}

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterLink, WhatsAppButtonComponent, ProductImageSliderComponent],
  template: `
    <div class="hero-wrapper">
    <section class="hero-carousel">
      @if (banners.length) {
        <div class="carousel-wrap">
          @for (b of banners; track b._id; let i = $index) {
            <div class="carousel-slide" [class.active]="carouselIndex === i">
              <div class="slide-bg" [style.backgroundImage]="'url(' + b.image + ')'"></div>
              <div class="slide-overlay"></div>
              <div class="product-patches">
                @for (p of b.products; track p._id) {
                  <a [routerLink]="['/products', p._id]" class="patch">
                    <img [src]="p.images?.[0] || ''" [alt]="p.name" />
                    <span class="patch-name">{{ p.name }}</span>
                    <span class="patch-price">₹{{ p.price }}</span>
                  </a>
                }
              </div>
              @if (banners.length > 1) {
                <div class="carousel-dots">
                  @for (b2 of banners; track b2._id; let j = $index) {
                    <button type="button" class="dot" [class.active]="carouselIndex === j" (click)="goToSlide(j)" [attr.aria-label]="'Slide ' + (j+1)"></button>
                  }
                </div>
              }
            </div>
          }
        </div>
      } @else {
        <div class="hero-fallback">
          <h1>Men's Wear,<br>Refined.</h1>
          <p>Premium quality clothing for the modern gentleman.</p>
        </div>
      }
    </section>
    <section class="sections" *ngIf="loading">
      <div class="container"><div class="loading">Loading...</div></div>
    </section>
    <section class="sections" *ngIf="!loading && sections?.length">
      <div class="container" *ngFor="let sec of sections">
        <div class="section-header">
          <h2>{{ sec.category.name }}</h2>
          <a [routerLink]="['/category', sec.category._id]" class="see-more">See More</a>
        </div>
        <div class="product-grid">
          <div class="card" *ngFor="let p of sec.products" [class.sold-out]="isFullySoldOut(p)">
            <a [routerLink]="['/products', p._id]" class="card-link">
              <div class="img-wrap">
                <app-product-image-slider [images]="p.images" [alt]="p.name" />
                <span class="badge-soldout" *ngIf="isFullySoldOut(p)">Sold Out</span>
                <div class="card-actions">
                  <app-whatsapp-button [product]="p" [inline]="true" class="wa-inline"></app-whatsapp-button>
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
        </div>
        <div class="section-footer" *ngIf="sec.total > sec.products.length">
          <a [routerLink]="['/category', sec.category._id]" class="btn-see-more">See More ({{ sec.total - sec.products.length }} more)</a>
        </div>
      </div>
    </section>
    </div>
  `,
  styles: [`
    :host { display: block; width: 100%; overflow-x: hidden; }
    .hero-wrapper { width: 100%; overflow-x: hidden; max-width: 100%; padding-top: 0.5rem; }
    .hero-carousel {
      position: relative;
      display: block;
      width: 90%;
      max-width: 90vw;
      max-height: 220px;
      margin: 0 auto;
      overflow: hidden;
      background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-light) 100%);
      color: #fff;
      aspect-ratio: 16 / 9;
      min-height: 160px;
      border-radius: var(--radius);
      box-sizing: border-box;
    }
    .carousel-wrap, .slide-bg, .slide-overlay { border-radius: inherit; }
    .carousel-wrap { overflow: hidden; }
    @media (min-width: 640px) { .hero-carousel { margin-top: 0; } }
    @media (min-width: 375px) { .hero-carousel { min-height: 180px; } }
    @media (min-width: 480px) { .hero-carousel { min-height: 200px; max-height: 260px; } }
    @media (min-width: 768px) { .hero-carousel { min-height: 220px; max-height: 300px; } }
    @media (min-width: 1024px) { .hero-carousel { min-height: 260px; max-height: 340px; } }
    .carousel-wrap {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
    }
    .carousel-slide {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      text-decoration: none;
      color: inherit;
      opacity: 0;
      transition: opacity 0.5s ease;
      pointer-events: none;
    }
    .carousel-slide.active { opacity: 1; pointer-events: auto; }
    .slide-bg {
      position: absolute;
      inset: 0;
      background-size: cover;
      background-position: top center;
      background-repeat: no-repeat;
      background-color: var(--color-primary);
    }
    .slide-overlay {
      position: absolute;
      inset: 0;
      background: linear-gradient(to bottom, rgba(0,0,0,0.4) 0%, transparent 40%, transparent 60%, rgba(0,0,0,0.5) 100%);
      pointer-events: none;
    }
    /* Scattered product patches – bigger, more space, subtle highlight animation */
    @keyframes patchGlow {
      0%, 100% { box-shadow: 0 4px 18px rgba(0,0,0,0.22), 0 0 0 0 rgba(245,158,11,0.25); }
      50% { box-shadow: 0 8px 26px rgba(0,0,0,0.35), 0 0 20px 4px rgba(245,158,11,0.4); }
    }
    @keyframes patchPop {
      0% { opacity: 0; transform: scale(0.7) translateY(10px); }
      100% { opacity: 1; transform: scale(1) translateY(0); }
    }
    .product-patches {
      position: absolute;
      inset: 0;
      z-index: 2;
      pointer-events: none;
    }
    .product-patches .patch { pointer-events: auto; }
    .patch {
      position: absolute;
      display: flex;
      flex-direction: column;
      align-items: center;
      width: 100px;
      padding: 0.6rem;
      background: rgba(255,255,255,0.97);
      border-radius: 14px;
      box-shadow: 0 4px 16px rgba(0,0,0,0.2);
      text-decoration: none;
      color: var(--text-primary);
      transition: transform 0.3s ease, box-shadow 0.3s ease;
      animation: patchGlow 2.5s ease-in-out infinite, patchPop 0.6s ease-out backwards;
    }
    .patch:nth-child(1) { left: 3%; bottom: 14%; transform: rotate(-8deg); animation-delay: 0s, 0.1s; }
    .patch:nth-child(2) { left: 25%; bottom: 22%; transform: rotate(5deg); animation-delay: 0.3s, 0.2s; }
    .patch:nth-child(3) { left: 50%; bottom: 12%; transform: rotate(-4deg); animation-delay: 0.6s, 0.3s; }
    .patch:nth-child(4) { left: 73%; bottom: 18%; transform: rotate(7deg); animation-delay: 0.9s, 0.4s; }
    .patch:hover {
      transform: scale(1.1) rotate(var(--patch-rotate, 0deg));
      box-shadow: 0 10px 24px rgba(0,0,0,0.35), 0 0 16px 3px rgba(245,158,11,0.35);
      animation: none;
      color: var(--text-primary);
    }
    .patch:hover .patch-name { color: var(--text-primary) !important; }
    .patch:hover .patch-price { color: var(--color-primary) !important; }
    .patch:nth-child(1):hover { transform: scale(1.1) rotate(-8deg); }
    .patch:nth-child(2):hover { transform: scale(1.1) rotate(5deg); }
    .patch:nth-child(3):hover { transform: scale(1.1) rotate(-4deg); }
    .patch:nth-child(4):hover { transform: scale(1.1) rotate(7deg); }
    @media (min-width: 480px) {
      .patch { width: 110px; padding: 0.65rem; }
      .patch:nth-child(1) { left: 5%; bottom: 16%; transform: rotate(-6deg); }
      .patch:nth-child(2) { left: 28%; bottom: 24%; transform: rotate(6deg); }
      .patch:nth-child(3) { left: 52%; bottom: 14%; transform: rotate(-5deg); }
      .patch:nth-child(4) { left: 72%; bottom: 20%; transform: rotate(4deg); }
      .patch:nth-child(1):hover { transform: scale(1.1) rotate(-6deg); }
      .patch:nth-child(2):hover { transform: scale(1.1) rotate(6deg); }
      .patch:nth-child(3):hover { transform: scale(1.1) rotate(-5deg); }
      .patch:nth-child(4):hover { transform: scale(1.1) rotate(4deg); }
    }
    @media (min-width: 768px) {
      .patch { width: 136px; padding: 0.7rem; }
      .patch:nth-child(1) { left: 6%; bottom: 18%; transform: rotate(-7deg); }
      .patch:nth-child(2) { left: 30%; bottom: 26%; transform: rotate(5deg); }
      .patch:nth-child(3) { left: 54%; bottom: 15%; transform: rotate(-6deg); }
      .patch:nth-child(4) { left: 74%; bottom: 22%; transform: rotate(6deg); }
      .patch:nth-child(1):hover { transform: scale(1.1) rotate(-7deg); }
      .patch:nth-child(2):hover { transform: scale(1.1) rotate(5deg); }
      .patch:nth-child(3):hover { transform: scale(1.1) rotate(-6deg); }
      .patch:nth-child(4):hover { transform: scale(1.1) rotate(6deg); }
    }
    @media (min-width: 1024px) {
      .patch { width: 150px; padding: 0.75rem; }
      .patch:nth-child(1) { left: 5%; bottom: 20%; transform: rotate(-6deg); }
      .patch:nth-child(2) { left: 30%; bottom: 28%; transform: rotate(7deg); }
      .patch:nth-child(3) { left: 55%; bottom: 16%; transform: rotate(-5deg); }
      .patch:nth-child(4) { left: 76%; bottom: 24%; transform: rotate(5deg); }
      .patch:nth-child(1):hover { transform: scale(1.1) rotate(-6deg); }
      .patch:nth-child(2):hover { transform: scale(1.1) rotate(7deg); }
      .patch:nth-child(3):hover { transform: scale(1.1) rotate(-5deg); }
      .patch:nth-child(4):hover { transform: scale(1.1) rotate(5deg); }
    }
    .patch img {
      width: 64px;
      height: 64px;
      object-fit: cover;
      border-radius: 10px;
      margin-bottom: 0.35rem;
    }
    @media (min-width: 480px) { .patch img { width: 70px; height: 70px; } }
    @media (min-width: 768px) { .patch img { width: 80px; height: 80px; margin-bottom: 0.4rem; } }
    @media (min-width: 1024px) { .patch img { width: 88px; height: 88px; } }
    .patch-name { font-size: 0.65rem; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 100%; }
    @media (min-width: 480px) { .patch-name { font-size: 0.7rem; } }
    @media (min-width: 768px) { .patch-name { font-size: 0.75rem; } }
    .patch-price { font-size: 0.7rem; font-weight: 700; color: var(--color-primary); }
    @media (min-width: 768px) { .patch-price { font-size: 0.8rem; } }
    .slide-content {
      position: relative;
      z-index: 1;
      padding: 2rem 1.5rem;
      max-width: 90%;
      text-align: left;
    }
    @media (min-width: 768px) { .slide-content { padding: 3rem 4rem; max-width: 480px; } }
    .hero-tag {
      display: inline-block;
      padding: 0.25rem 0.6rem;
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      background: rgba(255,255,255,0.25);
      border-radius: 4px;
      margin-bottom: 0.75rem;
    }
    .carousel-slide h1 { font-size: 1.5rem; font-weight: 700; line-height: 1.2; margin-bottom: 0.5rem; }
    @media (min-width: 768px) { .carousel-slide h1 { font-size: 2.25rem; } }
    .slide-price { font-size: 1.25rem; font-weight: 700; opacity: 0.95; }
    .carousel-dots {
      position: absolute;
      bottom: 0.5rem;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      gap: 0.5rem;
      z-index: 3;
    }
    .dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      border: 2px solid rgba(255,255,255,0.6);
      background: transparent;
      cursor: pointer;
      padding: 0;
      transition: all 0.2s;
    }
    .dot:hover, .dot.active { background: #fff; border-color: #fff; }
    .hero-fallback {
      min-height: 180px;
      aspect-ratio: 16 / 7;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 2rem 1rem;
      text-align: center;
    }
    @media (min-width: 480px) { .hero-fallback { min-height: 220px; padding: 2.5rem 1.5rem; } }
    @media (min-width: 768px) { .hero-fallback { min-height: 320px; padding: 3rem 2rem; } }
    .hero-fallback h1 { font-size: 1.5rem; font-weight: 700; line-height: 1.2; margin-bottom: 0.5rem; }
    @media (min-width: 480px) { .hero-fallback h1 { font-size: 1.75rem; } }
    @media (min-width: 768px) { .hero-fallback h1 { font-size: 2rem; } }
    .hero-fallback p { font-size: 0.9rem; opacity: 0.9; }
    @media (min-width: 768px) { .hero-fallback p { font-size: 1rem; } }
    .sections { padding: 2rem 0; }
    .loading { padding: 3rem; text-align: center; color: var(--text-secondary); }
    .section-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.25rem;
    }
    .section-header h2 { font-size: 1.5rem; font-weight: 700; color: var(--text-primary); }
    .see-more, .btn-see-more {
      font-weight: 600;
      color: var(--color-accent);
      font-size: 0.95rem;
    }
    .see-more:hover, .btn-see-more:hover { color: var(--color-accent-hover); }
    .product-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 1rem;
    }
    @media (min-width: 640px) {
      .product-grid { grid-template-columns: repeat(4, 1fr); gap: 1.25rem; }
    }
    .section-footer { text-align: center; margin-top: 1.5rem; }
    .card {
      background: var(--bg-card);
      border-radius: var(--radius);
      overflow: hidden;
      box-shadow: var(--shadow-sm);
      transition: box-shadow var(--transition);
    }
    .card:hover { box-shadow: var(--shadow); }
    .card.sold-out { opacity: 0.85; }
    .card-link { display: block; }
    .img-wrap {
      position: relative;
      aspect-ratio: 1;
      overflow: hidden;
    }
    .img-wrap:hover .card-actions { opacity: 1; }
    .card-actions {
      position: absolute;
      bottom: 0.5rem;
      right: 0.5rem;
      opacity: 0;
      transition: opacity var(--transition);
    }
    .card img { width: 100%; height: 100%; object-fit: cover; }
    .badge-soldout {
      position: absolute; inset: 0;
      display: flex; align-items: center; justify-content: center;
      background: var(--bg-overlay);
      color: #fff; font-weight: 600; font-size: 0.85rem;
    }
    .card h3 { padding: 0.6rem 0.75rem 0; font-size: 0.95rem; }
    .price { padding: 0 0.75rem; font-weight: 700; color: var(--color-primary); font-size: 0.95rem; }
    button {
      width: 100%; margin: 0.5rem 0.75rem 0.75rem; padding: 0.5rem;
      background: var(--color-primary);
      color: #fff; border-radius: var(--radius-sm);
      font-weight: 500; cursor: pointer; font-size: 0.85rem;
    }
    button:hover:not(:disabled) { opacity: 0.9; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .btn-select {
      display: block; width: 100%; margin: 0.5rem 0.75rem 0.75rem; padding: 0.5rem;
      background: var(--color-primary); color: #fff; text-align: center;
      border-radius: var(--radius-sm); font-weight: 500; font-size: 0.85rem;
    }
    .btn-select:hover { opacity: 0.9; color: #fff; }
    .wa-inline { margin: 0; }
  `],
})
export class HomeComponent implements OnInit, OnDestroy {
  private api = inject(ApiService);
  private store = inject(Store);
  sections: LandingSection[] = [];
  loading = true;
  banners: any[] = [];
  carouselIndex = 0;
  private carouselTimer: ReturnType<typeof setInterval> | null = null;

  ngOnInit() {
    this.api.get<{ banners?: any[] } | any[]>('/banners/active', { _: String(Date.now()) }).subscribe({
      next: (res) => {
        const data = res as { banners?: any[] } | any[];
        this.banners = Array.isArray(data) ? data : (data?.banners ?? []);
        if (this.banners.length > 1) {
          this.carouselTimer = setInterval(() => {
            this.carouselIndex = (this.carouselIndex + 1) % this.banners.length;
          }, 2500);
        }
      },
      error: () => { this.banners = []; }
    });
    this.api.get<{ sections: LandingSection[] }>('/products/landing').subscribe({
      next: (res) => {
        this.sections = res?.sections ?? [];
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  ngOnDestroy() {
    if (this.carouselTimer) clearInterval(this.carouselTimer);
  }

  goToSlide(i: number) {
    this.carouselIndex = i;
    if (this.banners.length > 1) {
      if (this.carouselTimer) clearInterval(this.carouselTimer);
      this.carouselTimer = setInterval(() => {
        this.carouselIndex = (this.carouselIndex + 1) % this.banners.length;
      }, 2500);
    }
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
