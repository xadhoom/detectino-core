// App
export * from './app.component';

import {provide} from '@angular/core';
import {HTTP_PROVIDERS, Http} from '@angular/http';
import {AuthConfig, AuthHttp} from 'angular2-jwt';

// Application wide providers
export const APP_PROVIDERS = [
  HTTP_PROVIDERS,
  provide(AuthHttp, {
    useFactory: (http) => {
      return new AuthHttp(new AuthConfig({
        tokenName: 'id_token',
        noTokenScheme: true,
        globalHeaders: [
          {'Accept': 'application/json'},
          {'Content-Type': 'application/json'}
        ],
        noJwtError: false
      }), http);
    },
    deps: [Http]
  })
];
