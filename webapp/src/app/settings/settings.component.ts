import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';

import { Scenario } from '../models/scenario';
import { Scenariolist } from '../scenarios/scenariolist.component';
import { Pindialog } from '../pindialog/pindialog.component';
import { PinService } from '../services';

@Component({
  selector: 'settings',
  styleUrls: ['./settings.component.css', '../shared/common.scss'],
  templateUrl: './settings.component.html'
})

export class Settings implements OnInit {
  links: Object[];

  constructor(private router: Router,
    private pinSrv: PinService) {
    this.links = [
      { path: 'users' },
      { path: 'sensors' },
      { path: 'scenarios' },
      { path: 'partitions' },
      { path: 'outputs' },
      { path: 'events' }
    ];
  };

  ngOnInit() { }

  openLink(path: string) {
    this.router.navigateByUrl('/' + path);
  }
}
