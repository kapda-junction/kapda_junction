import { createFeatureSelector, createSelector } from '@ngrx/store';
import { ProductsState } from './product.reducer';

export const selectProductsState = createFeatureSelector<ProductsState>('products');

export const selectProducts = createSelector(selectProductsState, (s) => s.list);
export const selectAllProducts = selectProducts;
export const selectProductsLoading = createSelector(selectProductsState, (s) => s.loading);
export const selectProductsError = createSelector(selectProductsState, (s) => s.error);
