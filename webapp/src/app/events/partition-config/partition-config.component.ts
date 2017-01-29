import { Component, OnInit, Input } from '@angular/core';
import { SelectItem } from 'primeng/primeng';
import { EventPartitionConfig } from '../../models/event';

@Component({
  selector: 'app-partition-config',
  templateUrl: './partition-config.component.html',
  styleUrls: ['./partition-config.component.scss']
})

export class PartitionConfigComponent implements OnInit {
  @Input() strconfig: string;

  config: EventPartitionConfig;

  types: SelectItem[];

  ngOnInit() {
    this.types = [{ label: 'Select a type', value: null }];
    this.types.push({ label: 'Alarm', value: 'alarm' });
    this.types.push({ label: 'Tamper', value: 'tamper' });

    if (this.strconfig) {
      this.config = <EventPartitionConfig>JSON.parse(this.strconfig);
    }
    if (!this.config) {
      this.config = new EventPartitionConfig();
    }
  };

  get() {
    return JSON.stringify(this.config);
  };
}


