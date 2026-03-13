import { createActionGroup, emptyProps, props } from '@ngrx/store';

export const ProductActions = createActionGroup({
  source: 'Products',
  events: {
    'Load Products Request': emptyProps(),
    'Load Products Success': props<{ products: any[] }>(),
    'Load Products Failure': props<{ error: string }>(),
  },
});
