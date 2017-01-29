import { Component, OnInit, ViewChild } from '@angular/core';
import { ScenarioService, NotificationService } from '../services';
import { Scenario } from '../models/scenario';
import { PartitionsScenariosComponent } from './partitions-scenarios/partitions-scenarios.component';
import { SelectItem } from 'primeng/primeng';
import { Observable } from 'rxjs/Rx';
import 'rxjs/operator/concatAll';

@Component({
  selector: 'app-scenarios',
  templateUrl: './scenarios.component.html',
  styleUrls: ['./scenarios.component.scss']
})

export class ScenariosComponent implements OnInit {

  @ViewChild('partitionsscenarios')
  partitionsscenarios: PartitionsScenariosComponent;

  scenario: Scenario;

  scenarios: Scenario[];

  selectedScenario: Scenario;

  displayDialog: boolean;

  newScenario: boolean;

  errorMessage: string;

  constructor(private scenarioService: ScenarioService,
    private notificationService: NotificationService) { };

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
    let s2: Observable<any> = null;
    let s1 = this.scenarioService.save(this.scenario);
    s2 = this.partitionsscenarios ? this.partitionsscenarios.saveAll() : null;
    let s3 = null;

    if (s2) {
      s3 = Observable.concat(s1, s2);
    } else {
      s3 = s1;
    }
    s3.
      subscribe(
      success => this.refresh(),
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


