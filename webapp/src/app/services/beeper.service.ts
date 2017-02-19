import { Injectable } from '@angular/core';

@Injectable()
export class BeeperService {
  private beepers: { [key: string]: any };
  private interval: Number;
  private audioContext: any;

  constructor() {
    this.beepers = {};
    this.interval = 0.5 * 1000;
    this.audioContext = new AudioContext;
  }

  public start_beeping(name: string) {
    if (this.beepers[name]) {
      return; // beeper is already running
    }
    const timer = setInterval(() => this.beep(), this.interval);
    this.beepers[name] = timer;
  }

  public stop_beeping(name: string) {
    const timer = this.beepers[name];
    if (timer) {
      clearInterval(timer);
      this.beepers[name] = null;
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
