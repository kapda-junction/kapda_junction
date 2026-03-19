import { createActionGroup, emptyProps, props } from '@ngrx/store';

export const AuthActions = createActionGroup({
  source: 'Auth',
  events: {
    'Login Request': props<{ email: string; password: string }>(),
    'Login Success': props<{ user: any; token: string }>(),
    'Login Failure': props<{ error: string }>(),
    'Register Request': props<{ name: string; email: string; password: string }>(),
    'Register Success': props<{ user: any; token: string }>(),
    'Register Failure': props<{ error: string }>(),
    'Logout': emptyProps(),
  },
});
