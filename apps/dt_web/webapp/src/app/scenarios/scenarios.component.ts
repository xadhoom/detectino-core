import { Component, OnInit } from '@angular/core';

import { ScenarioService, NotificationService } from '../services';

import { Scenario } from '../models/scenario';

import { SelectItem } from 'primeng/primeng';

@Component({
    selector: 'scenarios',
    template: require('./scenarios.component.html'),
    styles: [ require('./scenarios.component.css') ]
})

export class Scenarios implements OnInit {

  scenario: Scenario;

  scenarios: Scenario[];

  selectedScenario: Scenario;

  displayDialog: boolean;

  newScenario: boolean;

  errorMessage: string;

  constructor(private scenarioService: ScenarioService,
              private notificationService: NotificationService) {};

  ngOnInit() {
    this.all();
  };

  all() {
    this.scenarioService.all().
      subscribe(
        scenarios => this.scenarios = scenarios,
        error => this.onError(error)
    );
  };

  save() {
    this.scenarioService.save(this.scenario).
      subscribe(
        scenario => this.refresh(),
        error => this.onError(error)
    );
  };

  destroy() {
    this.scenarioService.destroy(this.scenario).
      subscribe(
        success => this.refresh(),
        error => this.onError(error)
    );
  };

  onError(error: any) {
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  };

  refresh() {
    this.displayDialog = false;
    this.all();
  };

  showDialogToAdd() {
    this.newScenario = true;
    this.scenario = new Scenario();
    this.displayDialog = true;
  }

  onRowSelect(event) {
    this.newScenario = false;
    this.scenario = this.cloneScenario(event.data);
    this.displayDialog = true;
  };

  cloneScenario(s: Scenario): Scenario {
    let scenario = new Scenario();
    for (let prop in s) {
      if (prop) {
        scenario[prop] = s[prop];
      }
    }
    return scenario;
  }

}

