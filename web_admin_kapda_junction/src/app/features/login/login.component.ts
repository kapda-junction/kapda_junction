import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Store } from '@ngrx/store';
import { AuthActions } from '../../core/features/auth/store/auth.actions';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <div class="login-container">
      <form [formGroup]="form" (ngSubmit)="onSubmit()">
        <h1>Admin Login</h1>
        <input formControlName="email" type="email" placeholder="Email" />
        <input formControlName="password" type="password" placeholder="Password" />
        <button type="submit" [disabled]="form.invalid">Login</button>
        @if (error$ | async; as err) { <p class="error">{{ err }}</p> }
      </form>
    </div>
  `,
  styles: [`
    .login-container { display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    form { display: flex; flex-direction: column; gap: 1rem; width: 320px; }
    input, button { padding: 0.75rem; border: 1px solid #ddd; border-radius: 8px; }
    button { background: #1a1a2e; color: #fff; cursor: pointer; }
    .error { color: red; font-size: 0.875rem; }
  `],
})
export class LoginComponent {
  form: FormGroup;

  constructor(
    private fb: FormBuilder,
    private store: Store
  ) {
    this.form = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
    });
  }

  error$ = this.store.select((s: any) => s.auth?.error);

  onSubmit() {
    if (this.form.valid) {
      this.store.dispatch(AuthActions.loginRequest(this.form.value));
    }
  }
}
