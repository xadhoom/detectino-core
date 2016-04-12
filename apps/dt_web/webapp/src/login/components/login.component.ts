import {Component} from 'angular2/core';
import {Router} from 'angular2/router';
import {AuthService} from '../../shared/services/auth.service';

@Component({
  selector: 'login',
  moduleId: module.id,
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
  providers: [AuthService]
})

export class LoginComponent {
  constructor(public router: Router, public auth: AuthService) {
  }

  login(event: Event, username: string, password: string) {
    event.preventDefault();
    this.auth.login(username, password).
      subscribe( res => {
      if(res) {
        this.router.parent.navigate(['Home']);
      } else {
        console.log('ayee cannot log');
      }
    }, error => console.log('ayeee error in log'));
  }
}
