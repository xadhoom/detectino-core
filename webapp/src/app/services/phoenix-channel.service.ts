import { Injectable } from '@angular/core';

import { Observable } from 'rxjs/Observable';
import { Observer } from 'rxjs/Observer';
import { Subject } from 'rxjs/Subject';

declare var Phoenix: any;

@Injectable()
export class PhoenixChannelService {
  private socket: any;
  private channels: { [key: string]: any };
  private feeds: { [key: string]: Array<any> };
  private subject: Subject<MessageEvent>;

  constructor() {
    this.feeds = {};
    this.channels = {};
  }

  public disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = undefined;
    }
  }

  public connect(token) {
    if (this.socket && this.socket.isConnected()) { return; }

    this.socket = new Phoenix.Socket(this.getUrl() + '/socket', {
      // logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data); }),
      transport: WebSocket,
      params: { guardian_token: token },
    });
    this.socket.connect();
    this.reopen_channels();
  }

  public subscribe(topic: string, event: string, cb: Function) {
    const chankey = topic + ':' + event;
    if (!this.feeds[chankey]) {
      this._subscribe(topic, event, cb);
    } else {
      this.feeds[chankey].push(cb);
    }
  }

  private getUrl(): string {
    const proto = location.protocol.match(/^https/) ? 'wss://' : 'ws://';
    const host = location.host;
    return proto + host;
  }

  private _subscribe(topic: string, event: string, cb: Function) {
    const chankey = topic + ':' + event;

    this.feeds[chankey] = [];
    this.feeds[chankey].push(cb);

    if (!this.socket) {
      // delay channel creation, will get recreated on connect via refresh
      return;
    }

    let channel = this.channels[topic];
    if (!channel) {
      channel = this.socket.channel(topic, {});
      channel.join();
      this.channels[topic] = channel;
    }
    channel.on(event, (msg) => {
      this.feeds[chankey].forEach((callback) => {
        const ret = callback(msg);
      });
    });

    channel.onError((error) => console.log('Error from channel', error));
    channel.onClose(() => console.log('Channel closed', chankey));
  }

  private reopen_channels() {
    for (const chankey in this.feeds) {
      if (this.feeds.hasOwnProperty(chankey)) {
        this.feeds[chankey].forEach((cb) => {
          const topic_event = chankey.split(':', 3);
          const topic = topic_event[0] + ':' + topic_event[1];
          this._subscribe(topic, topic_event[2], cb);
        });
      }
    }
  }
}
