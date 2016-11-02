import { Component, OnInit, Input } from '@angular/core';

import { SelectItem } from 'primeng/primeng';

import { EventSensorConfig } from '../models/event';

@Component({
  selector: 'dt-eventsensorconfig',
  template: require('./sensorconfig.component.html'),
  styles: [require('./sensorconfig.component.css')]
})

export class SensorConfig implements OnInit {
  @Input() strconfig: string;

  config: EventSensorConfig;

  types: SelectItem[];

  ngOnInit() {
    this.types = [{ label: 'Select a type', value: null }];
    this.types.push({ label: 'Alarm', value: 'alarm' });
    this.types.push({ label: 'Tamper', value: 'tamper' });

    this.config = <EventSensorConfig>JSON.parse(this.strconfig);
    if (!this.config) {
      this.config = new EventSensorConfig();
    }
  };
}

