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
      switchMap(() =>
        this.api.get<{ products: any[] }>('/products').pipe(
          map((res) => ProductActions.loadProductsSuccess({ products: res?.products ?? [] })),
          catchError((err) => of(ProductActions.loadProductsFailure({ error: err.message })))
        )
      )
    )
  );
}
