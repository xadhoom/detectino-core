import { Component, OnInit, ViewChild } from '@angular/core';
import { EventService, NotificationService, OutputService } from '../services';
import { Event } from '../models/event';
import { Output } from '../models/output';
import { SensorConfigComponent } from './sensor-config/sensor-config.component';
import { PartitionConfigComponent } from './partition-config/partition-config.component';
import { SelectItem } from 'primeng/primeng';

@Component({
  selector: 'app-events',
  templateUrl: './events.component.html',
  styleUrls: ['./events.component.scss']
})

export class EventsComponent implements OnInit {
  @ViewChild('sensorconfig')
  sensorconfig: SensorConfigComponent;

  @ViewChild('partitionconfig')
  partitionconfig: PartitionConfigComponent;

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
    const aIDs = avail.map(i => i.id);
    const bIDs = used.map(i => i.id);
    return avail.filter(i => bIDs.indexOf(i.id) < 0);
  };

  cloneEvent(s: Event): Event {
    const event = new Event();
    for (const prop in s) {
      if (prop) {
        event[prop] = s[prop];
      }
    }
    return event;
  }

}

