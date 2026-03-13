import { createReducer, on } from '@ngrx/store';
import { ProductActions } from './product.actions';

export interface ProductsState {
  list: any[];
  loading: boolean;
  error: string | null;
}

export const initialState: ProductsState = {
  list: [],
  loading: false,
  error: null,
};

export const productReducer = createReducer(
  initialState,
  on(ProductActions.loadProductsRequest, (state) => ({ ...state, loading: true, error: null })),
  on(ProductActions.loadProductsSuccess, (state, { products }) => ({
    ...state,
    list: products,
    loading: false,
    error: null,
  })),
  on(ProductActions.loadProductsFailure, (state, { error }) => ({
    ...state,
    loading: false,
    error,
  }))
);
