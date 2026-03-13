import { ActionReducerMap } from '@ngrx/store';
import { authReducer } from '../features/auth/store/auth.reducer';
import { AppState } from './app.state';

export const appReducers: ActionReducerMap<AppState> = {
  auth: authReducer,
};
