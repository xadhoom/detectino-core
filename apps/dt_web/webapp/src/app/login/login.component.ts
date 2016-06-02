import {Component} from '@angular/core';
import {Router} from '@angular/router-deprecated';
import {AuthService} from '../auth/auth.service';

@Component({
  selector: 'login',
  moduleId: module.id,
  template: require('./login.template.html'),
  providers: [AuthService]
})

export class Login {
  constructor(public router: Router, public auth: AuthService) {
  }

  login(event: Event, username: string, password: string) {
    event.preventDefault();
    this.auth.login(username, password).
      subscribe( res => {
      if (res) {
        // this.router.parent.navigate(['Home']);
      } else {
        console.log('ayee cannot log');
      }
    }, error => console.log('ayeee error in log'));
  }
}
