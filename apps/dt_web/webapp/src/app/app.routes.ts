import { Routes, RouterModule } from '@angular/router';

import { AuthGuard } from './services/auth.guard';

import { Home } from './home';
import { Login } from './login';
import { Users } from './users';
import { Sensors } from './sensors';
import { Scenarios } from './scenarios';
import { Partitions } from './partitions';
import { Outputs } from './outputs';
import { Events } from './events';

export const ROUTES: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: Home },
  { path: 'login', component: Login },
  { path: 'users', component: Users, canActivate: [AuthGuard] },
  { path: 'sensors', component: Sensors, canActivate: [AuthGuard] },
  { path: 'scenarios', component: Scenarios, canActivate: [AuthGuard] },
  { path: 'partitions', component: Partitions, canActivate: [AuthGuard] },
  { path: 'outputs', component: Outputs, canActivate: [AuthGuard] },
  { path: 'events', component: Events, canActivate: [AuthGuard] }
];

