import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { AuthGuardService } from './services/auth-guard.service';

import { HomeComponent } from './home';
import { LoginComponent } from './login';
import { UsersComponent } from './users';
import { SensorsComponent } from './sensors';
import { ScenariosComponent, ScenarioslistComponent } from './scenarios';
import { PartitionsComponent } from './partitions';
import { OutputsComponent } from './outputs';
import { EventsComponent } from './events';
import { SettingsComponent } from './settings';
import { IntrusionComponent } from './intrusion';
import { EventlogsComponent } from './eventlogs';

const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'home', component: HomeComponent, canActivate: [AuthGuardService] },
  { path: 'users', component: UsersComponent, canActivate: [AuthGuardService] },
  { path: 'sensors', component: SensorsComponent, canActivate: [AuthGuardService] },
  { path: 'scenarios', component: ScenariosComponent, canActivate: [AuthGuardService] },
  { path: 'scenarioslist', component: ScenarioslistComponent, canActivate: [AuthGuardService] },
  { path: 'partitions', component: PartitionsComponent, canActivate: [AuthGuardService] },
  { path: 'outputs', component: OutputsComponent, canActivate: [AuthGuardService] },
  { path: 'events', component: EventsComponent, canActivate: [AuthGuardService] },
  { path: 'settings', component: SettingsComponent, canActivate: [AuthGuardService] },
  { path: 'intrusion', component: IntrusionComponent, canActivate: [AuthGuardService] },
  { path: 'eventlogs', component: EventlogsComponent, canActivate: [AuthGuardService] },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
  providers: []
})
export class AppRoutingModule { }
