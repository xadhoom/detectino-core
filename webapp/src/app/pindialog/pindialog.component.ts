import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { NotificationService, PinService } from '../services';


@Component({
  selector: 'dt-pindialog',
  styleUrls: ['./pindialog.component.css'],
  templateUrl: './pindialog.component.html'
})

export class Pindialog implements OnInit {
  errorMessage: string;

  private pin: string;
  private pinmsg: string;
  private realpin: string;

  constructor(private router: Router,
    private notificationService: NotificationService,
    private pinSrv: PinService) {
    this.pin = '';
    this.realpin = '';
    this.pinmsg = 'enter pin';
  };

  ngOnInit() { }

  openLink(path: string) {
    this.router.navigateByUrl('/' + path);
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
