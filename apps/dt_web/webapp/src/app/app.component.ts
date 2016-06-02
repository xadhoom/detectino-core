/*
 * Angular 2 decorators and services
 */
import { Component, ViewEncapsulation, provide } from '@angular/core';
import { RouteConfig, Router } from '@angular/router-deprecated';
import { Http } from '@angular/http';

import { Home } from './home';
import { About } from './about';
import { Login } from './login';
import { RouterActive } from './router-active';
import { AuthService } from './auth';

/*
 * App Component
 * Top Level Component
 */
@Component({
  selector: 'app',
  pipes: [ ],
  directives: [ RouterActive ],
  providers: [
    provide(AuthService, {
      useClass: AuthService,
      deps: [Http, Router]
    })
  ],
  encapsulation: ViewEncapsulation.None,
  styles: [
    require('normalize.css'),
    require('./app.css')
  ],
  template: `
    <md-content>
      <md-toolbar color="primary">
          <span>{{ name }}</span>
          <span class="fill"></span>
          <button md-button router-active [routerLink]=" ['Index'] ">
            Index
          </button>
          <button md-button router-active [routerLink]=" ['Home'] ">
            Home
          </button>
          <button md-button router-active [routerLink]=" ['About'] " *ngIf="auth.authenticated()">
            About
          </button>
          <button md-button router-active [routerLink]=" ['Login'] " *ngIf="!auth.authenticated()">
            Log In
          </button>
          <button md-button (click)="auth.logout()" *ngIf="auth.authenticated()">
            Log Out
          </button>
      </md-toolbar>

      <md-progress-bar mode="indeterminate" color="primary" *ngIf="loading"></md-progress-bar>

      <router-outlet></router-outlet>

      </md-content>
  `
})

@RouteConfig([
  { path: '/',      name: 'Index', component: Home, useAsDefault: true },
  { path: '/home',  name: 'Home',  component: Home },
  { path: '/about', name: 'About', component: About },
  { path: '/login', name: 'Login', component: Login }
])

export class App {
  angularclassLogo = 'assets/img/angularclass-avatar.png';
  loading = false;
  name = 'Angular 2 Webpack Starter';
  url = 'https://twitter.com/AngularClass';

  constructor(private auth: AuthService) { }

}
