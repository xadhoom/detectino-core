import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { Scenario } from '../models/scenario';
import { Crud } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class ScenarioService extends Crud {

  private baseurl = 'api/scenarios';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  all(): Observable<Scenario[]> {
    return this._read(this.baseurl);
  };

  get_available(): Observable<Scenario[]> {
    const url = this.baseurl + '/get_available';
    return this.http.get(url).
      map(this.parseResponse).
      catch(this.handleError);
  }

  destroy(s: Scenario): Observable<Scenario> {
    return this._destroy(s, this.baseurl);
  }

  save(s: Scenario): Observable<Scenario> {
    return this._save(s, this.baseurl);
  }

  public run(s: Scenario): Observable<boolean> {
    const rqOpts = this.buildOptions();
    const url = this.baseurl + '/' + s.id + '/run';
    return this.http.post(url, null, rqOpts).
      map((res) => {
        return true;
      }).
      catch(this.handleRunError);
  }

  private handleRunError(error: any) {
    if (error.status === 555) {
      const errMsg = 'Some Partition is tripped, cannot arm!';
      return Observable.throw(new Error(errMsg));
    } else {
      return this.handleError(error);
    }
  };

}
