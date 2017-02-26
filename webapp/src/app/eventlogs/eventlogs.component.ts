import { Component, OnInit } from '@angular/core';
import { Eventlog } from '../models/eventlog';
import { EventlogService, NotificationService, PinService } from '../services';

@Component({
  selector: 'app-eventlogs',
  templateUrl: './eventlogs.component.html',
  styleUrls: ['./eventlogs.component.scss']
})
export class EventlogsComponent implements OnInit {

  eventlog: Eventlog;
  eventlogs: Eventlog[];
  selected: Eventlog;
  displayDialog: boolean;
  new: boolean;
  errorMessage: string;

  constructor(private eventlogService: EventlogService,
    private notificationService: NotificationService,
    public pinSrv: PinService) { };

  ngOnInit() {
    this.eventlogs = [];

    this.pinSrv.observePin().subscribe(
      pin => { this.getLogs(); }
    );
  };

  getLogs() {
    if (!this.pinSrv.getPin()) {
      return;
    }

    this.eventlogService.getLogs().
      subscribe(
      eventlogs => this.eventlogs = eventlogs,
      error => this.onError(error)
      );
  };

  save() {
    this.eventlogService.save(this.eventlog).
      subscribe(
      eventlog => this.refresh(),
      error => this.onError(error)
      );
  };

  destroy() {
    this.eventlogService.destroy(this.eventlog).
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
    this.getLogs();
  };

  onRowSelect(event) {
    this.new = false;
    this.eventlog = this.cloneRecord(event.data);
    this.displayDialog = true;
  };

  cloneRecord(ev: Eventlog): Eventlog {
    const record = new Eventlog();
    for (const prop in ev) {
      if (prop) {
        record[prop] = ev[prop];
      }
    }
    return record;
  }

}
