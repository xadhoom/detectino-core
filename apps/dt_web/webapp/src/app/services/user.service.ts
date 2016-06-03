import {Injectable} from '@angular/core';
import {Http, Response} from '@angular/http';
import {AuthHttp} from 'angular2-jwt';

import {Observable}     from 'rxjs/Observable';

import {User} from '../models/user';

@Injectable()
export class UserService {

  private url = 'api/users';

  constructor (private http: AuthHttp) {}

  getUsers(): Observable<User[]> {
    return this.http.get(this.url).
      map(this.parseResponse).
      catch(this.handleError);
  };

  private parseResponse(res: Response) {
    let body = res.json();
    return body || [];
  };

  private handleError(error: any) {
    let errMsg = (error.message) ? error.message :
      error.status ? `${error.status} - ${error.statusText}` : 'Server error';
    console.error(errMsg);
    return Observable.throw(errMsg);
  };

}

