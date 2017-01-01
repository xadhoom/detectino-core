import { Component, OnInit, ViewEncapsulation, Input } from '@angular/core';

import { ScenarioService, NotificationService, PinService } from '../services';
import { Scenario } from '../models/scenario';

@Component({
  selector: 'dt-scenariolist',
  styleUrls: ['./scenariolist.component.css', '../shared/common.scss'],
  templateUrl: './scenariolist.component.html'
})

export class Scenariolist implements OnInit {
  scenarios: Scenario[];
  errorMessage: string;

  constructor(private scenarioService: ScenarioService,
    private notificationService: NotificationService,
    private pinSrv: PinService) { }

  ngOnInit() {
    this.scenarios = [];
    this.scenarioService.get_available().subscribe(
      scenarios => this.setScenarios(scenarios),
      error => this.onError(error)
    );
  }

  getInitials(name: string) {
    return name[0];
  }

  run(s: Scenario) {
    let runOp = this.scenarioService.run(s);
    runOp.subscribe(
      res => console.log(res),
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
