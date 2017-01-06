import { Injectable } from '@angular/core';
import { AuthHttp } from 'angular2-jwt';
import { Observable, BehaviorSubject } from 'rxjs/Rx';
import { contentHeaders } from '../shared/utils/headers';

@Injectable()
export class PinService {
  private pin: BehaviorSubject<string>;
  private expireTimer: any;
  private expireValue: number;

  constructor(private http: AuthHttp) {
    this.expireTimer = null;
    this.expireValue = 30000;
    this.pin = new BehaviorSubject<string>(null);

    // very ugly, but future self will find a better way
    document.addEventListener('click', () => this.restartExpireTimer());
  }

  public setPin(pin: string) {
    let body = JSON.stringify({
      'pin': pin
    });

    return this.http.post('/api/users/check_pin',
      body, { headers: contentHeaders })
      .map(response => {
        this.startExpireTimer();
        this.pin.next(pin);
      }).catch(this.handleError);

  }

  public observePin(): BehaviorSubject<string> {
    return this.pin;
  }

  public getPin(): string {
    return this.pin.getValue();
  }

  public resetPin(): void {
    this.pin.next(null);
  }

  private startExpireTimer(): void {
    this.expireTimer = setTimeout(() => {
      this.resetPin();
      this.expireTimer = null;
    }, this.expireValue);
  }

  private restartExpireTimer(): void {
    if (this.expireTimer) {
      clearTimeout(this.expireTimer);
      this.startExpireTimer();
    }
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
