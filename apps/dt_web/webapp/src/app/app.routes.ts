import { Routes, RouterModule } from '@angular/router';

import { AuthGuard } from './services/auth.guard';

import { Home } from './home';
import { Login } from './login';
import { Users } from './users';
import { Sensors } from './sensors';

export const ROUTES: Routes = [
  { path: '',  redirectTo: '/home', pathMatch: 'full' },
  { path: 'home',  component: Home },
  { path: 'login', component: Login },
  { path: 'users', component: Users, canActivate: [AuthGuard] },
  { path: 'sensors', component: Sensors, canActivate: [AuthGuard] }
];

