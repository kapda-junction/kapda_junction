import { Action, ActionReducer } from '@ngrx/store';
import { CartState } from './cart.reducer';

const CART_KEY = 'cart';

export function cartStorageMetaReducer(reducer: ActionReducer<CartState>): ActionReducer<CartState> {
  return (state: CartState | undefined, action: Action) => {
    if (action.type === '@ngrx/store/init') {
      if (typeof localStorage !== 'undefined') {
        try {
          const stored = localStorage.getItem(CART_KEY);
          if (stored) {
            const parsed = JSON.parse(stored);
            if (parsed?.items && Array.isArray(parsed.items) && parsed.items.length > 0) {
              return { items: parsed.items };
            }
          }
        } catch {}
      }
      return reducer(state, action);
    }
    const nextState = reducer(state, action);
    if (typeof localStorage !== 'undefined' && nextState?.items) {
      try {
        if (nextState.items.length > 0) {
          localStorage.setItem(CART_KEY, JSON.stringify({ items: nextState.items }));
        } else {
          localStorage.removeItem(CART_KEY);
        }
      } catch {}
    }
    return nextState;
  };
}
