import { Injectable } from '@angular/core';

import { Observable } from 'rxjs/Observable';
import { Observer } from 'rxjs/Observer';
import { Subject } from 'rxjs/Subject';

declare var Phoenix: any;

@Injectable()
export class PhoenixChannelService {
  private socket: any;
  private channel: any;
  private feeds: { [key: string]: Array<any> };
  private subject: Subject<MessageEvent>;

  constructor() {
    this.feeds = {};
  }

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
    this.reopen_channels();
  }

  public subscribe(topic: string, key: string, cb: Function) {
    let chankey = topic + ':' + key;
    if (!this.feeds[chankey]) {
      this._subscribe(topic, key, cb);
    } else {
      this.feeds[chankey].push(cb);
    }
  }

  private _subscribe(topic: string, key: string, cb: Function) {
    let chankey = topic + ':' + key;

    this.feeds[chankey] = [];
    this.feeds[chankey].push(cb);

    let channel = this.socket.channel(chankey, {});
    channel.join();
    channel.on(key, (msg) => {
      this.feeds[chankey].forEach((cb) => {
        let ret = cb(msg);
      });
    });
    channel.onError((error) => console.log('Error from channel', error));
    channel.onClose(() => console.log('Channel closed', chankey));
  }

  private reopen_channels() {
    for (let chankey in this.feeds) {
      this.feeds[chankey].forEach((cb) => {
        let topickey = chankey.split(':', 2);
        this._subscribe(topickey[0], topickey[1], cb);
      });
    }
  }
}
