import {
  TestBed,
  inject
} from '@angular/core/testing';

import { Http } from '@angular/http';
import { Router } from '@angular/router';
import { ElementRef } from '@angular/core';

// Load the implementations that should be tested
import { AppComponent } from './app.component';
import {
  AuthService, NotificationService, PhoenixChannelService
} from './services';

class MockRouter {
  navigate = jasmine.createSpy('navigate');
}

class MockElementRef implements ElementRef {
  nativeElement = {};
}

class MockPhoenixService {
}

describe('App', () => {
  // provide our implementations or mocks to the dependency injector
  beforeEach(() => TestBed.configureTestingModule({
    providers: [
      { provide: AuthService, deps: [Http, Router] },
      {
        provide: ElementRef,
        useFactory: function () {
          return new MockElementRef();
        }
      },
      {
        provide: Router,
        useFactory: function () {
          return new MockRouter();
        },
        deps: [MockRouter]
      },
      {
        provide: PhoenixChannelService,
        useFactory: function () {
          return new MockPhoenixService();
        }
      },
      NotificationService,
      AppComponent,
      MockRouter
    ]
  }));

  it('should have a name', inject([AppComponent], (app) => {
    console.log(app);

    expect(app.name).toEqual('Detectino');
  }));

});
