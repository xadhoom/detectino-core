import { Component, OnInit } from '@angular/core';
import {
  PartitionService, NotificationService,
  PinService
} from '../services';
import { MatIconRegistry } from '@angular/material';
import { DomSanitizer } from '@angular/platform-browser';
import { Partition } from '../models/partition';

@Component({
  selector: 'app-intrusion',
  templateUrl: './intrusion.component.html',
  styleUrls: ['./intrusion.component.scss']
})

export class IntrusionComponent implements OnInit {
  partitions: Partition[];
  errorMessage: string;

  public selectedPartition: Partition;
  public showArmDialog: boolean;

  constructor(private partitionService: PartitionService,
    private notificationService: NotificationService,
    public pinSrv: PinService, iconRegistry: MatIconRegistry,
    sanitizer: DomSanitizer) {
    this.selectedPartition = null;
    this.showArmDialog = false;

    iconRegistry.addSvgIcon(
      'lock-outline',
      sanitizer.bypassSecurityTrustResourceUrl('assets/images/lock-outline.svg'));
    iconRegistry.addSvgIcon(
      'lock-open-outline',
      sanitizer.bypassSecurityTrustResourceUrl('assets/images/lock-open-outline.svg'));
    iconRegistry.addSvgIcon(
      'security-home',
      sanitizer.bypassSecurityTrustResourceUrl('assets/images/security-home.svg'));
    iconRegistry.addSvgIcon(
      'security-close',
      sanitizer.bypassSecurityTrustResourceUrl('assets/images/close.svg'));
  }

  ngOnInit() {
    this.partitions = [];

    this.pinSrv.observePin().subscribe(
      pin => { this.loadPartitions(pin); }
    );
  }

  public doArm(part: Partition, mode: string) {
    this.partitionService.arm(part, mode).subscribe(
      res => {
        this.notificationService.success('Partition armed successfully');
        this.cancelArming();
      },
      error => this.onError(error)
    );
  }

  public doDisarm(part: Partition) {
    this.partitionService.disarm(part).subscribe(
      res => {
        this.notificationService.success('Partition disarmed successfully');
        this.cancelArming();
      },
      error => this.onError(error)
    );
  }

  public cancelArming() {
    this.reloadPartitions();
    this.showArmDialog = false;
    this.selectedPartition = null;
  }

  public armDisarmPartition(part: Partition) {
    this.showArmDialog = true;
    this.selectedPartition = part;
  }

  public isArmed(partition: Partition) {
    let armed = false;
    switch (partition.armed) {
      case 'ARM':
        armed = true; break;
      case 'ARMSTAY':
        armed = true; break;
      case 'ARMSTAYIMMEDIATE':
        armed = true; break;
      case 'DISARM':
        armed = false; break;
      case null:
        armed = false; break;
      default:
        armed = false;
        console.error('unhandled arming status: ', partition);
        break;
    }
    return armed;
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

