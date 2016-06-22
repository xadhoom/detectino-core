/*
 * These are globally available services in any component or any other service
 */

// Angular 2
import { HashLocationStrategy, LocationStrategy } from '@angular/common';
import { FormBuilder, disableDeprecatedForms, provideForms } from '@angular/forms';
// Angular 2 Http
import { HTTP_PROVIDERS } from '@angular/http';

/*
* Application Providers/Directives/Pipes
* providers/directives/pipes that only live in our browser environment
*/
export const APPLICATION_PROVIDERS = [
  disableDeprecatedForms(),
  provideForms(),
  FormBuilder,
  HTTP_PROVIDERS,
  {provide: LocationStrategy, useClass: HashLocationStrategy }
];

export const PROVIDERS = [
  APPLICATION_PROVIDERS
];
