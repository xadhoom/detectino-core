import { Component, OnInit } from '@angular/core';
import { UserService, NotificationService } from '../services';
import { User } from '../models/user';
import { SelectItem } from 'primeng/primeng';

@Component({
  selector: 'app-users',
  templateUrl: './users.component.html',
  styleUrls: ['./users.component.scss']
})

export class UsersComponent implements OnInit {

  user: User;

  users: User[];
  roles: SelectItem[];

  selectedUser: User;

  displayDialog: boolean;

  newUser: boolean;

  errorMessage: string;

  constructor(private userService: UserService,
    private notificationService: NotificationService) { };

  ngOnInit() {
    this.roles = [];
    this.getUsers();

    this.roles.push({ label: 'Select Role', value: undefined });
    this.roles.push({ label: 'Admin', value: 'admin' });
    this.roles.push({ label: 'User', value: 'user' });
  };

  getUsers() {
    this.userService.getUsers().
      subscribe(
      users => this.users = users,
      error => this.onError(error)
      );
  };

  save() {
    this.userService.save(this.user).
      subscribe(
      user => this.refresh(),
      error => this.onError(error)
      );
  };

  destroy() {
    this.userService.destroy(this.user).
      subscribe(
      success => this.refresh(),
      error => this.onError(error)
      );
  };

  onError(error: any) {
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  };

  refresh() {
    this.displayDialog = false;
    this.getUsers();
  };

  showDialogToAdd() {
    this.newUser = true;
    this.user = new User();
    this.displayDialog = true;
  }

  onRowSelect(event) {
    this.newUser = false;
    this.user = this.cloneUser(event.data);
    this.displayDialog = true;
  };

  cloneUser(u: User): User {
    const user = new User();
    for (const prop in u) {
      if (prop) {
        user[prop] = u[prop];
      }
    }
    return user;
  }

  invalidateSession(obj: User) {
    this.userService.invalidateSession(obj).subscribe(
      res => {
        this.notificationService.success('All Sessions Invalidated!');
      },
      error => this.onError(error)
    );
  }

}
