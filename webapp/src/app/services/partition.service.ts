import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { Partition } from '../models/partition';
import { Crud } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class PartitionService extends Crud {

  private baseurl = 'api/partitions';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  all(): Observable<Partition[]> {
    return this._read(this.baseurl);
  };

  destroy(s: Partition): Observable<Partition> {
    return this._destroy(s, this.baseurl);
  }

  save(s: Partition): Observable<Partition> {
    return this._save(s, this.baseurl);
  };

  public arm(p: Partition, mode: string): Observable<boolean> {
    const rqOpts = this.buildOptions();
    const url = this.baseurl + '/' + p.id + '/arm';
    return this.http.post(url, { mode: mode }, rqOpts).
      map((res) => {
        return true;
      }).
      catch(this.handleArmError);
  }

  public disarm(p: Partition): Observable<boolean> {
    const rqOpts = this.buildOptions();
    const url = this.baseurl + '/' + p.id + '/disarm';
    return this.http.post(url, null, rqOpts).
      map((res) => {
        return true;
      }).
      catch(this.handleError);
  }

  private handleArmError(error: any) {
    let errMsg;
    const errTxt = error.text;
    if (error.status != 555) {
      errMsg = (error.message) ? error.message :
        error.status ? `${error.status} - ${error.statusText}` : 'Server error';
      if (errTxt && errTxt !== error.statusText) {
        errMsg = `${errMsg}: ${error.text}`;
      }
    } else {
      errMsg = "Partition is tripped, cannot arm!";
    }
    return Observable.throw(new Error(errMsg));
  };

}
