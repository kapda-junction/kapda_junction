import { createReducer, on } from '@ngrx/store';
import { AuthActions } from './auth.actions';

export interface AuthState {
  user: any;
  token: string | null;
  isAuthenticated: boolean;
}

export const initialState: AuthState = {
  user: null,
  token: typeof localStorage !== 'undefined' ? localStorage.getItem('token') : null,
  isAuthenticated: !!(typeof localStorage !== 'undefined' && localStorage.getItem('token')),
};

export const authReducer = createReducer(
  initialState,
  on(AuthActions.loginSuccess, (state, { user, token }) => ({
    ...state,
    user,
    token,
    isAuthenticated: true,
  })),
  on(AuthActions.logout, () => ({ ...initialState, token: null }))
);
