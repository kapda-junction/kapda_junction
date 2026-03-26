import { createReducer, on } from '@ngrx/store';
import { AuthActions } from './auth.actions';

export interface AuthState {
  user: any;
  token: string | null;
  isAuthenticated: boolean;
  error: string | null;
}

export const initialState: AuthState = {
  user: null,
  token: typeof localStorage !== 'undefined' ? localStorage.getItem('token') : null,
  isAuthenticated: !!(typeof localStorage !== 'undefined' && localStorage.getItem('token')),
  error: null,
};

export const authReducer = createReducer(
  initialState,
  on(AuthActions.loginSuccess, AuthActions.registerSuccess, (state, { user, token }) => ({
    ...state,
    user,
    token,
    isAuthenticated: true,
    error: null,
  })),
  on(AuthActions.loginFailure, AuthActions.registerFailure, (state, { error }) => ({
    ...state,
    error,
  })),
  on(AuthActions.logout, () => ({
    user: null,
    token: null,
    isAuthenticated: false,
    error: null,
  }))
);
