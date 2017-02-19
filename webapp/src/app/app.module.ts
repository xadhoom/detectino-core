import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpModule, Http, JsonpModule, RequestOptions } from '@angular/http';
import { Router } from '@angular/router';
import { AppRoutingModule } from './app-routing.module';
import { AuthHttp, AuthConfig } from 'angular2-jwt';

import {
  AuthService, AuthGuardService, NotificationService,
  UserService, SensorService, ScenarioService, PartitionService,
  PartitionScenarioService, OutputService, EventService, PhoenixChannelService,
  PinService, BeeperService
} from './services';

import {
  ButtonModule, ToolbarModule, MessagesModule, GrowlModule,
  DialogModule, InputTextModule, DropdownModule, PasswordModule,
  DataTableModule, SpinnerModule, CheckboxModule, PickListModule,
  InputSwitchModule
} from 'primeng/primeng';

import { MdIconModule, MdIconRegistry } from '@angular2-material/icon';

import { AppComponent } from './app.component';
import { HomeComponent } from './home/home.component';
import { LoginComponent } from './login/login.component';
import { UsersComponent } from './users/users.component';
import { SensorsComponent } from './sensors/sensors.component';
import { ScenariosComponent } from './scenarios/scenarios.component';
import { ScenarioslistComponent } from './scenarios/scenarioslist/scenarioslist.component';
import { PartitionsComponent } from './partitions/partitions.component';
import { OutputsComponent } from './outputs/outputs.component';
import { EventsComponent } from './events/events.component';
import { SettingsComponent } from './settings/settings.component';
import { IntrusionComponent } from './intrusion/intrusion.component';
import { PartitionConfigComponent } from './events/partition-config/partition-config.component';
import { SensorConfigComponent } from './events/sensor-config/sensor-config.component';
import { PartitionsScenariosComponent } from './scenarios/partitions-scenarios/partitions-scenarios.component';
import { PindialogComponent } from './pindialog/pindialog.component';

export function authHttpServiceFactory(http: Http, options: RequestOptions) {
  return new AuthHttp(new AuthConfig({
    tokenName: 'id_token',
    noTokenScheme: true,
    globalHeaders: [
      { 'Accept': 'application/json' },
      { 'Content-Type': 'application/json' }
    ],
    noJwtError: false
  }), http, options);
}

@NgModule({
  declarations: [
    AppComponent,
    HomeComponent,
    LoginComponent,
    UsersComponent,
    SensorsComponent,
    ScenariosComponent,
    ScenarioslistComponent,
    PartitionsComponent,
    OutputsComponent,
    EventsComponent,
    SettingsComponent,
    IntrusionComponent,
    PartitionConfigComponent,
    SensorConfigComponent,
    ScenarioslistComponent,
    PartitionsScenariosComponent,
    PindialogComponent
  ],
  imports: [
    BrowserModule,
    FormsModule,
    HttpModule,
    AppRoutingModule,
    ButtonModule, ToolbarModule, MessagesModule, GrowlModule,
    DialogModule, InputTextModule, DropdownModule, PasswordModule,
    DataTableModule, SpinnerModule, CheckboxModule, PickListModule,
    InputSwitchModule,
    JsonpModule, MdIconModule
  ],
  providers: [{
    provide: AuthHttp,
    useFactory: authHttpServiceFactory,
    deps: [Http, RequestOptions]
  }, {
    provide: AuthService,
    useClass: AuthService,
    deps: [Http, AuthHttp, Router, PhoenixChannelService]
  }, MdIconRegistry, NotificationService,
    UserService,
    SensorService,
    ScenarioService,
    PartitionService,
    PartitionScenarioService,
    OutputService,
    EventService,
    AuthGuardService,
    PhoenixChannelService, PinService, BeeperService],
  bootstrap: [AppComponent]
})
export class AppModule { }
