import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs/Observable';

import { tokenNotExpired } from 'angular2-jwt';

@Injectable()
export class AuthGuard {
  constructor(private router: Router) {}

  canActivate(): Observable<boolean> {
    let res = false;

    if (tokenNotExpired()) {
      res = true;
    } else {
      this.router.navigate(['home']);
    }

    return Observable.create((observer) => {
      observer.next(res);
      observer.complete();
    });
  }
}
