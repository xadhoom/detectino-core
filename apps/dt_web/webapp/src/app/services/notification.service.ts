import {Injectable} from '@angular/core';

import {Subject} from 'rxjs/Subject';

import {Message} from 'primeng/primeng';

@Injectable()
export class NotificationService {

  private _messages$: Subject<Message[]>;
  private messages: Message[];

  constructor() {
    this.messages = [];
    this._messages$ = <Subject<Message[]>>new Subject();
    // this._messages$.next(this.messages);
  }

  get messages$() {
    console.log('getting an observable....');
    return this._messages$.asObservable();
  }

  error(body: string) {
    let msg = {severity: 'error', summary: 'Error Message', detail: body};
    console.log(this.messages);
    this.messages.push(msg);
    this._messages$.next(this.messages);
    console.log(this.messages);
  }

}

