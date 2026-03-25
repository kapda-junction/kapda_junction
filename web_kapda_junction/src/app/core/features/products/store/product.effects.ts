import { inject } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { catchError, map, switchMap } from 'rxjs/operators';
import { ProductActions } from './product.actions';
import { ApiService } from '../../../services/api.service';

export class ProductEffects {
  private actions$ = inject(Actions);
  private api = inject(ApiService);

  loadProducts$ = createEffect(
    () =>
    this.actions$.pipe(
      ofType(ProductActions.loadProductsRequest),
      switchMap(({ params }) => {
        const q =
          params && Object.keys(params).length > 0
            ? Object.fromEntries(Object.entries(params).filter(([, v]) => v != null && v !== ''))
            : undefined;
        return this.api.get<{ products: any[] }>('/products', q).pipe(
          map((res) => ProductActions.loadProductsSuccess({ products: res?.products ?? [] })),
          catchError((err) => of(ProductActions.loadProductsFailure({ error: err.message })))
        );
      })
    )
  );
}
