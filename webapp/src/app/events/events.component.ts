import { Component, OnInit, ViewChild } from '@angular/core';

import { EventService, NotificationService, OutputService } from '../services';

import { Event } from '../models/event';
import { Output } from '../models/output';
import { SensorConfig } from './sensorconfig.component';
import { PartitionConfig } from './partitionconfig.component';

import { SelectItem } from 'primeng/primeng';

@Component({
  selector: 'events',
  templateUrl: './events.component.html',
  styleUrls: ['./events.component.css', '../shared/common.scss']
})

export class Events implements OnInit {
  @ViewChild('sensorconfig')
  sensorconfig: SensorConfig;

  @ViewChild('partitionconfig')
  partitionconfig: PartitionConfig;

  event: Event;

  events: Event[];
  sources: SelectItem[];

  selectedEvent: Event;

  selectedOutputs: Output[];
  outputs: Output[];

  displayDialog: boolean;
  showSensorConfig: boolean;
  showPartitionConfig: boolean;

  newEvent: boolean;

  errorMessage: string;

  constructor(private eventService: EventService,
    private outputService: OutputService,
    private notificationService: NotificationService) { };

  ngOnInit() {
    this.sources = [{ label: 'Select a source', value: null }];
    this.sources.push({ label: 'Sensor', value: 'sensor' });
    this.sources.push({ label: 'Partition', value: 'partition' });
    this.all();
  };

  allOutputs() {
    this.outputService.all().
      subscribe(
      items => this.outputs = items,
      error => this.onError(error)
      );
  };

  all() {
    this.outputs = [];
    this.selectedOutputs = [];
    this.allOutputs();

    this.eventService.all().
      subscribe(
      events => this.events = events,
      error => this.onError(error)
      );
  };

  save() {
    if (this.event.source === 'sensor') {
      this.event.source_config = this.sensorconfig.get();
    } else if (this.event.source === 'partition') {
      this.event.source_config = this.partitionconfig.get();
    } else {
      this.event.source_config = null;
    }
    this.event.outputs = this.selectedOutputs;
    this.eventService.save(this.event).
      subscribe(
      event => this.refresh(),
      error => this.onError(error)
      );
  };

  destroy() {
    this.eventService.destroy(this.event).
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
    this.displayDialog = false;
    this.all();
  };

  showDialogToAdd() {
    this.newEvent = true;
    this.event = new Event();
    this.displayDialog = true;
  }

  onRowSelect(event) {
    this.newEvent = false;
    this.event = this.cloneEvent(event.data);
    this.selectedOutputs = this.event.outputs;
    this.outputs = this.availOutputs(this.outputs, this.selectedOutputs);
    this.displayDialog = true;
  };

  availOutputs(avail: Array<any>, used: Array<any>): Array<any> {
    let aIDs = avail.map(i => i.id);
    let bIDs = used.map(i => i.id);
    return avail.filter(i => bIDs.indexOf(i.id) < 0);
  };

  cloneEvent(s: Event): Event {
    let event = new Event();
    for (let prop in s) {
      if (prop) {
        event[prop] = s[prop];
      }
    }
    return event;
  }

}

