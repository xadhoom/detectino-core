import 'script!primeui/primeui-ng-all.min.js';
import 'script!./assets/theme/layout/js/layout.js';
/*
 * Providers provided by Angular
 */
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { AppModule } from './app/app.module';

platformBrowserDynamic().bootstrapModule(AppModule);

