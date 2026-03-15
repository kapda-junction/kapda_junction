import { Component, signal } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Store } from '@ngrx/store';
import { AuthActions } from '../../core/features/auth/store/auth.actions';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive, RouterOutlet],
  template: `
    <div class="admin-layout">
      <header class="topbar">
        <button type="button" class="hamburger" (click)="toggleSidebar()" aria-label="Toggle menu">
          <span></span><span></span><span></span>
        </button>
        <h1 class="topbar-title">Kapda Junction</h1>
      </header>
      <div class="backdrop" [class.open]="sidebarOpen()" (click)="closeSidebar()" aria-hidden="true"></div>
      <aside class="sidebar" [class.open]="sidebarOpen()">
        <div class="sidebar-header">
          <span class="sidebar-logo">Kapda Junction</span>
          <button type="button" class="sidebar-close" (click)="closeSidebar()" aria-label="Close menu">&times;</button>
        </div>
        <h2 class="sidebar-brand">Kapda Junction</h2>
        <nav class="sidebar-nav">
          <a routerLink="/dashboard" routerLinkActive="active" (click)="closeSidebar()">Dashboard</a>
          <a routerLink="/products" routerLinkActive="active" (click)="closeSidebar()">Products</a>
          <a routerLink="/categories" routerLinkActive="active" (click)="closeSidebar()">Categories</a>
          <a routerLink="/colors" routerLinkActive="active" (click)="closeSidebar()">Colors</a>
          <a routerLink="/sizes" routerLinkActive="active" (click)="closeSidebar()">Sizes</a>
          <a routerLink="/orders" routerLinkActive="active" (click)="closeSidebar()">Orders</a>
          <a routerLink="/banners" routerLinkActive="active" (click)="closeSidebar()">Banners</a>
          <a routerLink="/settings" routerLinkActive="active" (click)="closeSidebar()">WhatsApp</a>
          <button type="button" class="sidebar-logout" (click)="logout()">Logout</button>
        </nav>
      </aside>
      <main class="content">
        <router-outlet></router-outlet>
      </main>
    </div>
  `,
  styles: [`
    .admin-layout { display: flex; flex-direction: column; min-height: 100vh; position: relative; }
    @media (min-width: 768px) {
      .admin-layout { flex-direction: row; }
    }
    .topbar {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.6rem 0.75rem;
      background: #1a1a2e;
      color: #fff;
      min-height: 52px;
      position: sticky;
      top: 0;
      z-index: 40;
      flex-shrink: 0;
    }
    @media (min-width: 360px) { .topbar { padding: 0.75rem 1rem; } }
    @media (min-width: 768px) { .topbar { display: none; } }
    .hamburger {
      display: flex;
      flex-direction: column;
      gap: 5px;
      background: none;
      border: none;
      cursor: pointer;
      padding: 0.25rem;
      color: #fff;
    }
    .hamburger span {
      display: block;
      width: 22px;
      height: 2px;
      background: currentColor;
      border-radius: 1px;
    }
    .topbar-title { font-size: 1rem; font-weight: 600; margin: 0; flex: 1; }
    @media (min-width: 375px) { .topbar-title { font-size: 1.1rem; } }
    .backdrop {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,0.4);
      z-index: 45;
      opacity: 0;
      transition: opacity 0.2s ease;
      pointer-events: none;
    }
    .backdrop.open {
      display: block;
      opacity: 1;
      pointer-events: auto;
    }
    @media (min-width: 768px) { .backdrop { display: none !important; } }
    .sidebar {
      position: fixed;
      top: 0;
      left: 0;
      bottom: 0;
      width: 260px;
      max-width: 85vw;
      background: #1a1a2e;
      color: #eee;
      z-index: 50;
      transform: translateX(-100%);
      transition: transform 0.25s ease;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
    }
    .sidebar.open { transform: translateX(0); }
    @media (min-width: 768px) {
      .sidebar {
        position: relative;
        flex-shrink: 0;
        transform: none;
        width: 220px;
        max-width: none;
      }
    }
    .sidebar-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem 1rem 0.75rem;
      border-bottom: 1px solid rgba(255,255,255,0.1);
    }
    @media (min-width: 768px) { .sidebar-header { display: none; } }
    .sidebar-brand { display: none; margin: 0 0 1rem; font-size: 1.15rem; font-weight: 600; color: #fff; padding: 0 0.75rem; }
    @media (min-width: 768px) { .sidebar-brand { display: block; padding: 1rem 1rem 0.5rem; } }
    .sidebar-brand { display: none; margin-bottom: 1rem; font-size: 1.2rem; font-weight: 700; color: #fff; padding: 0 1rem; }
    @media (min-width: 768px) { .sidebar-brand { display: block; padding: 1.5rem 1rem 0.5rem; } }
    .sidebar-logo { font-weight: 700; font-size: 1.1rem; color: #fff; }
    .sidebar-close {
      background: none;
      border: none;
      color: #aaa;
      font-size: 1.5rem;
      cursor: pointer;
      padding: 0.25rem;
      line-height: 1;
    }
    .sidebar-close:hover { color: #fff; }
    .sidebar-brand { display: none; }
    @media (min-width: 768px) {
      .sidebar-brand { display: block; padding: 0 1rem 1rem; font-size: 1.2rem; font-weight: 600; color: #fff; margin: 0; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 1rem; margin-bottom: 0.5rem; }
    }
    .sidebar-nav {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
      padding: 1rem 0.75rem;
    }
    @media (min-width: 768px) {
      .sidebar-nav { padding: 1.5rem 1rem; }
    }
    .sidebar-nav a {
      color: #aaa;
      text-decoration: none;
      padding: 0.65rem 0.75rem;
      border-radius: 8px;
      transition: all 0.2s;
      font-size: 0.9rem;
    }
    @media (min-width: 768px) { .sidebar-nav a { padding: 0.75rem; } }
    .sidebar-nav a:hover, .sidebar-nav a.active { background: #16213e; color: #fff; }
    .sidebar-logout {
      margin-top: 0.5rem;
      padding: 0.65rem 0.75rem;
      background: rgba(220, 53, 69, 0.2);
      color: #f87171;
      border: 1px solid rgba(220, 53, 69, 0.4);
      border-radius: 8px;
      cursor: pointer;
      font-size: 0.9rem;
      text-align: left;
      transition: background 0.2s, color 0.2s;
    }
    .sidebar-logout:hover { background: rgba(220, 53, 69, 0.35); color: #fff; }
    .content {
      flex: 1;
      padding: 1rem 0.75rem;
      background: #f5f5f5;
      overflow-x: hidden;
    }
    @media (min-width: 360px) { .content { padding: 1.25rem 1rem; } }
    @media (min-width: 640px) { .content { padding: 1.5rem 1.5rem; } }
    @media (min-width: 768px) { .content { padding: 1.5rem 2rem; } }
  `],
})
export class AdminLayoutComponent {
  sidebarOpen = signal(false);

  constructor(
    private store: Store,
    private router: Router
  ) {}

  toggleSidebar() {
    this.sidebarOpen.update(v => !v);
  }

  closeSidebar() {
    this.sidebarOpen.set(false);
  }

  logout() {
    this.store.dispatch(AuthActions.logout());
    this.closeSidebar();
    this.router.navigate(['/login']);
  }
}
