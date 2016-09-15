import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { Scenario } from '../models/scenario';
import { Crud } from './crud';

@Injectable()
export class ScenarioService extends Crud {

  private baseurl = 'api/scenarios';

  constructor(protected http: AuthHttp) {
    super(http);
  }

  all(): Observable<Scenario[]> {
    return this._read(this.baseurl);
  };

  destroy(s: Scenario): Observable<Scenario> {
    return this._destroy(s, this.baseurl);
  }

  save(s: Scenario): Observable<Scenario> {
    return this._save(s, this.baseurl);
  };

}

