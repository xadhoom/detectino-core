import { Component, OnInit, Input } from '@angular/core';
import { SelectItem } from 'primeng/primeng';
import { EventSensorConfig } from '../../models/event';

@Component({
  selector: 'app-sensor-config',
  templateUrl: './sensor-config.component.html',
  styleUrls: ['./sensor-config.component.scss']
})

export class SensorConfigComponent implements OnInit {
  @Input() strconfig: string;

  config: EventSensorConfig;

  types: SelectItem[];

  ngOnInit() {
    this.types = [{ label: 'Select a type', value: null }];
    this.types.push({ label: 'Alarm', value: 'alarm' });
    this.types.push({ label: 'Tamper', value: 'tamper' });

    if (this.strconfig) {
      this.config = <EventSensorConfig>JSON.parse(this.strconfig);
    }
    if (!this.config) {
      this.config = new EventSensorConfig();
    }
  };

  get() {
    return JSON.stringify(this.config);
  };
}

