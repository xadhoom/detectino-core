import {
  Http, Response, Request, RequestMethod,
  RequestOptions, Headers
} from '@angular/http';
import { AuthHttp } from 'angular2-jwt';
import { Observable } from 'rxjs/Rx';
import { PinService } from './pin.service';

export class CrudSettings {
  // for future
}

export class Crud {

  constructor(protected http: AuthHttp, protected pinSrv: PinService) { }

  _read(url: string, options?: CrudSettings): Observable<any[]> {
    let rqOpts = this.buildOptions(options);
    return this.http.get(url, rqOpts).
      map(this.parseResponse).
      catch(this.handleError);
  };

  _save(obj: any, url: string, options?: CrudSettings): Observable<any> {
    let rqOpts = this.buildOptions(options);
    let rq = new Request({
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
    let rqOpts = this.buildOptions(options);

    if (!obj.id) {
      return Observable.throw('Missing Object id');
    }

    let rq = new Request({
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
    let body = res.json();
    return body || [];
  };

  protected handleError(error: any) {
    let errTxt = error.text();
    let errMsg = (error.message) ? error.message :
      error.status ? `${error.status} - ${error.statusText}` : 'Server error';
    if (errTxt && errTxt !== error.statusText) {
      errMsg = `${errMsg}: ${error.text()}`;
    }
    return Observable.throw(new Error(errMsg));
  };

  protected buildOptions(options: CrudSettings): RequestOptions {
    let reqOpts = new RequestOptions();

    let pin = this.pinSrv.getPin();
    let headers = new Headers();
    headers.append('Content-Type', 'application/json');
    if (pin) {
      headers.append('p-dt-pin', pin);
    }
    return reqOpts.merge({ headers: headers });
  }

}
