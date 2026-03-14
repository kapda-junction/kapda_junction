import { Component, OnInit, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';
import { selectCartCount } from '../../core/features/cart/store/cart.selectors';
import { Store } from '@ngrx/store';
import { SettingsService } from '../../core/services/settings.service';

@Component({
  selector: 'app-customer-layout',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive, RouterOutlet],
  template: `
    <div class="layout-wrap">
    <header class="header">
      <div class="container header-inner">
        <a routerLink="/" class="logo">Kapda Junction</a>
        <nav class="nav">
          <a routerLink="/" routerLinkActive="active" [routerLinkActiveOptions]="{ exact: true }">Home</a>
          <a routerLink="/products" routerLinkActive="active">Shop</a>
          <a routerLink="/cart" class="cart-link" routerLinkActive="active">
            Cart <span class="badge">{{ cartCount$ | async }}</span>
          </a>
        </nav>
      </div>
    </header>
    <main class="main"><router-outlet></router-outlet></main>
    <footer class="footer">
      <div class="container footer-inner">
        <div class="footer-brand">
          <span class="footer-logo">Kapda Junction</span>
          <p class="footer-tagline">Men's Wear, Refined.</p>
        </div>
        <div class="footer-contact">
          <a href="mailto:kapdajunction.fashion@gmail.com" class="footer-email" aria-label="Email us">
            <svg class="icon-email" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>
            kapdajunction.fashion&#64;gmail.com
          </a>
        </div>
        <nav class="footer-links">
          <a routerLink="/">Home</a>
          <a routerLink="/products">Shop</a>
          <a routerLink="/cart">Cart</a>
        </nav>
        <div class="footer-copy">
          <span>&copy; {{ currentYear }} Kapda Junction. All rights reserved.</span>
        </div>
      </div>
    </footer>
    </div>
    <a [href]="waHref" target="_blank" rel="noopener noreferrer" class="wa-float" *ngIf="waHref" aria-label="WhatsApp">
      <svg viewBox="0 0 24 24" fill="currentColor" width="28" height="28"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
    </a>
  `,
  styles: [`
    .layout-wrap { display: flex; flex-direction: column; min-height: 100vh; }
    .main { flex: 1; }
    .header {
      position: sticky; top: 0; z-index: 50;
      background: var(--color-primary);
      color: #fff;
      box-shadow: var(--shadow-sm);
      overflow-x: hidden;
    }
    .header .container { padding-left: 0.75rem; padding-right: 0.75rem; }
    @media (min-width: 360px) {
      .header .container { padding-left: 1rem; padding-right: 1rem; }
    }
    .header-inner {
      display: flex;
      justify-content: space-between;
      align-items: center;
      min-height: 52px;
      height: var(--header-h);
      padding: 0.4rem 0;
      gap: 0.5rem;
    }
    @media (min-width: 375px) {
      .header-inner { min-height: 54px; gap: 0.6rem; }
    }
    @media (min-width: 480px) {
      .header-inner { min-height: var(--header-h); padding: 0; gap: 0.75rem; }
    }
    @media (min-width: 640px) {
      .header-inner { gap: 1.25rem; }
    }
    .logo {
      font-weight: 700;
      font-size: 0.95rem;
      color: #fff;
      text-decoration: none;
      white-space: nowrap;
      flex-shrink: 1;
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    @media (min-width: 375px) { .logo { font-size: 1.1rem; } }
    @media (min-width: 480px) { .logo { font-size: 1.2rem; } }
    @media (min-width: 640px) { .logo { font-size: 1.25rem; } }
    .nav {
      display: flex;
      gap: 0.5rem;
      align-items: center;
      flex-shrink: 0;
    }
    @media (min-width: 375px) { .nav { gap: 0.6rem; } }
    @media (min-width: 480px) { .nav { gap: 0.9rem; } }
    @media (min-width: 640px) { .nav { gap: 1.25rem; } }
    .nav a {
      color: rgba(255,255,255,0.85);
      text-decoration: none;
      font-weight: 500;
      font-size: 0.85rem;
      transition: color var(--transition);
    }
    @media (min-width: 480px) { .nav a { font-size: 0.95rem; } }
    @media (min-width: 640px) { .nav a { font-size: 1rem; } }
    .nav a:hover, .nav a.active { color: #fff; }
    .cart-link { position: relative; }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 1.1rem;
      height: 1.1rem;
      padding: 0 0.2rem;
      background: var(--color-accent);
      color: #fff;
      font-size: 0.65rem;
      font-weight: 700;
      border-radius: 9999px;
      margin-left: 0.2rem;
    }
    @media (min-width: 480px) {
      .badge { min-width: 1.25rem; height: 1.25rem; padding: 0 0.25rem; font-size: 0.7rem; margin-left: 0.25rem; }
    }
    .main {
      flex: 1;
      min-height: 0;
      padding: 1.5rem 0;
      background: var(--bg-body);
      overflow-x: hidden;
    }
    @media (min-width: 640px) { .main { padding: 2rem 0; } }
    /* Footer – responsive 320px+ */
    .footer {
      background: var(--color-primary);
      color: rgba(255,255,255,0.9);
      padding: 1.5rem 0;
      margin-top: auto;
    }
    .footer .container { padding: 0 0.75rem; }
    @media (min-width: 360px) { .footer .container { padding: 0 1rem; } }
    @media (min-width: 640px) { .footer .container { padding: 0 1.5rem; } }
    .footer-inner {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      gap: 1.25rem;
      max-width: var(--max-width);
      margin: 0 auto;
    }
    @media (min-width: 640px) {
      .footer-inner { flex-direction: row; flex-wrap: wrap; justify-content: space-between; text-align: left; gap: 1.5rem; }
    }
    .footer-brand { order: 1; }
    .footer-logo { font-weight: 700; font-size: 1rem; color: #fff; }
    @media (min-width: 375px) { .footer-logo { font-size: 1.1rem; } }
    .footer-tagline { font-size: 0.75rem; color: rgba(255,255,255,0.7); margin-top: 0.2rem; }
    @media (min-width: 375px) { .footer-tagline { font-size: 0.8rem; } }
    .footer-contact { order: 2; }
    .footer-email {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      color: var(--color-accent);
      text-decoration: none;
      font-size: 0.8rem;
      font-weight: 500;
      transition: color var(--transition);
    }
    .footer-email:hover { color: #fff; }
    @media (min-width: 375px) { .footer-email { font-size: 0.85rem; } }
    .icon-email { flex-shrink: 0; width: 16px; height: 16px; }
    .footer-links {
      order: 3;
      display: flex;
      gap: 1rem;
    }
    .footer-links a {
      color: rgba(255,255,255,0.8);
      text-decoration: none;
      font-size: 0.8rem;
      transition: color var(--transition);
    }
    .footer-links a:hover { color: #fff; }
    .footer-copy {
      order: 4;
      width: 100%;
      font-size: 0.7rem;
      color: rgba(255,255,255,0.6);
    }
    @media (min-width: 640px) { .footer-copy { order: 5; text-align: center; font-size: 0.75rem; } }
    .wa-float {
      position: fixed; bottom: 1.5rem; right: 1.5rem; z-index: 100;
      display: flex; align-items: center; justify-content: center;
      width: 56px; height: 56px;
      background: #25d366; color: #fff;
      border-radius: 50%; box-shadow: 0 4px 12px rgba(37,211,102,0.4);
      transition: transform 0.2s;
    }
    .wa-float:hover { transform: scale(1.05); color: #fff; }
  `],
})
export class CustomerLayoutComponent implements OnInit {
  private store = inject(Store);
  private settings = inject(SettingsService);
  cartCount$ = this.store.select(selectCartCount);
  waHref = '';
  currentYear = new Date().getFullYear();

  ngOnInit() {
    this.settings.getWhatsapp().subscribe((num) => {
      this.waHref = this.settings.getWhatsappUrl(num);
    });
  }
}
