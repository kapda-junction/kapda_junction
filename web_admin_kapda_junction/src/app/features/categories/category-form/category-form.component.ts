import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { CategoryService } from '../../../core/services/category.service';

@Component({
  selector: 'app-category-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
    <div class="form-card">
      <h1>{{ isEdit ? 'Edit Category' : 'New Category' }}</h1>
      <form [formGroup]="form" (ngSubmit)="onSubmit()">
        <div class="field">
          <label>Name *</label>
          <input formControlName="name" placeholder="e.g. Mens Wear" />
          @if (form.get('name')?.invalid && form.get('name')?.touched) {
            <span class="err">Required</span>
          }
        </div>
        <div class="field">
          <label>Parent Category</label>
          <select formControlName="parent">
            <option value="">— None (Top Level) —</option>
            @for (c of parentCategories; track c._id) {
              <option [value]="c._id">{{ c.name }}</option>
            }
          </select>
        </div>
        <div class="field">
          <label>Description</label>
          <textarea formControlName="description" rows="2"></textarea>
        </div>
        <div class="field">
          <label>Image URL</label>
          <input formControlName="image" placeholder="https://..." />
        </div>
        <div class="field-group">
          <h3>Metadata (SEO)</h3>
          <div class="field">
            <label>Meta Title</label>
            <input formControlName="metaTitle" />
          </div>
          <div class="field">
            <label>Meta Description</label>
            <textarea formControlName="metaDescription" rows="2"></textarea>
          </div>
        </div>
        <div class="field">
          <label class="checkbox">
            <input type="checkbox" formControlName="isActive" />
            <span>Visible on store (Active)</span>
          </label>
        </div>
        <div class="actions">
          <button type="submit" [disabled]="form.invalid || saving">{{ saving ? 'Saving...' : 'Save' }}</button>
          <a routerLink="/categories" class="btn-link">Cancel</a>
        </div>
      </form>
    </div>
  `,
  styles: [`
    .form-card { max-width: 560px; background: #fff; padding: 2rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    h1 { margin: 0 0 1.5rem; font-size: 1.5rem; }
    .field { margin-bottom: 1rem; }
    .field label { display: block; font-weight: 500; margin-bottom: 0.4rem; font-size: 0.9rem; }
    .field input, .field select, .field textarea { width: 100%; padding: 0.6rem 0.75rem; border: 1px solid #ddd; border-radius: 8px; font-size: 0.95rem; }
    .field .err { color: #c00; font-size: 0.8rem; }
    .field-group { margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid #eee; }
    .field-group h3 { margin-bottom: 1rem; font-size: 1rem; }
    .checkbox { display: flex !important; align-items: center; gap: 0.5rem; cursor: pointer; }
    .checkbox input { width: auto; }
    .actions { margin-top: 1.5rem; display: flex; gap: 1rem; align-items: center; }
    .actions button { padding: 0.6rem 1.2rem; background: #1a1a2e; color: #fff; border: none; border-radius: 8px; cursor: pointer; }
    .actions button:disabled { opacity: 0.6; cursor: not-allowed; }
    .btn-link { color: #666; text-decoration: none; }
  `],
})
export class CategoryFormComponent implements OnInit {
  form: FormGroup;
  parentCategories: any[] = [];
  isEdit = false;
  saving = false;

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private categoryService: CategoryService
  ) {
    this.form = this.fb.group({
      name: ['', Validators.required],
      parent: [''],
      description: [''],
      image: [''],
      metaTitle: [''],
      metaDescription: [''],
      isActive: [true]
    });
  }

  ngOnInit() {
    this.categoryService.getTree().subscribe((tree) => {
      const flatten = (arr: any[]): any[] => arr.flatMap((c) => [c, ...(c.children || []).map((ch: any) => ({ ...ch, name: '  └ ' + ch.name }))]);
      this.parentCategories = this.flattenParents(tree);
    });
    const id = this.route.snapshot.paramMap.get('id');
    if (id && id !== 'new') {
      this.isEdit = true;
      this.categoryService.getOne(id).subscribe((c) => {
        this.form.patchValue({
          name: c.name,
          parent: c.parent?._id || c.parent || '',
          description: c.description || '',
          image: c.image || '',
          metaTitle: c.metadata?.metaTitle || '',
          metaDescription: c.metadata?.metaDescription || '',
          isActive: c.isActive !== false
        });
      });
    }
  }

  flattenParents(tree: any[]): any[] {
    const out: any[] = [];
    for (const c of tree) {
      out.push(c);
      if (c.children?.length) {
        for (const ch of c.children) out.push(ch);
      }
    }
    return out;
  }

  onSubmit() {
    if (this.form.invalid || this.saving) return;
    this.saving = true;
    const id = this.route.snapshot.paramMap.get('id');
    const val = this.form.value;
    const payload = {
      name: val.name,
      parent: val.parent || undefined,
      description: val.description || undefined,
      image: val.image || undefined,
      metadata: { metaTitle: val.metaTitle, metaDescription: val.metaDescription },
      isActive: val.isActive
    };
    const obs = this.isEdit
      ? this.categoryService.update(id!, payload)
      : this.categoryService.create(payload);
    obs.subscribe({
      next: () => { this.saving = false; this.router.navigate(['/categories']); },
      error: () => { this.saving = false; }
    });
  }
}
