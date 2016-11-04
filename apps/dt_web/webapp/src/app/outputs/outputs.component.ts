import { Component, OnInit } from '@angular/core';

import { OutputService, NotificationService } from '../services';

import { Output } from '../models/output';

import { SelectItem } from 'primeng/primeng';

@Component({
  selector: 'outputs',
  template: require('./outputs.component.html'),
  styles: [require('./outputs.component.css')]
})

export class Outputs implements OnInit {

  output: Output;

  outputs: Output[];
  types: SelectItem[];

  selectedOutput: Output;

  displayDialog: boolean;

  newOutput: boolean;

  errorMessage: string;

  constructor(private outputService: OutputService,
    private notificationService: NotificationService) { };

  ngOnInit() {
    this.types = [{ label: 'Select a type', value: null }];
    this.types.push({ label: 'Email', value: 'email' });
    this.types.push({ label: 'Bus', value: 'bus' });
    this.all();
  };

  all() {
    this.outputService.all().
      subscribe(
      outputs => this.outputs = outputs,
      error => this.onError(error)
      );
  };

  save() {
    this.outputService.save(this.output).
      subscribe(
      output => this.refresh(),
      error => this.onError(error)
      );
  };

  destroy() {
    this.outputService.destroy(this.output).
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
    this.newOutput = true;
    this.output = new Output();
    this.displayDialog = true;
  }

  onRowSelect(event) {
    this.newOutput = false;
    this.output = this.cloneOutput(event.data);
    this.displayDialog = true;
  };

  cloneOutput(s: Output): Output {
    let output = new Output();
    for (let prop in s) {
      if (prop) {
        output[prop] = s[prop];
      }
    }
    return output;
  }

}

