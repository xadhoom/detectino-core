import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { Sensor } from '../models/sensor';
import { Crud, CrudSettings, PageSortFilter } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class SensorService extends Crud {

  private baseurl = 'api/sensors';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  all(): Observable<Sensor[]> {
    return this._read(this.baseurl);
  };

  destroy(s: Sensor): Observable<Sensor> {
    return this._destroy(s, this.baseurl);
  }

  save(s: Sensor): Observable<Sensor> {
    return this._save(s, this.baseurl);
  };

  getPaged(opts: PageSortFilter): Observable<{ total: number, data: Sensor[] }> {
    const rq_opts = new CrudSettings();
    rq_opts.enablePaging();
    rq_opts.setPage(opts.page);
    rq_opts.setPerPage(opts.per_page);
    rq_opts.setSortField(opts.sort);
    rq_opts.setSortDir(opts.direction);
    rq_opts.setFilters(opts.filters);
    return this._readPaged(this.baseurl, rq_opts);
  };

}
