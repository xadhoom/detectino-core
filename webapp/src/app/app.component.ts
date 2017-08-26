import {
  Component, AfterViewInit, ElementRef, Renderer,
  ViewChild, Input
} from '@angular/core';

import { Router } from '@angular/router';
import { Http } from '@angular/http';
import { Observable } from 'rxjs/Observable';
import { Subscription } from 'rxjs/Subscription';

import { Message } from 'primeng/primeng';

import {
  NotificationService, AuthService,
  PhoenixChannelService, PinService, BeeperService
} from './services';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})

export class AppComponent implements AfterViewInit {
  name = 'Detectino';

  subscription: Subscription;

  _notifications: Message[] = [];

  public time: string;
  public date: string;

  public isArmed: boolean;
  public unAckedAlarms: boolean;

  constructor(private el: ElementRef, public router: Router,
    public auth: AuthService,
    private notificationService: NotificationService,
    public pinSrv: PinService,
    private socket: PhoenixChannelService, private beeper: BeeperService) {

    this.subscription = notificationService.messages$.subscribe(
      messages => { this._notifications = messages; }
    );
  }

  ngAfterViewInit() {
    this.startWebSock();
  }

  @Input() set notifications(value: Message[]) {
    // the p-messages component call this only to clear
    this.notificationService.setMessages([]);
  }

  get notifications(): Message[] {
    return this._notifications;
  }

  startWebSock() {
    this.socket.subscribe('timer:time', 'time', (time) => this.updateTime(time));
    this.socket.subscribe('event:arm', 'arm', (isarmed) => this.updateArmState(isarmed));
    this.socket.subscribe('event:exit_timer', 'start', (ev) => this.startExitTimerEv(ev));
    this.socket.subscribe('event:exit_timer', 'stop', (ev) => this.stopExitTimerEv(ev));
    this.socket.subscribe('event:entry_timer', 'start', (ev) => this.startEntryTimerEv(ev));
    this.socket.subscribe('event:entry_timer', 'stop', (ev) => this.stopEntryTimerEv(ev));
    this.socket.subscribe('event:alarm_events', 'alarm_events', (ev) => this.onAlarmEvents(ev));
  }

  updateArmState(isarmed) {
    if (isarmed.armed) {
      this.isArmed = true;
    } else {
      this.isArmed = false;
    }
  }

  startExitTimerEv(ev) {
    console.log(ev);
    this.beeper.start_beeping();
  };

  stopExitTimerEv(ev) {
    console.log(ev);
    this.beeper.stop_beeping();
  };

  startEntryTimerEv(ev) {
    console.log(ev);
    this.beeper.start_fast_beeping();
  };

  stopEntryTimerEv(ev) {
    console.log(ev);
    this.beeper.stop_beeping();
  };

  onAlarmEvents(ev) {
    if (ev.events > 0) {
      this.unAckedAlarms = true;
      return;
    }
    this.unAckedAlarms = false;
  };

  updateTime(time) {
    let options = {};
    const date = new Date(time.time);

    options = { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' };
    this.date = date.toLocaleString([], options);

    options = { hour: '2-digit', minute: '2-digit', second: '2-digit' };
    this.time = date.toLocaleString([], options);
  }

  logout() {
    this.pinSrv.resetPin();
    this.auth.logout();
  }

  private onChanError(error) {
    console.log('Channel Error', error);
    this.startWebSock();
  }
}
