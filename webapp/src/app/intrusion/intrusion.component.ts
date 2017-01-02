import { Component, OnInit, ViewEncapsulation, Input } from '@angular/core';

import { PartitionService, NotificationService, PinService } from '../services';
import { Partition } from '../models/partition';

@Component({
  selector: 'dt-intrusion',
  styleUrls: ['./intrusion.component.scss', '../shared/common.scss'],
  templateUrl: './intrusion.component.html'
})

export class Intrusion implements OnInit {
  partitions: Partition[];
  errorMessage: string;

  private selectedPartition: Partition;
  private showArmDialog: boolean;

  constructor(private partitionService: PartitionService,
    private notificationService: NotificationService,
    private pinSrv: PinService) {
    this.selectedPartition = null;
    this.showArmDialog = false;
  }

  ngOnInit() {
    this.partitions = [];

    this.pinSrv.observePin().subscribe(
      pin => { this.loadPartitions(pin); }
    );
  }

  private doArm(part: Partition, mode: string) {
    this.partitionService.arm(part, mode).subscribe(
      res => {
        this.notificationService.success('Partition armed successfully');
        this.cancelArming();
      },
      error => this.onError(error)
    );
  }

  private doDisarm(part: Partition) {
    this.partitionService.disarm(part).subscribe(
      res => {
        this.notificationService.success('Partition disarmed successfully');
        this.cancelArming();
      },
      error => this.onError(error)
    );
  }

  private armDisarmPartition(part: Partition) {
    this.showArmDialog = true;
    this.selectedPartition = part;
  }

  private isArmed(partition: Partition) {
    let armed = false;
    switch (partition.armed) {
      case "ARM":
        armed = true; break;
      case "ARMSTAY":
        armed = true; break;
      case "ARMSTAYIMMEDIATE":
        armed = true; break;
      case "DISARM":
        armed = false; break;
      case null:
        armed = false; break;
    }
    return armed;
  }

  private cancelArming() {
    this.reloadPartitions();
    this.showArmDialog = false;
    this.selectedPartition = null;
  }

  private getInitials(name: string) {
    return name[0];
  }

  private onError(error: any) {
    this.errorMessage = <any>error;
    this.notificationService.error(this.errorMessage);
  }

  private setPartitions(partitions) {
    this.partitions = partitions;
  }

  private reloadPartitions() {
    // pin expected to be already set in pinSrv
    this.partitionService.all().subscribe(
      partitions => this.setPartitions(partitions),
      error => this.onError(error)
    );
  }

  private loadPartitions(pin) {
    if (!pin) { return; }
    this.reloadPartitions();
  }
}
