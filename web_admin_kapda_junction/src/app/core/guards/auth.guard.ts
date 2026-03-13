import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { map } from 'rxjs/operators';
import { selectIsAuthenticated } from '../features/auth/store/auth.selectors';
import { Store } from '@ngrx/store';

export const authGuard = () => {
  const store = inject(Store);
  const router = inject(Router);
  return store.select(selectIsAuthenticated).pipe(
    map((isAuth) => (isAuth ? true : router.createUrlTree(['/login'])))
  );
};
