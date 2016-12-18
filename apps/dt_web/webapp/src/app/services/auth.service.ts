import { Injectable } from '@angular/core';
import { Http } from '@angular/http';
import { Router } from '@angular/router';
import { JwtHelper, tokenNotExpired } from 'angular2-jwt';
import { contentHeaders } from '../shared/utils/headers';
import { Observable } from 'rxjs/Observable';
import 'rxjs/add/operator/map';

import { PhoenixChannelService } from './phoenixchannel.service';
import { PinService } from './pin.service';

@Injectable()
export class AuthService {
  jwtHelper: JwtHelper = new JwtHelper();

  channel: Observable<any>;

  constructor(private http: Http, private router: Router,
    private socket: PhoenixChannelService) {
    if (this.authenticated()) {
      let token = localStorage.getItem('id_token');
      this.socket.connect(token);
    }
  }

  public authenticated() {
    // Check if there's an unexpired JWT
    let expired = !tokenNotExpired();
    if (expired) {
      this.router.navigateByUrl('/');
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
        console.log(this.jwtHelper.decodeToken(token));
        localStorage.setItem('id_token', token);
        this.socket.connect(token);
        return true;
      });
  }

  public logout() {
    localStorage.removeItem('id_token');
    this.socket.disconnect();
    this.router.navigateByUrl('/');
  }

}
