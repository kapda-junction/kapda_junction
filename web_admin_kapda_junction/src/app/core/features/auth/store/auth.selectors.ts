import { createFeatureSelector, createSelector } from '@ngrx/store';
import { AuthState } from './auth.reducer';

export const selectAuthState = createFeatureSelector<AuthState>('auth');

export const selectUser = createSelector(selectAuthState, (state: any) => state.user);
export const selectToken = createSelector(selectAuthState, (state: any) => state.token);
export const selectIsAuthenticated = createSelector(selectAuthState, (state: any) => state.isAuthenticated);
export const selectAuthLoading = createSelector(selectAuthState, (state: any) => state.loading);
export const selectAuthError = createSelector(selectAuthState, (state: any) => state.error);
