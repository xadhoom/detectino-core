import {Injectable} from '@angular/core';
import {Http} from '@angular/http';
import {Router} from '@angular/router-deprecated';
import {JwtHelper, tokenNotExpired} from 'angular2-jwt';
import {contentHeaders} from '../shared/utils/headers';
import 'rxjs/add/operator/map';

@Injectable()
export class AuthService {
  jwtHelper: JwtHelper = new JwtHelper();

  constructor(private http: Http, private router: Router) {}

  public authenticated() {
    // Check if there's an unexpired JWT
    return tokenNotExpired();
  }

  public login(username: string, password: string) {
    let body = JSON.stringify({ 'user': {
      'username': username,
      'password': password
    }});

    return this.http.post('/api/login',
                          body, { headers: contentHeaders })
    .map(response => {
      console.log(this.jwtHelper.decodeToken(response.json().token));
      localStorage.setItem('id_token', response.json().token);
      return true;
    });
  }

  public logout() {
    localStorage.removeItem('id_token');
    this.router.navigate(['Home']);
  }
}
