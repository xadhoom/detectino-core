import { Component, OnInit } from '@angular/core';
import { Eventlog } from '../models/eventlog';
import { PageSortFilter } from '../services/crud';
import { EventlogService, NotificationService, PinService } from '../services';
import { LazyGrid } from '../shared/components/lazy_grid';

@Component({
  selector: 'app-eventlogs',
  templateUrl: './eventlogs.component.html',
  styleUrls: ['./eventlogs.component.scss']
})
export class EventlogsComponent implements OnInit {

  eventlog: Eventlog;
  eventlogs: Eventlog[];
  eventlogDetails: Iterable<Object>;
  selected: Eventlog;
  displayDialog: boolean;
  new: boolean;
  errorMessage: string;

  // pagination & sort stuff
  public lazyGrid: LazyGrid;

  constructor(private eventlogService: EventlogService,
    private notificationService: NotificationService,
    public pinSrv: PinService) {

    this.lazyGrid = new LazyGrid(() => this.getLogs());
  };

  ngOnInit() {
    this.eventlogs = [];

    this.pinSrv.observePin().subscribe(
      pin => { this.getLogs(); }
    );
  };

  public getLogs() {
    if (!this.pinSrv.getPin()) {
      return;
    }
    const opts = this.lazyGrid.getSortPage();
    if (!opts.sort) {
      opts.sort = 'inserted_at';
      opts.direction = 'desc';
    }

    this.eventlogService.getLogsPaged(opts).
      subscribe(
      res => { this.eventlogs = res.data; this.lazyGrid.setTotalRecords(res.total); },
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
    this.eventlogDetails = this.getDetails(this.eventlog);
    this.displayDialog = true;
    // console.log(this.eventlog);
  };

  public ackEvent(e: Eventlog) {
    const runOp = this.eventlogService.ack(e);
    runOp.subscribe(
      res => {
        this.notificationService.success('Event log acked!');
        this.refresh();
      },
      error => this.onError(error)
    );
  };

  public ackAllEvents() {
    const runOp = this.eventlogService.ackAll();
    runOp.subscribe(
      res => {
        this.notificationService.success('All events acked!');
        this.refresh();
      },
      error => this.onError(error)
    );
  };

  public toolTip(eventlog: Eventlog) {
    const header = [];
    const head = eventlog.details.source + ' ' + eventlog.operation;
    header.push(head);
    const fields = this.getDetails(eventlog) as Array<{ detail: string, value: string }>;
    const res = fields.map(field => {
      const entry = field.detail + ':' + field.value;
      return entry;
    });
    return header.concat(res).join('<br/>');
  }

  private getDetails(eventlog: Eventlog): Iterable<Object> {
    const res = [];
    for (const detail in eventlog.details.ev) {
      if (eventlog.details.ev.hasOwnProperty(detail)) {
        res.push({ detail: detail, value: eventlog.details.ev[detail] });
      }
    }
    return res;
  }

  private cloneRecord(ev: Eventlog): Eventlog {
    const record = new Eventlog();
    for (const prop in ev) {
      if (prop) {
        record[prop] = ev[prop];
      }
    }
    return record;
  }

}
