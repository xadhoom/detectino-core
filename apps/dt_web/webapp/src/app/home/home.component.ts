import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'home',
  styleUrls: ['./home.component.css'],
  templateUrl: './home.component.html'
})

export class Home implements OnInit {
  constructor(private router: Router) { }

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
}
