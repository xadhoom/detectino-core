import { Component, OnInit } from '@angular/core';
import {
  PartitionService, SensorService,
  NotificationService
} from '../services';
import { Sensor } from '../models/sensor';
import { Partition } from '../models/partition';

@Component({
  selector: 'app-sensors',
  templateUrl: './sensors.component.html',
  styleUrls: ['./sensors.component.scss']
})

export class SensorsComponent implements OnInit {

  sensor: Sensor;

  sensors: Sensor[];

  selectedPartitions: Partition[];
  partitions: Partition[];

  selectedSensor: Sensor;

  displayDialog: boolean;

  newSensor: boolean;

  errorMessage: string;

  constructor(private sensorService: SensorService,
    private partitionService: PartitionService,
    private notificationService: NotificationService) { };

  ngOnInit() {
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

  cloneSensor(s: Sensor): Sensor {
    const sensor = new Sensor();
    for (const prop in s) {
      if (prop) {
        sensor[prop] = s[prop];
      }
    }
    return sensor;
  }

}
