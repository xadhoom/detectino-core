import {
  inject,
  addProviders
} from '@angular/core/testing';
import { MockBackend } from '@angular/http/testing';
import { Component } from '@angular/core';
import { BaseRequestOptions, Http } from '@angular/http';

// Load the implementations that should be tested
import { Home } from './';

describe('Home', () => {
  // provide our implementations or mocks to the dependency injector
  beforeEach(() => addProviders([
    BaseRequestOptions,
    MockBackend,
    {
      provide: Http,
      useFactory: function(backend, defaultOptions) {
        return new Http(backend, defaultOptions);
      },
      deps: [MockBackend, BaseRequestOptions]
    },
    Home
  ]));

  it('should log ngOnInit', inject([ Home ], (home) => {
    spyOn(console, 'log');
    expect(console.log).not.toHaveBeenCalled();

    home.ngOnInit();
    expect(console.log).toHaveBeenCalled();
  }));

});
