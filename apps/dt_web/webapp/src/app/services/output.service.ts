import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { Output } from '../models/output';
import { Crud } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class OutputService extends Crud {

  private baseurl = 'api/outputs';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  all(): Observable<Output[]> {
    return this._read(this.baseurl);
  };

  destroy(s: Output): Observable<Output> {
    return this._destroy(s, this.baseurl);
  }

  save(s: Output): Observable<Output> {
    return this._save(s, this.baseurl);
  };

}

