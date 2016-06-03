/*
 * Angular 2 decorators and services
 */
import { Component, ViewEncapsulation, provide } from '@angular/core';
import { RouteConfig, Router } from '@angular/router-deprecated';
import { Http } from '@angular/http';

import {MD_SIDENAV_DIRECTIVES} from '@angular2-material/sidenav';
import {MD_LIST_DIRECTIVES} from '@angular2-material/list';
import {MdIcon, MdIconRegistry} from '@angular2-material/icon';

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
  directives: [
    RouterActive,
    MD_SIDENAV_DIRECTIVES,
    MD_LIST_DIRECTIVES,
    MdIcon
  ],
  providers: [
    provide(AuthService, {
      useClass: AuthService,
      deps: [Http, Router]
    })
  ],
  encapsulation: ViewEncapsulation.None,
  styles: [
    require('normalize.css'),
    require('./app.component.css')
  ],
  template: require('./app.component.html')
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
  name = 'Detectino';
  url = 'https://twitter.com/AngularClass';

  constructor(private auth: AuthService) { }

}
