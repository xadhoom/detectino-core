import {
  Http, Response, Request, RequestMethod,
  RequestOptions, Headers
} from '@angular/http';
import { AuthHttp } from 'angular2-jwt';
import { Observable } from 'rxjs/Rx';
import { PinService } from './pin.service';

export class CrudSettings { }

export class Crud {

  constructor(protected http: AuthHttp, protected pinSrv: PinService) { }

  _read(url: string, options?: CrudSettings): Observable<any[]> {
    // let rqOpts = this.buildOptions(options);
    return this.http.get(url).
      map(this.parseResponse).
      catch(this.handleError);
  };

  _save(obj: any, url: string, options?: CrudSettings): Observable<any> {
    let rq = new Request({
      url: url,
      method: RequestMethod.Post,
      body: JSON.stringify(obj),
      headers: new Headers({
        'Content-Type': 'application/json'
      })
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
    console.log('deleting id ' + obj.id);

    if (!obj.id) {
      return Observable.throw('Missing Object id');
    }

    let rq = new Request({
      url: url + '/' + obj.id,
      method: RequestMethod.Delete,
      body: '',
      headers: new Headers({
        'Content-Type': 'application/json'
      })
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

  private buildOptions(options: CrudSettings): RequestOptions {
    if (!options) {
      return new RequestOptions();
    }

    let pin = this.pinSrv.getPin();
    let headers = new Headers();
    if (pin) {
      headers.append('p-dt-pin', pin);
    }
    return new RequestOptions({ headers: headers });
  }

}
