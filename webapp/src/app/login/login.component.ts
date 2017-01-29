import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../services';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})

export class LoginComponent implements OnInit {
  constructor(public auth: AuthService, private router: Router) {
  }

  ngOnInit() {
    if (this.auth.authenticated()) {
      this.router.navigateByUrl('/home');
    }
  }

  login(event: Event, username: string, password: string) {
    event.preventDefault();
    this.auth.login(username, password).
      subscribe(res => {
        if (res) {
          this.router.navigateByUrl('/home');
        } else {
          console.log('ayee cannot login');
        }
      }, error => console.log('ayeee error in login:', error));
  }
}

