import { Component, OnInit, Input } from '@angular/core';
import { SelectItem } from 'primeng/primeng';
import { EventArmingConfig } from '../../models/event';

@Component({
  selector: 'app-arming-config',
  templateUrl: './arming-config.component.html',
  styleUrls: ['./arming-config.component.scss']
})

export class ArmingConfigComponent implements OnInit {
  @Input() strconfig: string;

  config: EventArmingConfig;

  types: SelectItem[];

  ngOnInit() {
    if (this.strconfig) {
      this.config = <EventArmingConfig>JSON.parse(this.strconfig);
    }
    if (!this.config) {
      this.config = new EventArmingConfig();
    }
  };

  get() {
    return JSON.stringify(this.config);
  };
}


