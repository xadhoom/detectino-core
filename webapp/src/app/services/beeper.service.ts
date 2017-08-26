import { Injectable } from '@angular/core';

@Injectable()
export class BeeperService {
  private interval: number;
  private audioContext: any;
  private beeping: boolean;
  private timer: any;

  constructor() {
    this.beeping = false;
    this.timer = null;
    this.interval = 0.5 * 1000;
    this.audioContext = new AudioContext;
  }

  public start_beeping() {
    if (this.beeping) {
      this.stop_beeping();
    }
    this.timer = setInterval(() => this.beep(), this.interval);
    this.beeping = true;
  }

  public start_fast_beeping() {
    if (this.beeping) {
      this.stop_beeping();
    }
    const newInterval = this.interval / 2;
    this.timer = setInterval(() => this.beep(), newInterval);
    this.beeping = true;
  }

  public stop_beeping() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      this.beeping = false;
    }
  }

  private beep() {
    const context = this.audioContext;
    const oscillator = context.createOscillator();
    oscillator.frequency.value = 1750;
    oscillator.connect(context.destination);
    oscillator.start(0);
    oscillator.stop(context.currentTime + 0.2);
  }

}
