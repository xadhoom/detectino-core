import { Injectable } from '@angular/core';
import { Observable } from 'rxjs/Observable';
import { AuthHttp } from 'angular2-jwt';
import { Eventlog } from '../models/eventlog';
import { Crud, CrudSettings, PageSortFilter } from './crud';
import { PinService } from './pin.service';

@Injectable()
export class EventlogService extends Crud {

  private baseurl = 'api/eventlogs';

  constructor(protected http: AuthHttp, protected pinSrv: PinService) {
    super(http, pinSrv);
  }

  getLogsPaged(opts: PageSortFilter): Observable<{ total: number, data: Eventlog[] }> {
    const rq_opts = new CrudSettings();
    rq_opts.enablePaging();
    rq_opts.setPage(opts.page);
    rq_opts.setPerPage(opts.per_page);
    rq_opts.setSortField(opts.sort);
    rq_opts.setSortDir(opts.direction);
    rq_opts.setFilters(opts.filters);
    return this._readPaged(this.baseurl, rq_opts);
  };

  destroy(ev: Eventlog): Observable<Eventlog> {
    return this._destroy(ev, this.baseurl);
  }

  save(ev: Eventlog): Observable<Eventlog> {
    return this._save(ev, this.baseurl);
  };

  ack(ev: Eventlog): Observable<boolean> {
    const rqOpts = this.buildOptions();
    const url = this.baseurl + '/' + ev.id + '/ack';
    return this.http.post(url, null, rqOpts).
      map((res) => {
        return true;
      }).
      catch(this.handleError);
  }

  ackAll(): Observable<boolean> {
    const rqOpts = this.buildOptions();
    const url = this.baseurl + '/ackall';
    return this.http.post(url, null, rqOpts).
      map((res) => {
        return true;
      }).
      catch(this.handleError);
  }

}
