import { Injectable } from '@angular/core';

import { Observable } from 'rxjs/Observable';
import { Observer } from 'rxjs/Observer';
import { Subject } from 'rxjs/Subject';

declare var Phoenix: any;

@Injectable()
export class PhoenixChannelService {
  private socket: any;
  private channel: any;

  private subject: Subject<MessageEvent>;

  public disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = undefined;
    }
  }

  public connect(token) {
    if (this.socket && this.socket.isConnected()) { return; }

    this.socket = new Phoenix.Socket('ws://localhost:4000/socket', {
      // logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data); }),
      transport: WebSocket,
      params: { guardian_token: token },
    });
    this.socket.connect();
  }

  public subscribe(topic: string, key: string): Subject<MessageEvent> {
    let observable = Observable.create(
      (obs: Observer<MessageEvent>) => {
        let channel = this.socket.channel(topic + ':' + key, {});
        channel.join();
        channel.on(key, obs.next.bind(obs));
        channel.onError(obs.error.bind(obs));
        channel.onClose(obs.complete.bind(obs));
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
