import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';
import { Observable } from 'rxjs/Rx';

export class Crud {

  constructor(protected http: AuthHttp) {
    this.http = http;
  }

  _read(url: string): Observable<any[]> {
    return this.http.get(url).
      map(this.parseResponse).
      catch(this.handleError);
  };

  _save(obj: any, url: string): Observable<any> {
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

  _destroy(obj: any, url: string): Observable<any> {
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

}
