import {
  TestComponentBuilder,
  describe,
  expect,
  injectAsync,
  it,
  beforeEachProviders
} from 'angular2/testing';

import {Component, provide, DirectiveResolver} from 'angular2/core';

import {Location, Router, RouteRegistry, ROUTER_PRIMARY_COMPONENT} from 'angular2/router';
import {SpyLocation} from 'angular2/src/mock/location_mock';
import {RootRouter} from 'angular2/src/router/router';

import {DOM} from 'angular2/src/platform/dom/dom_adapter';
import {AboutComponent} from './about.component';

export function main() {
  describe('About component', () => {

    beforeEachProviders(() => [
      RouteRegistry,
      DirectiveResolver,
      provide(Location, {useClass: SpyLocation}),
      provide(ROUTER_PRIMARY_COMPONENT, {useValue: AboutComponent}),
      provide(Router, {useClass: RootRouter})
    ]);

    it('should work',
      injectAsync([TestComponentBuilder], (tcb: TestComponentBuilder) => {
        return tcb.createAsync(TestComponent)
          .then((rootTC) => {
            let aboutDOMEl = rootTC.debugElement.children[0].nativeElement;

            expect(DOM.querySelectorAll(aboutDOMEl, 'h2')[0].textContent).toEqual('Features');
          });
      }));
  });
}

@Component({
  selector: 'test-cmp',
  directives: [AboutComponent],
  template: '<sd-about></sd-about>'
})
class TestComponent {}
