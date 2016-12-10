import {
  inject,
  TestBed
} from '@angular/core/testing';
import { MockBackend } from '@angular/http/testing';
import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { BaseRequestOptions, Http } from '@angular/http';
import { Observable } from 'rxjs/Observable';

import {
  NotificationService
} from '../services';

// Load the implementations that should be tested
import { Home } from './';

class MockRouter {
  navigate = jasmine.createSpy('navigate');
}

describe('Home', () => {
  // provide our implementations or mocks to the dependency injector
  beforeEach(() => TestBed.configureTestingModule({
    providers: [
      BaseRequestOptions,
      MockBackend,
      {
        provide: Http,
        useFactory: function (backend, defaultOptions) {
          return new Http(backend, defaultOptions);
        },
        deps: [MockBackend, BaseRequestOptions]
      },
      {
        provide: Router,
        useFactory: function () {
          return new MockRouter();
        }
      },
      NotificationService,
      Home
    ]
  }));

  it('should toggle settings', inject([Home], (home) => {
    expect(home.displaySettings).toBe(false);
    home.toggleSettings();
    expect(home.displaySettings).toBe(true);
  }));

});
