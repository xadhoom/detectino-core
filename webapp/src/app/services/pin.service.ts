import { Injectable } from '@angular/core';
import { AuthHttp } from 'angular2-jwt';
import { Observable } from 'rxjs/Rx';
import { contentHeaders } from '../shared/utils/headers';

@Injectable()
export class PinService {
  private pin: string;

  constructor(private http: AuthHttp) {
    this.pin = null;
  }

  public setPin(pin: string) {
    let body = JSON.stringify({
      'pin': pin
    });

    return this.http.post('/api/users/check_pin',
      body, { headers: contentHeaders })
      .map(response => {
        this.pin = pin;
      }).catch(this.handleError);

  }

  public getPin(): string {
    return this.pin;
  }

  public resetPin(): void {
    this.pin = null;
  }

  private handleError(error: any) {
    let errTxt = error.text();
    let errMsg = (error.message) ? error.message :
      error.status ? `${error.status} - ${error.statusText}` : 'Server error';
    if (errTxt && errTxt !== error.statusText) {
      errMsg = `${errMsg}: ${error.text()}`;
    }
    return Observable.throw(new Error(errMsg));
  }
}
