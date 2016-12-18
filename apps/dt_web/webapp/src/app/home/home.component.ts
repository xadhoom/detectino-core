import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { NotificationService, PinService } from '../services';

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
  displaySettings: boolean;

  private pin: string;
  private pinmsg: string;
  private realpin: string;

  constructor(private router: Router,
    private notificationService: NotificationService,
    private pinSrv: PinService) {
    this.pin = '';
    this.realpin = '';
    this.pinmsg = 'enter pin';
    this.displaySettings = false;
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

  openScenarios() {
    this.openLink('/scenarioslist');
  }

  toggleSettings() {
    this.displaySettings = !this.displaySettings;
  }

  private pinKey(value: string) {
    if (this.realpin.length >= 6) { return; }

    if (this.realpin === '') {
      this.pinmsg = '';
    }

    this.realpin = this.realpin + value;
    this.pin = this.pin + '*';
  }

  private resetPin() {
    this.pin = '';
    this.realpin = '';
    this.pinmsg = 'enter pin';
  }

  private setPin() {
    this.pinSrv.setPin(this.realpin).
      subscribe(
      success => { this.resetPin(); },
      error => this.onError(error)
      );
  }

  private onError(error: any) {
    this.resetPin();
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  }

}
