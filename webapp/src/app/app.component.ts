import {
  Component, AfterViewInit, ElementRef, Renderer,
  ViewChild
} from '@angular/core';

import { Router } from '@angular/router';
import { Http } from '@angular/http';
import { Observable } from 'rxjs/Observable';
import { Subscription } from 'rxjs/Subscription';

import { Message } from 'primeng/primeng';

import {
  NotificationService, AuthService,
  PhoenixChannelService, PinService
} from './services';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})

export class AppComponent implements AfterViewInit {
  name = 'Detectino';

  subscription: Subscription;

  notifications: Message[] = [];

  public time: string;
  public date: string;

  constructor(private el: ElementRef, public router: Router,
    private auth: AuthService,
    private notificationService: NotificationService,
    public pinSrv: PinService,
    private socket: PhoenixChannelService) {

    this.subscription = notificationService.messages$.subscribe(
      messages => { this.notifications = messages; }
    );
  }

  ngAfterViewInit() {
    this.startWebSock();
  }

  startWebSock() {
    this.socket.subscribe('timer', 'time', (time) => this.updateTime(time));
  }

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
