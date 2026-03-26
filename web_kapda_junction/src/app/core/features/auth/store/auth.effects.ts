import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { catchError, map, switchMap, tap } from 'rxjs/operators';
import { AuthActions } from './auth.actions';
import { ApiService } from '../../../services/api.service';
import { CartActions } from '../../cart/store/cart.actions';

export class AuthEffects {
  private actions$ = inject(Actions);
  private api = inject(ApiService);
  private router = inject(Router);

  login$ = createEffect(() =>
    this.actions$.pipe(
      ofType(AuthActions.loginRequest),
      switchMap(({ email, password }) =>
        this.api.post<{ user: any; token: string }>('/auth/login', { email, password }).pipe(
          tap((res) => {
            if (res?.token) localStorage.setItem('token', res.token);
          }),
          map((res) => AuthActions.loginSuccess({ user: res.user, token: res.token })),
          catchError((err) => of(AuthActions.loginFailure({
            error: err.error?.message || err.statusText || 'Login failed'
          })))
        )
      )
    )
  );

  register$ = createEffect(() =>
    this.actions$.pipe(
      ofType(AuthActions.registerRequest),
      switchMap(({ name, email, password }) =>
        this.api.post<{ user: any; token: string }>('/auth/register', { name, email, password }).pipe(
          tap((res) => {
            if (res?.token) localStorage.setItem('token', res.token);
          }),
          map((res) => AuthActions.registerSuccess({ user: res.user, token: res.token })),
          catchError((err) => of(AuthActions.registerFailure({
            error: err.error?.message || err.statusText || 'Registration failed'
          })))
        )
      )
    )
  );

  authSuccess$ = createEffect(
    () =>
      this.actions$.pipe(
        ofType(AuthActions.loginSuccess, AuthActions.registerSuccess),
        tap(({ token }) => {
          if (token) localStorage.setItem('token', token);
        })
      ),
    { dispatch: false }
  );

  logout$ = createEffect(
    () =>
      this.actions$.pipe(
        ofType(AuthActions.logout),
        tap(() => {
          localStorage.removeItem('token');
          localStorage.removeItem('cart');
          this.router.navigate(['/']);
        })
      ),
    { dispatch: false }
  );

  logoutClearCart$ = createEffect(() =>
    this.actions$.pipe(
      ofType(AuthActions.logout),
      map(() => CartActions.clearCart())
    )
  );
}
