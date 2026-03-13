import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { catchError, map, switchMap, tap } from 'rxjs/operators';
import { AuthActions } from './auth.actions';
import { ApiService } from '../../../services/api.service';

export class AuthEffects {
  private actions$ = inject(Actions);
  private api = inject(ApiService);
  private router = inject(Router);

  login$ = createEffect(() =>
    this.actions$.pipe(
      ofType(AuthActions.loginRequest),
      switchMap(({ email, password }) =>
        this.api.post<{ user: any; token: string }>('/auth/login', { email, password }).pipe(
          map((res) => AuthActions.loginSuccess({ user: res.user, token: res.token })),
          catchError((err) => of(AuthActions.loginFailure({ error: err.error?.message || 'Login failed' })))
        )
      )
    )
  );

  loginSuccess$ = createEffect(
    () =>
      this.actions$.pipe(
        ofType(AuthActions.loginSuccess),
        tap(({ token }) => {
          if (token) localStorage.setItem('token', token);
          this.router.navigate(['/']);
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
          this.router.navigate(['/login']);
        })
      ),
    { dispatch: false }
  );
}
