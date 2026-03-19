import { ActionReducerMap } from '@ngrx/store';
import { authReducer } from '../features/auth/store/auth.reducer';
import { cartReducer } from '../features/cart/store/cart.reducer';
import { cartStorageMetaReducer } from '../features/cart/store/cart.meta-reducer';
import { productReducer } from '../features/products/store/product.reducer';
import { AppState } from './app.state';

export const appReducers: ActionReducerMap<AppState> = {
  auth: authReducer,
  cart: cartStorageMetaReducer(cartReducer),
  products: productReducer
};
