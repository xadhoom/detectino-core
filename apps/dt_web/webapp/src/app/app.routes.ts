import { provideRouter, RouterConfig } from '@angular/router';

import { AuthGuard } from './services/auth.guard';

import { Home } from './home';
import { Login } from './login';
import { Users } from './users';

export const routes = [
  { path: '',  redirectTo: '/home', terminal: true },
  { path: 'home',  component: Home },
  { path: 'login', component: Login },
  { path: 'users', component: Users, canActivate: [AuthGuard] }
];

export const APP_ROUTER_PROVIDERS = [
  provideRouter(routes),
  AuthGuard
];

