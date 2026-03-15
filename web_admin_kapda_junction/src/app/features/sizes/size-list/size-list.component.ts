import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SizeService } from '../../../core/services/size.service';
import { SnackbarService } from '../../../core/services/snackbar.service';

@Component({
  selector: 'app-size-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="page-header">
      <h1>Sizes</h1>
      <button class="btn primary" (click)="openForm()">+ Add Size</button>
    </div>

    @if (loading) { <p class="loading">Loading...</p> }
    @else if (items.length) {
      <div class="list">
        @for (s of items; track s._id) {
          <div class="list-item">
            <span class="name">{{ s.name }}</span>
            <div class="actions">
              <button class="btn small" (click)="openForm(s)">Edit</button>
              <button class="btn small danger" (click)="deleteItem(s)">Delete</button>
            </div>
          </div>
        }
      </div>
    }
    @else { <p class="empty">No sizes. Add sizes to use in product variants.</p> }

    @if (showForm) {
      <div class="modal-overlay" (click)="closeForm()">
        <div class="modal" (click)="$event.stopPropagation()">
          <h2>{{ editing ? 'Edit Size' : 'Add Size' }}</h2>
          <form (ngSubmit)="save()">
            <div class="field">
              <label>Name *</label>
              <input [(ngModel)]="form.name" name="name" required placeholder="e.g. 28, 30, 32, S, M, L" />
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
export class SizeListComponent implements OnInit {
  private sizeService = inject(SizeService);
  private snackbar = inject(SnackbarService);
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
    this.sizeService.getAll().subscribe({
      next: (data) => {
        this.items = data;
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  openForm(s?: { _id: string; name: string }) {
    this.editing = s || null;
    this.form = { name: s?.name ?? '' };
    this.showForm = true;
  }

  closeForm() {
    this.showForm = false;
    this.editing = null;
  }

  save() {
    if (!this.form.name?.trim()) return;
    const payload = { name: this.form.name.trim() };
    this.snackbar.setLoading(true);
    if (this.editing?._id) {
      this.sizeService.update(this.editing._id, payload).subscribe({
        next: () => {
          this.snackbar.setLoading(false);
          this.snackbar.showSuccess('Size updated');
          this.closeForm();
          this.load();
        },
        error: (e) => {
          this.snackbar.setLoading(false);
          this.snackbar.showError(e.error?.message || 'Update failed');
        }
      });
    } else {
      this.sizeService.create(payload).subscribe({
        next: () => {
          this.snackbar.setLoading(false);
          this.snackbar.showSuccess('Size added');
          this.closeForm();
          this.load();
        },
        error: (e) => {
          this.snackbar.setLoading(false);
          this.snackbar.showError(e.error?.message || 'Create failed');
        }
      });
    }
  }

  deleteItem(s: { _id: string; name: string }) {
    if (!confirm(`Delete size "${s.name}"?`)) return;
    this.snackbar.setLoading(true);
    this.sizeService.delete(s._id).subscribe({
      next: () => {
        this.snackbar.setLoading(false);
        this.snackbar.showSuccess('Size deleted');
        this.load();
      },
      error: (e) => {
        this.snackbar.setLoading(false);
        this.snackbar.showError(e.error?.message || 'Delete failed');
      }
    });
  }
}
