import { Injectable } from '@angular/core';

import { Observable } from 'rxjs/Observable';
import { Observer } from 'rxjs/Observer';
import { Subject } from 'rxjs/Subject';

declare var Phoenix: any;

@Injectable()
export class PhoenixChannelService {
  socket: any;
  channel: any;

  private subject: Subject<MessageEvent>;

  constructor() {
    this.socket = new Phoenix.Socket('ws://localhost:4000/socket', {
      // logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data); }),
      transport: WebSocket
    });

    this.socket.connect();
  }

  public run(): Subject<MessageEvent> {
    if (!this.subject) {
      this.subject = this.create();
    }
    return this.subject;
  }

  private create(): Subject<MessageEvent> {
    this.channel = this.socket.channel('event:time', {});
    this.channel.join();

    let observable = Observable.create(
      (obs: Observer<MessageEvent>) => {
        this.channel.on('time', obs.next.bind(obs));
        this.channel.onError(obs.error.bind(obs));
        this.channel.onClose(obs.complete.bind(obs));
      });

    let observer = {
      next: (data: Object) => {
        // this.channel.send(JSON.stringify(data));
        console.log('Will send data:', data);
      },
    };
    return Subject.create(observer, observable);
  }
}
