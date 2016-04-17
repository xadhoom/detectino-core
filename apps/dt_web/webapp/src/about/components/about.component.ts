import {Component} from 'angular2/core';
import {Router} from 'angular2/router';

@Component({
  selector: 'sd-about',
  moduleId: module.id,
  templateUrl: './about.component.html',
  styleUrls: ['./about.component.css']
})
export class AboutComponent {
  constructor(public router: Router) {}

  ngOnInit() {
    console.log('ayee');
    //this.router.parent.navigate(['Home']);
  }

  ngOnDestroy() {
    console.log('destroy about');
  }
}
