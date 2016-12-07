import { Component, OnInit, ViewEncapsulation, Input } from '@angular/core';

import { Scenario } from '../models/scenario';

@Component({
  selector: 'dt-scenariolist',
  encapsulation: ViewEncapsulation.None,
  styles: [require('./scenariolist.component.css')],
  template: require('./scenariolist.component.html')
})

export class Scenariolist implements OnInit {
  @Input() scenarios: Scenario[];

  constructor() { }

  ngOnInit() { }

  getInitials(name: string) {
    return name[0];
  }
}
