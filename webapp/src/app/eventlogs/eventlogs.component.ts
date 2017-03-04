import { Component, OnInit } from '@angular/core';
import { Eventlog } from '../models/eventlog';
import { PageSortFilter } from '../services/crud';
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

  // pagination & sort stuff
  public sortPage: PageSortFilter;
  public totalRecords: number;

  constructor(private eventlogService: EventlogService,
    private notificationService: NotificationService,
    public pinSrv: PinService) {
    this.sortPage = new PageSortFilter({
      page: 1, per_page: 10, sort: null, direction: null
    });
    this.totalRecords = 0;
  };

  ngOnInit() {
    this.eventlogs = [];

    this.pinSrv.observePin().subscribe(
      pin => { this.getLogs(); }
    );
  };

  public getSorted(event) {
    //console.log('sort ev:', event);
    this.sortPage.sort = event.field;
    if (event.order > 0) {
      this.sortPage.direction = "asc"
    } else {
      this.sortPage.direction = "desc"
    }

    return this.getLogs();
  }

  public getPaged(event) {
    //console.log('page ev:', event);
    this.sortPage.page = event.page + 1; // primeng index is 0 based
    this.sortPage.per_page = event.rows;
    return this.getLogs();
  }

  public getLogs() {
    if (!this.pinSrv.getPin()) {
      return;
    }

    this.eventlogService.getLogsPaged(this.sortPage).
      subscribe(
      res => {
        this.eventlogs = res.data; this.totalRecords = res.total;
      },
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
