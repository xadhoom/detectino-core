import {
  beforeEachProviders,
  inject,
  injectAsync,
  it
} from '@angular/core/testing';

// Load the implementations that should be tested
import { App } from './app.component';
import { AuthService } from './services';
import { provide } from '@angular/core';
import { Http } from '@angular/http';
import { Router, RootRouter } from '@angular/router';

describe('App', () => {
  // provide our implementations or mocks to the dependency injector
  beforeEachProviders(() => [
    provide(AuthService, {
      deps: [Http, Router]
    }),
    provide(Router, {useClass: RootRouter}),
    App
  ]);

  it('should have a name', inject([ App ], (app) => {
    console.log(app);

    expect(app.name).toEqual('Detectino');
  }));

});
