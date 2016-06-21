import {Component} from '@angular/core';

import {UserService} from '../services';

import {User} from '../models/user';

import {UserForm} from './user.form';

@Component({
    selector: 'users',
    providers: [UserService],
    directives: [UserForm],
    template: require('./users.component.html'),
    styles: [ require('./users.component.css') ]
})

export class Users {

  users: User[];
  userForms: UserForm[] = [];
  errorMessage: string;

  constructor(private userService: UserService) {};

  ngOnInit() { this.getUsers(); };

  addUserForm(userForm: UserForm) {
    this.userForms.push(userForm);
  };

  getUsers() {
    this.userService.getUsers().
      subscribe(
        users => this.users = users,
        error => this.errorMessage = <any>error);
  };

  newUser() {
    this.users.push(new User(0));
  };

}

