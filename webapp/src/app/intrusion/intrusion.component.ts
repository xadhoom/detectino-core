import { Component, OnInit, ViewEncapsulation, Input } from '@angular/core';

import { PartitionService, NotificationService, PinService } from '../services';
import { Partition } from '../models/partition';

@Component({
  selector: 'dt-intrusion',
  styleUrls: ['./intrusion.component.scss'],
  templateUrl: './intrusion.component.html'
})

export class Intrusion implements OnInit {
  partitions: Partition[];
  errorMessage: string;

  constructor(private partitionService: PartitionService,
    private notificationService: NotificationService,
    private pinSrv: PinService) { }

  ngOnInit() {
    this.partitions = [];

    this.pinSrv.observePin().subscribe(
      pin => { this.loadPartitions(pin); }
    );
  }

  getInitials(name: string) {
    return name[0];
  }

  onError(error: any) {
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  }

  private setPartitions(partitions) {
    this.partitions = partitions;
  }

  private loadPartitions(pin) {
    if (!pin) { return; }

    this.partitionService.all().subscribe(
      partitions => this.setPartitions(partitions),
      error => this.onError(error)
    );
  }
}
