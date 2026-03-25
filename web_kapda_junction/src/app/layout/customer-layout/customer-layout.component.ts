import { Component, HostListener, OnInit, inject, viewChild, ElementRef } from '@angular/core';
import {
  RouterLink,
  RouterLinkActive,
  RouterOutlet,
  Router,
  NavigationEnd,
} from '@angular/router';
import { CommonModule } from '@angular/common';
import { Store } from '@ngrx/store';
import { filter } from 'rxjs/operators';
import { map } from 'rxjs/operators';
import { selectCartCount } from '../../core/features/cart/store/cart.selectors';
import { selectAuthState } from '../../core/features/auth/store/auth.selectors';
import { AuthActions } from '../../core/features/auth/store/auth.actions';
import { SettingsService } from '../../core/services/settings.service';

@Component({
  selector: 'app-customer-layout',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive, RouterOutlet],
  template: `
    <div class="layout-wrap">
    <header class="header">
      <div class="container header-bar">
        <a routerLink="/" class="logo">Kapda Junction</a>
        <form
          class="global-search"
          [class.mobile-open]="mobileSearchOpen"
          (submit)="onGlobalSearchSubmit($event)"
        >
          <label class="sr-only" for="global-search-input">Search products</label>
          <input
            #globalSearchInput
            id="global-search-input"
            type="search"
            name="q"
            class="global-search-input"
            placeholder="Search products..."
            autocomplete="off"
            [value]="globalSearchValue"
            (input)="onGlobalSearchInput($event)"
          />
          <button type="submit" class="global-search-submit" aria-label="Search">
            <svg class="icon-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <circle cx="11" cy="11" r="8"></circle>
              <path d="m21 21-4.3-4.3"></path>
            </svg>
          </button>
        </form>
        @if (!mobileSearchOpen) {
          <button
            type="button"
            class="search-toggle"
            (click)="toggleMobileSearch()"
            aria-expanded="false"
            aria-controls="global-search-input"
            aria-label="Open search"
          >
            <svg class="icon-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <circle cx="11" cy="11" r="8"></circle>
              <path d="m21 21-4.3-4.3"></path>
            </svg>
          </button>
        } @else {
          <button
            type="button"
            class="search-close"
            (click)="closeMobileSearch()"
            aria-expanded="true"
            aria-controls="global-search-input"
            aria-label="Close search"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="22" height="22" aria-hidden="true">
              <path d="M18 6L6 18M6 6l12 12"></path>
            </svg>
          </button>
        }
        <nav class="nav">
          <a routerLink="/" routerLinkActive="active" [routerLinkActiveOptions]="{ exact: true }">Home</a>
          <a routerLink="/products" routerLinkActive="active">Shop</a>
          <a routerLink="/cart" class="cart-link" routerLinkActive="active">
            Cart <span class="badge">{{ cartCount$ | async }}</span>
          </a>
          @if (isAuth$ | async) {
            <button type="button" class="btn-logout" (click)="logout()">Logout</button>
          } @else {
            <a routerLink="/login" routerLinkActive="active">Login</a>
          }
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
      overflow: visible;
    }
    .header .container { padding-left: 0.75rem; padding-right: 0.75rem; }
    @media (min-width: 360px) {
      .header .container { padding-left: 1rem; padding-right: 1rem; }
    }
    .header-bar {
      position: relative;
      display: flex;
      justify-content: space-between;
      align-items: center;
      min-height: 52px;
      height: var(--header-h);
      padding: 0.4rem 0;
      gap: 0.45rem;
    }
    @media (min-width: 375px) {
      .header-bar { min-height: 54px; gap: 0.5rem; }
    }
    @media (min-width: 480px) {
      .header-bar { min-height: var(--header-h); padding: 0; gap: 0.65rem; }
    }
    @media (min-width: 640px) {
      .header-bar { gap: 0.85rem; }
    }
    @media (min-width: 768px) {
      .header-bar { gap: 1rem; }
    }
    .sr-only {
      position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px;
      overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0;
    }
    .global-search {
      flex: 1;
      min-width: 0;
      max-width: 26rem;
      display: flex;
      align-items: stretch;
      gap: 0;
      margin: 0 auto;
    }
    .global-search-input {
      flex: 1;
      min-width: 0;
      padding: 0.45rem 0.65rem;
      border: none;
      border-radius: var(--radius-sm) 0 0 var(--radius-sm);
      font-size: 0.9rem;
      background: rgba(255,255,255,0.95);
      color: var(--text-primary, #1a1a1a);
    }
    .global-search-input::placeholder { color: rgba(0,0,0,0.45); }
    .global-search-input:focus {
      outline: 2px solid var(--color-accent, #f59e0b);
      outline-offset: 0;
      z-index: 1;
    }
    .global-search-submit {
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 0 0.65rem;
      border: none;
      border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
      background: rgba(255,255,255,0.22);
      color: #fff;
      cursor: pointer;
      transition: background var(--transition);
    }
    .global-search-submit:hover { background: rgba(255,255,255,0.32); }
    .icon-search { width: 18px; height: 18px; display: block; }
    @media (min-width: 480px) {
      .global-search-input { padding: 0.5rem 0.75rem; font-size: 0.95rem; }
    }
    .search-toggle,
    .search-close {
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      width: 40px;
      height: 40px;
      padding: 0;
      border: none;
      border-radius: var(--radius-sm);
      background: rgba(255,255,255,0.15);
      color: #fff;
      cursor: pointer;
      transition: background var(--transition);
    }
    .search-toggle:hover,
    .search-close:hover { background: rgba(255,255,255,0.25); }
    @media (max-width: 767px) {
      .global-search {
        position: absolute;
        left: 0;
        right: 0;
        top: 100%;
        max-width: none;
        margin: 0;
        padding: 0.6rem 0.75rem;
        background: var(--color-primary);
        box-shadow: 0 12px 24px rgba(0,0,0,0.18);
        display: none;
        z-index: 60;
      }
      .global-search.mobile-open { display: flex; }
      .search-toggle { display: flex; }
      .global-search-input { border-radius: var(--radius-sm) 0 0 var(--radius-sm); font-size: 16px; }
    }
    @media (min-width: 768px) {
      .search-toggle { display: none !important; }
      .search-close { display: none !important; }
      .global-search {
        position: relative;
        top: auto;
        left: auto;
        right: auto;
        padding: 0;
        box-shadow: none;
        background: transparent;
        display: flex !important;
      }
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
.btn-logout { background: none; border: none; color: rgba(255,255,255,0.85); font: inherit; cursor: pointer; padding: 0; }
.btn-logout:hover { color: #fff; }
    .btn-logout { background: none; border: none; color: rgba(255,255,255,0.85); font-weight: 500; font-size: 0.95rem; cursor: pointer; padding: 0; }
    .btn-logout:hover { color: #fff; }
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
  private router = inject(Router);
  globalSearchInput = viewChild<ElementRef<HTMLInputElement>>('globalSearchInput');

  cartCount$ = this.store.select(selectCartCount);
  isAuth$ = this.store.select(selectAuthState).pipe(map((a) => a?.isAuthenticated ?? false));
  waHref = '';
  currentYear = new Date().getFullYear();
  globalSearchValue = '';
  mobileSearchOpen = false;

  ngOnInit() {
    this.syncSearchFromUrl();
    this.router.events
      .pipe(filter((e): e is NavigationEnd => e instanceof NavigationEnd))
      .subscribe(() => this.syncSearchFromUrl());

    this.settings.getWhatsapp().subscribe((num) => {
      this.waHref = this.settings.getWhatsappUrl(num);
    });
  }

  @HostListener('document:keydown.escape')
  onEscapeCloseSearch() {
    if (this.mobileSearchOpen) {
      this.closeMobileSearch();
    }
  }

  syncSearchFromUrl() {
    const tree = this.router.parseUrl(this.router.url);
    const q = tree.queryParams['search'];
    this.globalSearchValue = typeof q === 'string' ? q : '';
  }

  onGlobalSearchInput(ev: Event) {
    this.globalSearchValue = (ev.target as HTMLInputElement)?.value ?? '';
  }

  onGlobalSearchSubmit(ev: Event) {
    ev.preventDefault();
    const q = this.globalSearchValue.trim();
    this.router.navigate(['/products'], { queryParams: q ? { search: q } : {} });
    this.closeMobileSearch();
  }

  toggleMobileSearch() {
    this.mobileSearchOpen = !this.mobileSearchOpen;
    if (this.mobileSearchOpen) {
      queueMicrotask(() => this.globalSearchInput()?.nativeElement?.focus());
    }
  }

  closeMobileSearch() {
    this.mobileSearchOpen = false;
  }

  logout() {
    this.store.dispatch(AuthActions.logout());
  }
}
