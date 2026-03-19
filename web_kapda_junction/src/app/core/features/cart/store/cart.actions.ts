import { createActionGroup, emptyProps, props } from '@ngrx/store';

export const CartActions = createActionGroup({
  source: 'Cart',
  events: {
    'Add Item': props<{ product: any; quantity?: number; variant?: { color?: string; size?: string } }>(),
    'Remove Item': props<{ productId: string; variant?: { color?: string; size?: string } }>(),
    'Update Quantity': props<{ productId: string; quantity: number; variant?: { color?: string; size?: string } }>(),
    'Clear Cart': emptyProps(),
    'Set Items': props<{ items: Array<{ product: any; quantity: number; variant?: { color?: string; size?: string } }> }>(),
  },
});
