import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Scenario } from '../models/scenario';
import { PindialogComponent } from '../pindialog/pindialog.component';
import { PinService, NotificationService, PhoenixChannelService } from '../services';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.scss']
})

export class SettingsComponent implements OnInit {
  links: Object[];

  public isArmed: boolean;

  constructor(private router: Router,
    public pinSrv: PinService, private socket: PhoenixChannelService,
    private notificationService: NotificationService
  ) {
    this.isArmed = false;
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
    this.socket.subscribe('event:arm', 'arm', (isarmed) => this.updateArmState(isarmed));
  }

  openLink(path: string) {
    if (this.canOpen(path)) {
      this.router.navigateByUrl('/' + path);
    }
  }

  private canOpen(path: string) {
    const notWhenArmed = ['sensors', 'partitions', 'events', 'outputs'];
    if (notWhenArmed.includes(path) && this.isArmed) {
      const msg = 'Cannot configure when armed!';
      this.notificationService.error(msg);
      return false;
    }
    return true;
  }

  private updateArmState(isarmed) {
    if (isarmed.armed) {
      this.isArmed = true;
    } else {
      this.isArmed = false;
    }
  }
}

