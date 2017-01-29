import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs/Observable';
import { tokenNotExpired } from 'angular2-jwt';

@Injectable()
export class AuthGuardService {
  constructor(private router: Router) { }

  canActivate(): Observable<boolean> {
    let res = false;

    if (tokenNotExpired()) {
      res = true;
    } else {
      this.router.navigateByUrl('/login');
    }

    return Observable.create((observer) => {
      observer.next(res);
      observer.complete();
    });
  }
}

