import { Injectable } from '@angular/core';
import { Http } from '@angular/http';
import { Router } from '@angular/router';
import { JwtHelper, tokenNotExpired, AuthHttp } from 'angular2-jwt';
import { contentHeaders } from '../shared/utils/headers';
import { Observable } from 'rxjs/Observable';
import 'rxjs/add/operator/map';

import { PhoenixChannelService } from './phoenixchannel.service';
import { PinService } from './pin.service';

@Injectable()
export class AuthService {
  jwtHelper: JwtHelper = new JwtHelper();

  channel: Observable<any>;
  private refreshTimer;
  private refreshInt = 60000;

  constructor(private http: Http, private authHttp: AuthHttp,
    private router: Router, private socket: PhoenixChannelService) {

    if (this.authenticated()) {
      let token = localStorage.getItem('id_token');
      this.socket.connect(token);
      this.refreshTimer = setInterval(() => this.refreshToken(),
        this.refreshInt);
    }
  }

  public authenticated() {
    let token = localStorage.getItem('id_token');
    if (!token) {
      return false;
    }
    // Check if there's an unexpired JWT
    let expired = !tokenNotExpired();
    if (expired) {
      this.logout();
      return false;
    }
    return true;
  }

  public login(username: string, password: string) {
    let body = JSON.stringify({
      'user': {
        'username': username,
        'password': password
      }
    });

    return this.http.post('/api/login',
      body, { headers: contentHeaders })
      .map(response => {
        let token = response.json().token;
        localStorage.setItem('id_token', token);

        this.socket.connect(token);

        if (this.refreshTimer) {
          clearInterval(this.refreshTimer);
        }
        this.refreshTimer = setInterval(() => this.refreshToken(),
          this.refreshInt);

        return true;
      });
  }

  public logout() {
    clearInterval(this.refreshTimer);
    this.refreshTimer = null;
    localStorage.removeItem('id_token');
    if (this.socket) {
      this.socket.disconnect();
    }
    this.router.navigateByUrl('/');
    location.reload();
  }

  public refreshToken() {
    return this.authHttp.post('/api/login/refresh',
      {}, { headers: contentHeaders })
      .map(response => {
        let token = response.json().token;
        localStorage.setItem('id_token', token);
      }).subscribe(
      res => { },
      error => this.logout()
      );
  }

}
