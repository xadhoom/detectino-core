import { Component, OnInit } from '@angular/core';

import { PartitionService, NotificationService } from '../services';

import { Partition } from '../models/partition';

import { SelectItem } from 'primeng/primeng';

@Component({
  selector: 'partitions',
  templateUrl: './partitions.component.html',
  styleUrls: ['./partitions.component.css', '../shared/common.scss']
})

export class Partitions implements OnInit {

  partition: Partition;

  partitions: Partition[];

  selectedPartition: Partition;

  displayDialog: boolean;

  newPartition: boolean;

  errorMessage: string;

  constructor(private partitionService: PartitionService,
    private notificationService: NotificationService) { };

  ngOnInit() {
    this.all();
  };

  all() {
    this.partitionService.all().
      subscribe(
      partitions => this.partitions = partitions,
      error => this.onError(error)
      );
  };

  save() {
    this.partitionService.save(this.partition).
      subscribe(
      partition => this.refresh(),
      error => this.onError(error)
      );
  };

  destroy() {
    this.partitionService.destroy(this.partition).
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
    this.newPartition = true;
    this.partition = new Partition();
    this.displayDialog = true;
  }

  onRowSelect(event) {
    this.newPartition = false;
    this.partition = this.clonePartition(event.data);
    this.displayDialog = true;
  };

  clonePartition(s: Partition): Partition {
    let partition = new Partition();
    for (let prop in s) {
      if (prop) {
        partition[prop] = s[prop];
      }
    }
    return partition;
  }

}

