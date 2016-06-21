/*
 * Angular 2 decorators and services
 */
import { Component, ViewEncapsulation, provide } from '@angular/core';
import { Router } from '@angular/router';
import { Http } from '@angular/http';

import { AuthService } from './services';

import {Button, Toolbar} from 'primeng/primeng';

/*
 * App Component
 * Top Level Component
 */
@Component({
  selector: 'app',
  pipes: [ ],
  directives: [
    Toolbar,
    Button
  ],
  providers: [
    provide(AuthService, {
      useClass: AuthService,
      deps: [Http, Router]
    })
  ],
  encapsulation: ViewEncapsulation.None,
  styles: [
    require('./app.component.css')
  ],
  template: require('./app.component.html')
})

export class App {
  angularclassLogo = 'assets/img/angularclass-avatar.png';
  loading = false;
  name = 'Detectino';

  constructor(private router: Router, private auth: AuthService) { }

}
