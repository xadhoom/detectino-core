import {Component} from '@angular/core';
import {CanActivate} from '@angular/router-deprecated';
import {tokenNotExpired} from 'angular2-jwt';

import {UserService} from '../services';

import {User} from '../models/user';

@Component({
    selector: 'users',
    providers: [UserService],
    template: require('./users.component.html'),
    styles: [ require('./users.component.css') ]
})

@CanActivate(() => tokenNotExpired())

export class Users {

  users: User[];
  errorMessage: string;

  constructor(private userService: UserService) {};

  ngOnInit() { this.getUsers(); };

  getUsers() {
    this.userService.getUsers().
      subscribe(
        users => this.users = users,
        error => this.errorMessage = <any>error);
  };
}

