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
  moduleId: module.id,
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
  name = 'Angular 2 Webpack Starter';
  url = 'https://twitter.com/AngularClass';

  constructor(private auth: AuthService) { }

}
