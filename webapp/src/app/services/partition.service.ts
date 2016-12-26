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

}
