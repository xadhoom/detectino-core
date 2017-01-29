import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Scenario } from '../models/scenario';
import { PindialogComponent } from '../pindialog/pindialog.component';
import { PinService } from '../services';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.scss']
})

export class SettingsComponent implements OnInit {
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

