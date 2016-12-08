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
  ScenarioService, NotificationService
} from '../services';

// Load the implementations that should be tested
import { Home } from './';

class MockRouter {
  navigate = jasmine.createSpy('navigate');
}

class MockScenarioService {
  public get_available() {
    return Observable.create(function (observer) {
      observer.next([]);
      observer.complete();
    });
  }
};

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
      {
        provide: ScenarioService,
        useFactory: function () {
          return new MockScenarioService();
        }
      },
      NotificationService,
      Home
    ]
  }));

  it('should load scenarios', inject([Home], (home) => {
    expect(home.scenarios).toBe(undefined);
    home.ngOnInit();
    expect(home.scenarios).toEqual([]);
  }));

});
