import { AuthState } from '../features/auth/store/auth.reducer';
import { CartState } from '../features/cart/store/cart.reducer';
import { ProductsState } from '../features/products/store/product.reducer';

export interface AppState {
  auth: AuthState;
  cart: CartState;
  products: ProductsState;
}
