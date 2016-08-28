import {
  addProviders,
  inject
} from '@angular/core/testing';

import { provide } from '@angular/core';
import { Http } from '@angular/http';
import { Router } from '@angular/router';

// Load the implementations that should be tested
import { AppComponent } from './app.component';
import { AuthService, NotificationService } from './services';

class MockRouter {
  navigate = jasmine.createSpy('navigate');
}

describe('App', () => {
  // provide our implementations or mocks to the dependency injector
  beforeEach(() => addProviders([
    provide(AuthService, {
      deps: [Http, Router]
    }),
    provide(Router, {useClass: MockRouter}),
    NotificationService,
    AppComponent
  ]));

  it('should have a name', inject([ AppComponent ], (app) => {
    console.log(app);

    expect(app.name).toEqual('Detectino');
  }));

});
