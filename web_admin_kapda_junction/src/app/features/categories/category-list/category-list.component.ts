import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CategoryService } from '../../../core/services/category.service';
import { Category } from '../../../core/services/category.service';
import { inject } from '@angular/core';

@Component({
  selector: 'app-category-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="page-header">
      <h1>Categories</h1>
      <button class="btn primary" (click)="openForm()">+ Add Category</button>
    </div>

    <div class="toolbar">
      <span class="filter-info">
        <label><input type="checkbox" [(ngModel)]="showInactive" (change)="load()" /> Show inactive</label>
      </span>
    </div>

    @if (loading) { <p class="loading">Loading...</p> }
    @else if (tree.length) {
      <div class="tree">
        @for (c of tree; track c._id) {
          <div class="tree-node">
            <div class="tree-item">
              <span class="name">{{ c.name }}</span>
              <span class="meta" *ngIf="c.children?.length">({{ c.children.length }} sub)</span>
              <span class="badge" [class.active]="c.isActive" [class.inactive]="!c.isActive">
                {{ c.isActive ? 'Active' : 'Hidden' }}
              </span>
              <div class="actions">
                <button class="btn small" (click)="openForm(c)">Edit</button>
                <button class="btn small" (click)="openForm(null, c)">+ Sub</button>
              </div>
            </div>
            @if (c.children?.length) {
              <div class="tree-children">
                @for (child of c.children; track child._id) {
                  <div class="tree-node child">
                    <div class="tree-item">
                      <span class="name">{{ child.name }}</span>
                      <span class="badge" [class.active]="child.isActive">{{ child.isActive ? 'Active' : 'Hidden' }}</span>
                      <button class="btn small" (click)="openForm(child)">Edit</button>
                    </div>
                  </div>
                }
              </div>
            }
          </div>
        }
      </div>
    }
    @else { <p class="empty">No categories. Add one to get started.</p> }

    @if (showForm) {
      <div class="modal-overlay" (click)="closeForm()">
        <div class="modal" (click)="$event.stopPropagation()">
          <h2>{{ editingCategory ? 'Edit Category' : (parentCategory ? 'Add Subcategory' : 'Add Category') }}</h2>
          <form (ngSubmit)="saveCategory()">
            <div class="field">
              <label>Name *</label>
              <input [(ngModel)]="form.name" name="name" required />
            </div>
            <div class="field">
              <label>Slug</label>
              <input [(ngModel)]="form.slug" name="slug" placeholder="auto-generated if empty" />
            </div>
            <div class="field">
              <label>Description</label>
              <textarea [(ngModel)]="form.description" name="desc"></textarea>
            </div>
            <div class="field" *ngIf="!parentCategory">
              <label>Parent Category</label>
              <select [(ngModel)]="form.parent" name="parent">
                <option [ngValue]="undefined">— None (Top level) —</option>
                @for (c of parentOptions; track c._id) {
                  <option [ngValue]="c._id">{{ c.name }}</option>
                }
              </select>
            </div>
            <div class="field">
              <label>Sort Order</label>
              <input type="number" [(ngModel)]="form.sortOrder" name="sortOrder" />
            </div>
            <div class="field">
              <label><input type="checkbox" [(ngModel)]="form.isActive" name="isActive" /> Visible to customers</label>
            </div>
            <div class="modal-actions">
              <button type="button" class="btn" (click)="closeForm()">Cancel</button>
              <button type="submit" class="btn primary">Save</button>
            </div>
          </form>
        </div>
      </div>
    }
  `,
  styles: [`
    .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
    .btn { padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; border: 1px solid #ddd; background: #fff; }
    .btn.primary { background: #1a1a2e; color: #fff; border-color: #1a1a2e; }
    .btn.small { padding: 0.25rem 0.5rem; font-size: 0.85rem; }
    .toolbar { margin-bottom: 1rem; display: flex; gap: 1rem; align-items: center; }
    .filter-info label { font-size: 0.9rem; cursor: pointer; }
    .tree { margin-top: 1rem; }
    .tree-node { margin-bottom: 0.5rem; }
    .tree-node.child { margin-left: 2rem; }
    .tree-item { display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: #fff; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .tree-children { margin-top: 0.5rem; }
    .badge { font-size: 0.75rem; padding: 0.2rem 0.5rem; border-radius: 4px; }
    .badge.active { background: #d4edda; color: #155724; }
    .badge.inactive { background: #f8d7da; color: #721c24; }
    .actions { margin-left: auto; }
    .table { width: 100%; background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .table th, .table td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid #eee; }
    .table th { background: #f8f9fa; font-weight: 600; }
    .loading, .empty { padding: 2rem; text-align: center; color: #666; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; }
    .modal { background: #fff; padding: 2rem; border-radius: 12px; max-width: 480px; width: 90%; max-height: 90vh; overflow-y: auto; }
    .field { margin-bottom: 1rem; }
    .field label { display: block; font-weight: 500; margin-bottom: 0.35rem; font-size: 0.9rem; }
    .field input, .field select, .field textarea { width: 100%; padding: 0.5rem; border: 1px solid #ddd; border-radius: 6px; }
    .field textarea { min-height: 80px; resize: vertical; }
    .modal-actions { display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem; }
  `],
})
export class CategoryListComponent implements OnInit {
  private categoryService = inject(CategoryService);
  categories: Category[] = [];
  tree: any[] = [];
  treeView = true;
  loading = false;
  showInactive = true;
  showForm = false;
  editingCategory: Category | null = null;
  parentCategory: Category | null = null;
  parentOptions: Category[] = [];
  form: Partial<Category> = { name: '', slug: '', description: '', parent: undefined, sortOrder: 0, isActive: true };

  getParentName(c: { parent?: string | { name?: string } | null }): string {
    if (!c?.parent) return '-';
    return typeof c.parent === 'object' && c.parent?.name ? c.parent.name : '-';
  }

  ngOnInit() {
    this.load();
  }

  load() {
    this.loading = true;
    this.categoryService.getTree().subscribe({
      next: (data: any) => {
        this.tree = data;
        this.categories = this.flattenTree(data);
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  flattenTree(nodes: any[]): any[] {
    return nodes.reduce((acc: any[], n: any) => {
      acc.push(n);
      if (n.children?.length) acc.push(...this.flattenTree(n.children));
      return acc;
    }, []);
  }

  openForm(c?: Category | null, parent?: Category) {
    this.editingCategory = c || null;
    this.parentCategory = parent || null;
    this.parentOptions = this.categories.filter((x: any) => !x.parent || (parent && (x.parent?._id || x.parent) === parent._id));
    if (!this.parentOptions.length && !parent) {
      this.categoryService.getAll(true).subscribe((data: any) => {
        const arr = Array.isArray(data) ? data : (data.categories || data || []);
        this.parentOptions = arr.filter((x: any) => !x.parent);
      });
    }
    this.form = c
      ? { ...c, parent: (c as any).parent?._id ?? (c as any).parent }
      : { name: '', slug: '', description: '', parent: parent?._id, sortOrder: 0, isActive: true };
    this.showForm = true;
  }

  closeForm() {
    this.showForm = false;
    this.editingCategory = null;
    this.parentCategory = null;
  }

  saveCategory() {
    if (!this.form.name?.trim()) return;
    const payload = {
      name: this.form.name.trim(),
      slug: this.form.slug?.trim() || undefined,
      description: this.form.description || '',
      parent: this.form.parent ?? undefined,
      sortOrder: this.form.sortOrder ?? 0,
      isActive: this.form.isActive ?? true,
    };
    if (this.editingCategory?._id) {
      this.categoryService.update(this.editingCategory._id, payload).subscribe({
        next: () => { this.closeForm(); this.load(); },
        error: (e) => alert(e.error?.message || 'Update failed')
      });
    } else {
      this.categoryService.create(payload).subscribe({
        next: () => { this.closeForm(); this.load(); },
        error: (e) => alert(e.error?.message || 'Create failed')
      });
    }
  }
}
