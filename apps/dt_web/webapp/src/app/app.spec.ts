import {
  beforeEachProviders,
  inject,
  injectAsync,
  it
} from '@angular/core/testing';

// Load the implementations that should be tested
import { App } from './app.component';
import { AuthService } from './auth';
import { provide } from '@angular/core';
import { Http } from '@angular/http';
import { Router } from '@angular/router-deprecated';

describe('App', () => {
  // provide our implementations or mocks to the dependency injector
  beforeEachProviders(() => [
    App,
    provide(AuthService, {
      deps: [Http, Router]
    })
  ]);

  it('should have a url', inject([ App ], (app) => {
    expect(app.url).toEqual('https://twitter.com/AngularClass');
  }));

});
