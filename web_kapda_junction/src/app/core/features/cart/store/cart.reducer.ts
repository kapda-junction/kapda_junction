import { createReducer, on } from '@ngrx/store';
import { CartActions } from './cart.actions';

export interface CartItem {
  product: any;
  quantity: number;
  variant?: { color?: string; size?: string };
}

function itemMatches(item: CartItem, productId: string, variant?: { color?: string; size?: string }): boolean {
  if (item.product._id !== productId) return false;
  const hasV = variant && ((variant.color !== undefined && variant.color !== '') || (variant.size !== undefined && variant.size !== ''));
  const itemHasV = item.variant && ((item.variant.color !== undefined && item.variant.color !== '') || (item.variant.size !== undefined && item.variant.size !== ''));
  if (!hasV && !itemHasV) return true;
  if (!hasV || !itemHasV) return false;
  return (item.variant?.color ?? '') === (variant?.color ?? '') && (item.variant?.size ?? '') === (variant?.size ?? '');
}

export interface CartState {
  items: CartItem[];
}

export const initialState: CartState = {
  items: [],
};

export const cartReducer = createReducer(
  initialState,
  on(CartActions.addItem, (state, { product, quantity = 1, variant }) => {
    const existing = state.items.find((i) => itemMatches(i, product._id, variant));
    if (existing) {
      return {
        ...state,
        items: state.items.map((i) =>
          itemMatches(i, product._id, variant) ? { ...i, quantity: i.quantity + quantity } : i
        ),
      };
    }
    return { ...state, items: [...state.items, { product, quantity, variant }] };
  }),
  on(CartActions.removeItem, (state, { productId, variant }) => ({
    ...state,
    items: state.items.filter((i) => !itemMatches(i, productId, variant)),
  })),
  on(CartActions.updateQuantity, (state, { productId, quantity, variant }) => ({
    ...state,
    items: state.items.map((i) =>
      itemMatches(i, productId, variant) ? { ...i, quantity } : i
    ),
  })),
  on(CartActions.clearCart, () => initialState),
  on(CartActions.setItems, (_, { items }) => ({ items }))
);
