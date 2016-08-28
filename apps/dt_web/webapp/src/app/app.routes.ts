import { Routes, RouterModule, provideRouter, RouterConfig } from '@angular/router';

import { AuthGuard } from './services/auth.guard';

import { Home } from './home';
import { Login } from './login';
import { Users } from './users';

export const ROUTES: Routes = [
  { path: '',  redirectTo: '/home', terminal: true },
  { path: 'home',  component: Home },
  { path: 'login', component: Login },
  { path: 'users', component: Users, canActivate: [AuthGuard] }
];

