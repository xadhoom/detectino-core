import { Component } from '@angular/core';

@Component({
  selector: 'home',
  styles: [ require('./home.component.css') ],
  template: require('./home.component.html')
})
export class Home {
  ngOnInit() {
    console.log('hello `Home` component');
  }
}
