import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { User } from '../models/user';
import { Crud } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class UserService extends Crud {

  private baseurl = 'api/users';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  getUsers(): Observable<User[]> {
    return this._read(this.baseurl);
  };

  destroy(u: User): Observable<User> {
    return this._destroy(u, this.baseurl);
  }

  save(u: User): Observable<User> {
    return this._save(u, this.baseurl);
  };

  invalidateSession(obj: User): Observable<boolean> {
    let rqOpts = this.buildOptions({});

    let rq = new Request({
      url: this.baseurl + '/' + obj.id + '/invalidate',
      method: RequestMethod.Post,
      headers: rqOpts.headers,
      body: ''
    });

    return this.http.request(rq).
      map(res => {
        return true;
      }).
      catch(this.handleError);
  }

}

