import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { Event } from '../models/event';
import { Crud, CrudSettings } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class EventService extends Crud {

  private baseurl = 'api/events';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  all(): Observable<Event[]> {
    return this._read(this.baseurl);
  };

  destroy(s: Event): Observable<Event> {
    return this._destroy(s, this.baseurl);
  }

  save(s: Event): Observable<Event> {
    return this._save(s, this.baseurl);
  };

}
