import { Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive, RouterOutlet],
  template: `
    <div class="admin-layout">
      <aside class="sidebar">
        <h2>Kapda Junction</h2>
        <nav>
          <a routerLink="/dashboard" routerLinkActive="active">Dashboard</a>
          <a routerLink="/products" routerLinkActive="active">Products</a>
          <a routerLink="/categories" routerLinkActive="active">Categories</a>
          <a routerLink="/colors" routerLinkActive="active">Colors</a>
          <a routerLink="/sizes" routerLinkActive="active">Sizes</a>
          <a routerLink="/orders" routerLinkActive="active">Orders</a>
          <a routerLink="/banners" routerLinkActive="active">Banners</a>
          <a routerLink="/settings" routerLinkActive="active">WhatsApp</a>
        </nav>
      </aside>
      <main class="content">
        <router-outlet></router-outlet>
      </main>
    </div>
  `,
  styles: [`
    .admin-layout { display: flex; min-height: 100vh; }
    .sidebar { width: 240px; background: #1a1a2e; color: #eee; padding: 1.5rem; }
    .sidebar h2 { margin-bottom: 1.5rem; font-size: 1.25rem; }
    .sidebar nav { display: flex; flex-direction: column; gap: 0.5rem; }
    .sidebar a { color: #aaa; text-decoration: none; padding: 0.75rem; border-radius: 8px; transition: all 0.2s; }
    .sidebar a:hover, .sidebar a.active { background: #16213e; color: #fff; }
    .content { flex: 1; padding: 2rem; background: #f5f5f5; }
  `],
})
export class AdminLayoutComponent {}
