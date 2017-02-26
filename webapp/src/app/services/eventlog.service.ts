import { Injectable } from '@angular/core';
import { Observable } from 'rxjs/Observable';
import { AuthHttp } from 'angular2-jwt';
import { Eventlog } from '../models/eventlog';
import { Crud } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class EventlogService extends Crud {

  private baseurl = 'api/eventlogs';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  getLogs(): Observable<Eventlog[]> {
    return this._read(this.baseurl);
  };

  destroy(ev: Eventlog): Observable<Eventlog> {
    return this._destroy(ev, this.baseurl);
  }

  save(ev: Eventlog): Observable<Eventlog> {
    return this._save(ev, this.baseurl);
  };

}
