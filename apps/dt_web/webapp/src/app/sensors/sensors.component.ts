import { Component, OnInit } from '@angular/core';

import { SensorService, NotificationService } from '../services';

import { Sensor } from '../models/sensor';

import { SelectItem } from 'primeng/primeng';

@Component({
    selector: 'sensors',
    template: require('./sensors.component.html'),
    styles: [ require('./sensors.component.css') ]
})

export class Sensors implements OnInit {

  sensor: Sensor;

  sensors: Sensor[];

  selectedSensor: Sensor;

  displayDialog: boolean;

  newSensor: boolean;

  errorMessage: string;

  constructor(private sensorService: SensorService,
              private notificationService: NotificationService) {};

  ngOnInit() {
    this.all();
  };

  all() {
    this.sensorService.all().
      subscribe(
        sensors => this.sensors = sensors,
        error => this.onError(error)
    );
  };

  save() {
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
    this.displayDialog = true;
  };

  cloneSensor(s: Sensor): Sensor {
    let sensor = new Sensor();
    for (let prop in s) {
      if (prop) {
        sensor[prop] = s[prop];
      }
    }
    return sensor;
  }

}

