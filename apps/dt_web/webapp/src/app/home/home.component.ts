import { Component, OnInit } from '@angular/core';

import { ScenarioService, NotificationService } from '../services';

import { Scenario } from '../models/scenario';

@Component({
  selector: 'home',
  styles: [require('./home.component.css')],
  template: require('./home.component.html')
})

export class Home implements OnInit {

  scenarios: Scenario[];

  errorMessage: string;

  constructor(private scenarioService: ScenarioService,
    private notificationService: NotificationService) { };

  ngOnInit() {
    console.log('hello `Home` component');
    this.scenarios = [];
    this.scenarioService.get_available().subscribe(
      scenarios => this.setScenarios(scenarios),
      error => this.onError(error)
    );
  }

  onError(error: any) {
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  }

  private setScenarios(scenarios) {
    this.scenarios = scenarios;
  }
}
