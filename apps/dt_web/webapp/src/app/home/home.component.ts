import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { ScenarioService, NotificationService } from '../services';

import { Scenario } from '../models/scenario';
import { Scenariolist } from '../scenarios/scenariolist.component';

@Component({
  selector: 'home',
  styleUrls: ['./home.component.css'],
  templateUrl: './home.component.html'
})

export class Home implements OnInit {
  scenarios: Scenario[];

  links: Object[];

  errorMessage: string;

  constructor(private router: Router, private scenarioService: ScenarioService,
    private notificationService: NotificationService) {
    this.links = [
      { path: 'users' },
      { path: 'sensors' },
      { path: 'scenarios' },
      { path: 'partitions' },
      { path: 'outputs' },
      { path: 'events' }
    ];
  };

  ngOnInit() {
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

  openLink(path: string) {
    this.router.navigateByUrl('/' + path);
  }

  private setScenarios(scenarios) {
    this.scenarios = scenarios;
  }
}
