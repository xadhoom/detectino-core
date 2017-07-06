import { Injectable } from '@angular/core';

import { Subject } from 'rxjs/Subject';

import { Message } from 'primeng/primeng';

import { UUID } from 'angular2-uuid';

export interface DtMessage {
  id: string;
  severity?: string;
  summary?: string;
  detail?: string;
}

@Injectable()
export class NotificationService {

  private _messages$: Subject<DtMessage[]>;
  private messages: DtMessage[];
  private msgTimeout: number;

  constructor() {
    this.messages = [];
    this._messages$ = <Subject<DtMessage[]>>new Subject();
    this.msgTimeout = 5000;
  }

  get messages$() {
    return this._messages$.asObservable();
  }

  success(body: string) {
    const id = UUID.UUID();
    const msg = {
      id: id,
      severity: 'success', summary: 'Success Message', detail: body
    };
    this.messages.push(msg);
    this._messages$.next(this.messages);
    setTimeout(() => { this.clearMessage(id); }, this.msgTimeout);
  }

  error(body: string) {
    const msg = {
      id: UUID.UUID(),
      severity: 'error', summary: 'Error Message', detail: body
    };
    this.messages.push(msg);
    this._messages$.next(this.messages);
  }

  setMessages(messages: DtMessage[]) {
    this.messages = messages;
    this._messages$.next(this.messages);
  }

  private clearMessage(uuid: any) {
    this.messages = this.messages.filter(msg => {
      return msg.id !== uuid;
    });
    this._messages$.next(this.messages);
  }

}
