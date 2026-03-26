import { inject } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { Store } from '@ngrx/store';
import { of } from 'rxjs';
import { catchError, debounceTime, map, switchMap, withLatestFrom } from 'rxjs/operators';
import { CartActions } from './cart.actions';
import { selectCartItems } from './cart.selectors';
import { selectAuthState } from '../../auth/store/auth.selectors';
import { AuthActions } from '../../auth/store/auth.actions';
import { ApiService } from '../../../services/api.service';
import { AppState } from '../../../store/app.state';

function toApiItem(item: { product: any; quantity: number; variant?: { color?: string; size?: string } }) {
  return {
    product: item.product?._id,
    quantity: item.quantity,
    color: item.variant?.color ?? '',
    size: item.variant?.size ?? ''
  };
}

function fromApiItem(apiItem: { product: any; quantity: number; color?: string; size?: string }) {
  const color = apiItem.color || '';
  const size = apiItem.size || '';
  return {
    product: apiItem.product,
    quantity: apiItem.quantity,
    variant: (color || size) ? { color, size } : undefined
  };
}

function authHeader(token?: string | null): Record<string, string> | undefined {
  return token ? { Authorization: `Bearer ${token}` } : undefined;
}

export class CartEffects {
  private actions$ = inject(Actions);
  private store = inject(Store<AppState>);
  private api = inject(ApiService);

  loadCart$ = createEffect(() =>
    this.actions$.pipe(
      ofType('@ngrx/store/init'),
      withLatestFrom(this.store.select(selectAuthState)),
      switchMap(([, auth]) => {
        if (!auth?.isAuthenticated || !auth?.token) return of({ type: 'NO_OP' });
        return this.api.get<{ items: any[] }>('/cart', undefined, { headers: authHeader(auth.token) }).pipe(
          map((cart) => {
            const items = (cart?.items ?? []).map(fromApiItem).filter((i) => i.product);
            return CartActions.setItems({ items });
          }),
          catchError(() => of({ type: 'NO_OP' }))
        );
      })
    )
  );

  loadCartOnAuthSuccess$ = createEffect(() =>
    this.actions$.pipe(
      ofType(AuthActions.loginSuccess, AuthActions.registerSuccess),
      switchMap(({ token }) =>
        this.api.get<{ items: any[] }>('/cart', undefined, { headers: authHeader(token) }).pipe(
          map((cart) => {
            const items = (cart?.items ?? []).map(fromApiItem).filter((i) => i.product);
            return CartActions.setItems({ items });
          }),
          catchError(() => of({ type: 'NO_OP' }))
        )
      )
    )
  );

  saveCart$ = createEffect(
    () =>
      this.actions$.pipe(
        ofType(
          CartActions.addItem,
          CartActions.removeItem,
          CartActions.updateQuantity,
          CartActions.clearCart
        ),
        debounceTime(500),
        withLatestFrom(
          this.store.select(selectCartItems),
          this.store.select(selectAuthState)
        ),
        switchMap(([, items, auth]) => {
          if (!auth?.isAuthenticated || !auth?.token || !items) return of({ type: 'NO_OP' });
          const apiItems = items.map(toApiItem);
          return this.api.put('/cart', { items: apiItems }, { headers: authHeader(auth.token) }).pipe(
            map((cart: any) => {
              const loaded = (cart?.items ?? []).map(fromApiItem).filter((i: any) => i.product);
              return CartActions.setItems({ items: loaded });
            }),
            catchError(() => of({ type: 'NO_OP' }))
          );
        })
      ),
    { dispatch: true }
  );
}
