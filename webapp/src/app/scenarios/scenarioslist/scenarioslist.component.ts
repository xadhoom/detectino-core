import { Component, OnInit } from '@angular/core';
import { ScenarioService, NotificationService, PinService } from '../../services';
import { Scenario } from '../../models/scenario';

@Component({
  selector: 'app-scenarioslist',
  templateUrl: './scenarioslist.component.html',
  styleUrls: ['./scenarioslist.component.scss']
})

export class ScenarioslistComponent implements OnInit {
  scenarios: Scenario[];
  errorMessage: string;

  constructor(private scenarioService: ScenarioService,
    private notificationService: NotificationService,
    public pinSrv: PinService) { }

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
    const runOp = this.scenarioService.run(s);
    runOp.subscribe(
      res => this.notificationService.success('Scenario started successfully'),
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

