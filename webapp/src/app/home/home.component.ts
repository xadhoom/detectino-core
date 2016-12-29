import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'home',
  styleUrls: ['./home.component.scss'],
  templateUrl: './home.component.html'
})

export class Home implements OnInit {
  timerEmerg: any;

  constructor(private router: Router) {
    this.timerEmerg = null;
  }

  ngOnInit() { }

  openLink(path: string) {
    this.router.navigateByUrl('/' + path);
  }

  openScenarios() {
    this.openLink('/scenarioslist');
  }

  openSettings() {
    this.openLink('/settings');
  }

  openIntrusion() {
    this.openLink('/intrusion');
  }

  stop_menu(e) {
    e.preventDefault();
    return false;
  }

  start_emerg(e) {
    e.preventDefault();
    e.stopPropagation();
    this.timerEmerg = setTimeout(() => this.run_emerg(), 3000);
  }

  stop_emerg() {
    if (this.timerEmerg) {
      clearTimeout(this.timerEmerg);
      this.timerEmerg = null;
    }
  }

  private run_emerg() {
    this.timerEmerg = null;
    console.log('EMERG!!!!');
  }
}
