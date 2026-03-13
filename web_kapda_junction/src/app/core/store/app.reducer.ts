import { ActionReducerMap } from '@ngrx/store';
import { authReducer } from '../features/auth/store/auth.reducer';
import { cartReducer } from '../features/cart/store/cart.reducer';
import { productReducer } from '../features/products/store/product.reducer';
import { AppState } from './app.state';

export const appReducers: ActionReducerMap<AppState> = {
  auth: authReducer,
  cart: cartReducer,
  products: productReducer
};
