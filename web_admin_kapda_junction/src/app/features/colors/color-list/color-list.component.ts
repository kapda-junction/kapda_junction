import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ColorService } from '../../../core/services/color.service';

@Component({
  selector: 'app-color-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="page-header">
      <h1>Colors</h1>
      <button class="btn primary" (click)="openForm()">+ Add Color</button>
    </div>

    @if (loading) { <p class="loading">Loading...</p> }
    @else if (items.length) {
      <div class="list">
        @for (c of items; track c._id) {
          <div class="list-item">
            <span class="name">{{ c.name }}</span>
            <div class="actions">
              <button class="btn small" (click)="openForm(c)">Edit</button>
              <button class="btn small danger" (click)="deleteItem(c)">Delete</button>
            </div>
          </div>
        }
      </div>
    }
    @else { <p class="empty">No colors. Add colors to use in product variants.</p> }

    @if (showForm) {
      <div class="modal-overlay" (click)="closeForm()">
        <div class="modal" (click)="$event.stopPropagation()">
          <h2>{{ editing ? 'Edit Color' : 'Add Color' }}</h2>
          <form (ngSubmit)="save()">
            <div class="field">
              <label>Name *</label>
              <input [(ngModel)]="form.name" name="name" required placeholder="e.g. Blue, Black" />
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
    .btn.danger { color: #dc3545; border-color: #dc3545; }
    .list { display: flex; flex-direction: column; gap: 0.5rem; }
    .list-item { display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; background: #fff; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .name { font-weight: 500; }
    .actions { display: flex; gap: 0.5rem; }
    .loading, .empty { padding: 2rem; text-align: center; color: #666; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; }
    .modal { background: #fff; padding: 2rem; border-radius: 12px; max-width: 400px; width: 90%; }
    .field { margin-bottom: 1rem; }
    .field label { display: block; font-weight: 500; margin-bottom: 0.35rem; font-size: 0.9rem; }
    .field input { width: 100%; padding: 0.5rem; border: 1px solid #ddd; border-radius: 6px; }
    .modal-actions { display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem; }
  `],
})
export class ColorListComponent implements OnInit {
  private colorService = inject(ColorService);
  items: { _id: string; name: string }[] = [];
  loading = false;
  showForm = false;
  editing: { _id: string; name: string } | null = null;
  form = { name: '' };

  ngOnInit() {
    this.load();
  }

  load() {
    this.loading = true;
    this.colorService.getAll().subscribe({
      next: (data) => {
        this.items = data;
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  openForm(c?: { _id: string; name: string }) {
    this.editing = c || null;
    this.form = { name: c?.name ?? '' };
    this.showForm = true;
  }

  closeForm() {
    this.showForm = false;
    this.editing = null;
  }

  save() {
    if (!this.form.name?.trim()) return;
    const payload = { name: this.form.name.trim() };
    if (this.editing?._id) {
      this.colorService.update(this.editing._id, payload).subscribe({
        next: () => { this.closeForm(); this.load(); },
        error: (e) => alert(e.error?.message || 'Update failed')
      });
    } else {
      this.colorService.create(payload).subscribe({
        next: () => { this.closeForm(); this.load(); },
        error: (e) => alert(e.error?.message || 'Create failed')
      });
    }
  }

  deleteItem(c: { _id: string; name: string }) {
    if (!confirm(`Delete color "${c.name}"?`)) return;
    this.colorService.delete(c._id).subscribe({
      next: () => this.load(),
      error: (e) => alert(e.error?.message || 'Delete failed')
    });
  }
}
