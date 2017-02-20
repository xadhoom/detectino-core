import { Component, OnInit, ViewEncapsulation } from '@angular/core';
import {
  PartitionService, SensorService,
  NotificationService
} from '../services';
import { Sensor } from '../models/sensor';
import { Partition } from '../models/partition';
import { SelectItem } from 'primeng/primeng';

@Component({
  selector: 'app-sensors',
  templateUrl: './sensors.component.html',
  styleUrls: ['./sensors.component.scss'],
  encapsulation: ViewEncapsulation.None
})

export class SensorsComponent implements OnInit {

  sensor: Sensor;

  sensors: Sensor[];
  balance_types: SelectItem[];
  selectedPartitions: Partition[];
  partitions: Partition[];

  selectedSensor: Sensor;

  displayDialog: boolean;
  displayTh1: boolean;
  displayTh2: boolean;
  displayTh3: boolean;
  displayTh4: boolean;

  newSensor: boolean;

  errorMessage: string;

  constructor(private sensorService: SensorService,
    private partitionService: PartitionService,
    private notificationService: NotificationService) { };

  ngOnInit() {
    this.balance_types = [{ label: 'Select a type', value: null }];
    this.balance_types.push({ label: 'NC', value: 'NC' });
    this.balance_types.push({ label: 'NO', value: 'NO' });
    this.balance_types.push({ label: 'EOL', value: 'EOL' });
    this.balance_types.push({ label: 'DEOL', value: 'DEOL' });
    this.balance_types.push({ label: 'TEOL', value: 'TEOL' });
    this.all();
  };

  allPartitions() {
    this.partitionService.all().
      subscribe(
      items => this.partitions = items,
      error => this.onError(error)
      );
  };

  all() {
    this.partitions = [];
    this.selectedPartitions = [];
    this.allPartitions();

    this.sensorService.all().
      subscribe(
      items => this.sensors = items,
      error => this.onError(error)
      );
  };

  save() {
    this.sensor.partitions = this.selectedPartitions;
    this.sensorService.save(this.sensor).
      subscribe(
      sensor => this.refresh(),
      error => this.onError(error)
      );
  };

  destroy() {
    this.sensorService.destroy(this.sensor).
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
    this.newSensor = true;
    this.sensor = new Sensor();
    this.displayDialog = true;
  }

  onRowSelect(event) {
    this.newSensor = false;
    this.sensor = this.cloneSensor(event.data);
    this.selectedPartitions = this.sensor.partitions;
    this.partitions = this.availPartitions(this.partitions, this.selectedPartitions);
    this.displayDialog = true;
  };

  availPartitions(avail: Array<any>, used: Array<any>): Array<any> {
    const aIDs = avail.map(i => i.id);
    const bIDs = used.map(i => i.id);
    return avail.filter(i => bIDs.indexOf(i.id) < 0);
  };

  public checkThresholds() {
    this.checkTh1();
    this.checkTh2();
    this.checkTh3();
    this.checkTh4();
  }

  ngDoCheck() {
    if (this.sensor) {
      this.checkThresholds();
    }
  }

  private checkTh1() {
    if (this.sensor.balance) {
      this.displayTh1 = true;
    }
    return false;
  }

  private checkTh2() {
    const balances = ['EOL', 'DEOL', 'TEOL'];
    this.displayTh2 = this.checkBalance(balances);
  }

  private checkTh3() {
    const balances = ['DEOL', 'TEOL'];
    this.displayTh3 = this.checkBalance(balances);
  }

  private checkTh4() {
    const balances = ['TEOL'];
    this.displayTh4 = this.checkBalance(balances);
  }

  private checkBalance(balances: string[]) {
    return balances.some((balance) => this.sensor.balance == balance);
  }

  private cloneSensor(s: Sensor): Sensor {
    const sensor = new Sensor();
    for (const prop in s) {
      if (prop) {
        sensor[prop] = s[prop];
      }
    }
    return sensor;
  }

}
