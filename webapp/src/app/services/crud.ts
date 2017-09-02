import {
  Http, Response, Request, RequestMethod,
  RequestOptions, Headers, URLSearchParams
} from '@angular/http';
import { AuthHttp } from 'angular2-jwt';
import { Observable } from 'rxjs/Rx';
import { PinService } from './pin.service';

const LinkHeader = require('http-link-header');

export class Filter {
  key: string;
  value: string;
  mode: string;
  constructor({ key, value, mode }) {
    this.key = key;
    this.value = value;
    this.mode = mode;
  }
}

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
  filters: Filter[];

  constructor({ page, per_page, sort, direction }: PageSortFilterArgs) {
    this.page = page;
    this.per_page = per_page;
    this.sort = sort;
    this.direction = direction;
    this.filters = [];
  }

  public addFilter(k, v, mode): Filter[] {
    const filter = new Filter({ 'key': k, 'value': v, 'mode': mode });
    if (this.filters.indexOf(filter) < 0) {
      this.filters.push(filter);
    }
    return this.filters;
  }
  public clearFilters(): void { this.filters = []; };
  public getFilters(): Filter[] { return this.filters; }
}

export class CrudSettings {
  private page: number;
  private paged: boolean;
  private per_page: number;
  private sort_field: string;
  private sort_direction: string;
  private filters: Filter[];

  constructor() {
    this.paged = false; this.per_page = 20; this.page = 1;
    this.sort_field = null; this.sort_direction = null;
    this.filters = [];
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

  // simple filter helpers
  public setFilters(filters: Filter[]) { this.filters = filters; }
  public getFilters(): Filter[] { return this.filters; }
}

export class Crud {

  protected links: any;

  constructor(protected http: AuthHttp, protected pinSrv: PinService) { }

  _read(url: string, options?: CrudSettings): Observable<any[]> {
    const rqOpts = this.buildOptions();
    return this.http.get(url, rqOpts).
      map(val => this.parseResponse(val)).
      catch(err => this.handleError(err));
  };

  _readPaged(url: string, options?: CrudSettings): Observable<{ total: number, data: any[] }> {
    const rqOpts = this.buildOptions();
    if (!options) {
      options = new CrudSettings();
    }
    const search = this.setSearchUrlParams(options);
    rqOpts.search = search;

    return this.http.get(url, rqOpts).
      map(val => this.parsePagedResponse(val)).
      catch(err => this.handleError(err));
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
      map(val => this.parseResponse(val)).
      catch(err => this.handleError(err));
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
      catch(err => this.handleError(err));
  }

  protected parseResponse(res: Response) {
    const body = res.json();
    return body || [];
  };

  protected parsePagedResponse(res: Response) {
    const links = res.headers.get('link');
    if (links) {
      this.links = LinkHeader.parse(links);
    }
    const body = res.json();
    const total = this.getTotal(this.links);
    return { total: total, data: body || [] };
  };

  protected getTotal(links): number {
    let total = 0;
    for (let i = 0; i < links.refs.length; i++) {
      const ref = links.refs[i];
      if (ref.rel !== 'self') { continue; }
      total = ref.total;
    }
    return total;
  };

  protected handleError(error: any) {
    console.warn(error);

    const errTxt = error.text;
    const errMsg = (error.message) ? error.message :
      error.status ? `${error.status} - ${error.statusText}` : 'Server error';
    // if (errTxt && errTxt !== error.statusText) {
    //   errMsg = `${errMsg}`;
    // }
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
    let search = new URLSearchParams();
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

    const filters = options.getFilters();
    for (let i = 0; i < filters.length; i++) {
      const filter = filters[i];
      search = this.filter_with_guards(search, filter);
    }

    return search;
  }

  protected filter_with_guards(search: URLSearchParams, filter: Filter): URLSearchParams {
    const reserved = ['page', 'per_page', 'sort', 'direction'];
    const needle = filter.key;
    if (reserved.indexOf(needle) >= 0) {
      return search;
    }

    search.set(needle, filter.value);
    search.set(needle + 'MatchMode', this.getMatchMode(filter.mode));
    return search;
  }

  private getMatchMode(matchmode: string): string {
    /*
      Valid match modes:
      "startsWith", "contains", "endsWith", "equals" and "in" (from primeNG)
      will be translated to: starts, contains, ends, equals and in
    */
    if (matchmode === 'startsWith') {
      return 'starts';
    } else if (matchmode === 'endsWith') {
      return 'ends';
    } else if (matchmode === 'contains') {
      return 'contains';
    } else if (matchmode === 'equals') {
      return 'equals';
    } else if (matchmode === 'in') {
      return 'in';
    } else {
      return 'starts';
    }
  }

}
