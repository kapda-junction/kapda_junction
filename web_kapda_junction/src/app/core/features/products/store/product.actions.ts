import { createActionGroup, props } from '@ngrx/store';

export const ProductActions = createActionGroup({
  source: 'Products',
  events: {
    'Load Products Request': props<{ params?: Record<string, string> }>(),
    'Load Products Success': props<{ products: any[] }>(),
    'Load Products Failure': props<{ error: string }>(),
  },
});
