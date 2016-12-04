import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../services';

@Component({
  selector: 'login',
  template: require('./login.component.html'),
  styles: [require('./login.component.css')]
})

export class Login {
  constructor(public auth: AuthService, private router: Router) {
  }

  login(event: Event, username: string, password: string) {
    event.preventDefault();
    this.auth.login(username, password).
      subscribe(res => {
        if (res) {
          this.router.navigateByUrl('/home');
        } else {
          console.log('ayee cannot log');
        }
      }, error => console.log('ayeee error in log'));
  }
}
