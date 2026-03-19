import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { Store } from '@ngrx/store';
import { AuthActions } from '../../../core/features/auth/store/auth.actions';
import { selectAuthState } from '../../../core/features/auth/store/auth.selectors';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
    <div class="auth-wrap">
      <form class="auth-form" [formGroup]="form" (ngSubmit)="onSubmit()">
        <h1>Login</h1>
        <input formControlName="email" type="email" placeholder="Email" />
        <input formControlName="password" type="password" placeholder="Password" />
        <button type="submit" [disabled]="form.invalid">Login</button>
        @if (error) { <p class="error">{{ error }}</p> }
        <p class="switch">Don't have an account? <a routerLink="/register">Register</a></p>
      </form>
    </div>
  `,
  styles: [`
    .auth-wrap { min-height: 60vh; display: flex; align-items: center; justify-content: center; padding: 2rem; }
    .auth-form { display: flex; flex-direction: column; gap: 1rem; width: 100%; max-width: 320px; padding: 2rem; background: var(--bg-card); border-radius: var(--radius); box-shadow: var(--shadow-sm); }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    input { padding: 0.75rem; border: 1px solid var(--border); border-radius: var(--radius-sm); }
    button { padding: 0.75rem; background: var(--color-primary); color: #fff; font-weight: 600; border-radius: var(--radius); border: none; cursor: pointer; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .error { color: var(--color-error); font-size: 0.875rem; }
    .switch { font-size: 0.9rem; color: var(--text-secondary); margin-top: 0.5rem; }
    .switch a { color: var(--color-accent); font-weight: 500; }
  `],
})
export class LoginComponent {
  private store = inject(Store);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private fb = inject(FormBuilder);

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  error = '';
  private authSub = this.store.select(selectAuthState).subscribe((a) => {
    if (a?.error) this.error = a.error;
    if (a?.isAuthenticated) {
      const returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/';
      this.router.navigateByUrl(returnUrl);
    }
  });

  onSubmit() {
    this.error = '';
    if (this.form.valid) {
      const { email, password } = this.form.getRawValue();
      this.store.dispatch(AuthActions.loginRequest({ email: email ?? '', password: password ?? '' }));
    }
  }
}
