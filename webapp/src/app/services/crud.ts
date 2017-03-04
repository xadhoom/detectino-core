import {
  Http, Response, Request, RequestMethod,
  RequestOptions, Headers, URLSearchParams
} from '@angular/http';
import { AuthHttp } from 'angular2-jwt';
import { Observable } from 'rxjs/Rx';
import { PinService } from './pin.service';

const LinkHeader = require('http-link-header');

export class PageSortFilterArgs {
  page: number;
  per_page: number;
  sort: string;
  direction: string;
}

export class PageSortFilter {
  page: number;
  per_page: number;
  sort: string;
  direction: string;

  constructor({page, per_page, sort, direction}: PageSortFilterArgs) {
    this.page = page;
    this.per_page = per_page;
    this.sort = sort;
    this.direction = direction;
  }
}

export class CrudSettings {
  private page: number;
  private paged: boolean;
  private per_page: number;
  private sort_field: string;
  private sort_direction: string;

  constructor() {
    this.paged = false; this.per_page = 20; this.page = 1;
    this.sort_field = null; this.sort_direction = null;
  }

  // paging helpers
  public enablePaging() { this.paged = true; }

  public setPage(page: number) { this.page = page; }
  public getPage(): number { return this.page; }

  public setPerPage(x: number) { this.per_page = x; }
  public getPerPage(): number { return this.per_page; }

  public isPaged(): boolean { return this.paged; }

  // sorting helpers
  public setSortField(field: string) { this.sort_field = field; }
  public getSortField(): string { return this.sort_field; }

  public setSortDir(dir: string) { this.sort_direction = dir; }
  public getSortDir(): string { return this.sort_direction; }
}

export class Crud {

  protected links: any;

  constructor(protected http: AuthHttp, protected pinSrv: PinService) { }

  _read(url: string, options?: CrudSettings): Observable<any[]> {
    const rqOpts = this.buildOptions();
    return this.http.get(url, rqOpts).
      map(this.parseResponse).
      catch(this.handleError);
  };

  _readPaged(url: string, options?: CrudSettings): Observable<{ total: number, data: any[] }> {
    const rqOpts = this.buildOptions();
    if (!options) {
      options = new CrudSettings();
    }
    const search = this.setSearchUrlParams(options);
    rqOpts.search = search;

    return this.http.get(url, rqOpts).
      map(this.parsePagedResponse).
      catch(this.handleError);
  }

  _save(obj: any, url: string, options?: CrudSettings): Observable<any> {
    const rqOpts = this.buildOptions();
    const rq = new Request({
      url: url,
      method: RequestMethod.Post,
      body: JSON.stringify(obj),
      headers: rqOpts.headers
    });

    if (obj.id) {
      rq.method = RequestMethod.Patch;
      rq.url = rq.url + '/' + obj.id;
    }

    return this.http.request(rq).
      map(this.parseResponse).
      catch(this.handleError);
  };

  _destroy(obj: any, url: string, options?: CrudSettings): Observable<any> {
    const rqOpts = this.buildOptions();

    if (!obj.id) {
      return Observable.throw('Missing Object id');
    }

    const rq = new Request({
      url: url + '/' + obj.id,
      method: RequestMethod.Delete,
      body: '',
      headers: rqOpts.headers
    });

    return this.http.request(rq).
      map(res => []).
      catch(this.handleError);
  }

  protected parseResponse(res: Response) {
    const body = res.json();
    return body || [];
  };

  protected parsePagedResponse(res: Response) {
    const links = res.headers.get('link');
    if (links) {
      this.links = LinkHeader.parse(links);
      // console.log(this.links);
    }
    const body = res.json();
    return { total: 42, data: body || [] };
  };

  protected handleError(error: any) {
    const errTxt = error.text();
    let errMsg = (error.message) ? error.message :
      error.status ? `${error.status} - ${error.statusText}` : 'Server error';
    if (errTxt && errTxt !== error.statusText) {
      errMsg = `${errMsg}: ${error.text()}`;
    }
    return Observable.throw(new Error(errMsg));
  };

  protected buildOptions(): RequestOptions {
    const reqOpts = new RequestOptions();

    const pin = this.pinSrv.getPin();
    const headers = new Headers();
    headers.append('Content-Type', 'application/json');
    if (pin) {
      headers.append('p-dt-pin', pin);
    }
    return reqOpts.merge({ headers: headers });
  }

  protected setSearchUrlParams(options: CrudSettings): URLSearchParams {
    const search = new URLSearchParams();
    if (options.isPaged()) {
      search.set('per_page', String(options.getPerPage()));
      search.set('page', String(options.getPage()));
    }

    const sort_field = options.getSortField();
    if (sort_field) {
      search.set('sort', sort_field);
    }

    const sort_dir = options.getSortDir();
    if (sort_dir) {
      search.set('direction', sort_dir);
    }

    return search;
  }

}
