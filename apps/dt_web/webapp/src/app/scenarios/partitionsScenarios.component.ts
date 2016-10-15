import { Component, OnInit, Input } from '@angular/core';

import { PartitionScenarioService, PartitionService, NotificationService } from '../services';

import { PartitionScenario } from '../models/partitionScenario';

import { SelectItem } from 'primeng/primeng';

import { Observable } from 'rxjs/Rx';


@Component({
    selector: 'dt-partitionsscenarios',
    template: require('./partitionsScenarios.component.html'),
    styles: [ require('./partitionsScenarios.component.css') ]
})

export class PartitionsScenarios implements OnInit {
  @Input() scenarioid: number;

  items: PartitionScenario[];

  modes: SelectItem[];
  partitions: SelectItem[];

  errorMessage: string;

  constructor(private service: PartitionScenarioService,
              private partitionService: PartitionService,
              private notificationService: NotificationService) {};

  ngOnInit() {
    this.modes = [{label: 'Select a mode', value: null}];
    this.modes.push({label: 'Arm', value: 'ARM'});
    this.modes.push({label: 'Stay Arm', value: 'ARMSTAY'});
    this.modes.push({label: 'Immediate Stay', value: 'ARMSTAYIMMEDIATE'});
    this.modes.push({label: 'DISARM', value: 'DISARM'});
    this.modes.push({label: 'None', value: 'NONE'});

    this.partitions = [{label: 'Select a partition', value: null}];
    this.partitionService.all().
      subscribe(
        items => {
          for (let item of items) {
            this.partitions.push({label: item.name, value: item.id});
          }
        },
        error => this.onError(error)
    );

    this.all(this.scenarioid);
  };

  onPartitionChange(ev, idx) {
    this.items[idx].partition_id = ev.value;
  }

  onModeChange(ev, idx) {
    this.items[idx].mode = ev.value;
  }

  all(id) {
    this.service.all(id).
      subscribe(
        items => this.items = items,
        error => this.onError(error)
    );
  };

  saveAll() {
    let s: Observable<any> = null;
    for (let item of this.items) {
      if (!item.mode || !item.partition_id) {
        continue;
      }
      if (s) {
        s = Observable.concat(s, this.service.save(this.scenarioid, item));
      } else {
        s = this.service.save(this.scenarioid, item);
      }
    }
    return s;
  };

  destroy(idx) {
    let item = this.items[idx];
    if (!item.id) {
      this.items.splice(idx, 1);
      return;
    }
    this.service.destroy(this.scenarioid, this.items[idx]).
      subscribe(
        success => this.refresh(),
        error => this.onError(error)
    );
  };

  onError(error: any) {
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  };

  refresh() {
    this.all(this.scenarioid);
  };

  addPartitionScenario() {
    this.items.push(new PartitionScenario(this.scenarioid));
  }

}
