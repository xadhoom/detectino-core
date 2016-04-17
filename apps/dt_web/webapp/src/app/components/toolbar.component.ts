import {Component} from 'angular2/core';
import {ROUTER_DIRECTIVES} from 'angular2/router';
import {MATERIAL_DIRECTIVES, Media, SidenavService} from 'ng2-material/all';

@Component({
  selector: 'md-toolbar',
  moduleId: module.id,
  templateUrl: './toolbar.component.html',
  styleUrls: ['./toolbar.component.css'],
  directives: [MATERIAL_DIRECTIVES, ROUTER_DIRECTIVES],
  providers: [SidenavService, Media]
})
export class ToolbarComponent {
  constructor(public sidenav: SidenavService,
             public media: Media) {}

  hasMedia(breakSize: string): boolean {
    return this.media.hasMedia(breakSize);
  }

  m_open() {
    this.sidenav.show('right');
  }

  m_close() {
    this.sidenav.hide('right');
  }
}
