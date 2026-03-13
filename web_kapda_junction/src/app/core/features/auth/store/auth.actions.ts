import { createActionGroup, emptyProps, props } from '@ngrx/store';

export const AuthActions = createActionGroup({
  source: 'Auth',
  events: {
    'Login Success': props<{ user: any; token: string }>(),
    'Logout': emptyProps(),
  },
});
