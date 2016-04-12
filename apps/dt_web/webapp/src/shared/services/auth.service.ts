import {Injectable} from 'angular2/core';
import {Http} from 'angular2/http';
import {JwtHelper} from 'angular2-jwt';
import 'rxjs/add/operator/map';
import {contentHeaders} from '../../shared/utils/headers';

@Injectable()
export class AuthService {
  jwtHelper: JwtHelper = new JwtHelper();

  constructor(public http: Http) {}

  login(username: string, password: string) {
    let body = JSON.stringify({ 'user': {
      'username': username,
      'password': password
      }
    });
    return this.http.post('/api/login',
                          body, { headers: contentHeaders })
    .map(response => {
      console.log(this.jwtHelper.decodeToken(response.json().token));
      localStorage.setItem('jwt', response.json().token);
      return true;
    });
  }
}

