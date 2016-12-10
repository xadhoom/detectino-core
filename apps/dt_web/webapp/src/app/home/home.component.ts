import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { NotificationService } from '../services';

import { Scenario } from '../models/scenario';
import { Scenariolist } from '../scenarios/scenariolist.component';

@Component({
  selector: 'home',
  styleUrls: ['./home.component.css'],
  templateUrl: './home.component.html'
})

export class Home implements OnInit {
  links: Object[];

  errorMessage: string;

  constructor(private router: Router,
    private notificationService: NotificationService) {
    this.links = [
      { path: 'users' },
      { path: 'sensors' },
      { path: 'scenarios' },
      { path: 'scenarioslist' },
      { path: 'partitions' },
      { path: 'outputs' },
      { path: 'events' }
    ];
  };

  ngOnInit() { }

  onError(error: any) {
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  }

  openLink(path: string) {
    this.router.navigateByUrl('/' + path);
  }
}
