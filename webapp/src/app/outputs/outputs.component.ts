import { Component, OnInit } from '@angular/core';
import { OutputService, NotificationService } from '../services';
import { Output, OutputEmailConfig, OutputBusConfig } from '../models/output';
import { SelectItem } from 'primeng/primeng';

@Component({
  selector: 'app-outputs',
  templateUrl: './outputs.component.html',
  styleUrls: ['./outputs.component.scss']
})

export class OutputsComponent implements OnInit {
  output: Output;

  outputs: Output[];
  types: SelectItem[];
  busTypes: SelectItem[];

  selectedOutput: Output;

  displayDialog: boolean;
  showEmailConfig: boolean;
  showBusConfig: boolean;

  newOutput: boolean;

  errorMessage: string;

  constructor(private outputService: OutputService,
    private notificationService: NotificationService) { };

  ngOnInit() {
    this.types = [{ label: 'Select a type', value: null }];
    this.types.push({ label: 'Email', value: 'email' });
    this.types.push({ label: 'Bus', value: 'bus' });

    this.busTypes = [{ label: 'Select a type', value: null }];
    this.busTypes.push({ label: 'Monostable', value: 'monostable' });
    this.busTypes.push({ label: 'Bistable', value: 'bistable' });

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
    this.checkConfigs();
    this.displayDialog = true;
  }

  onRowSelect(event) {
    this.newOutput = false;
    this.output = this.cloneOutput(event.data);
    this.checkConfigs();
    this.displayDialog = true;
  };

  checkConfigs() {
    if (!this.output.email_settings) {
      this.output.email_settings = new OutputEmailConfig();
    }
    if (!this.output.bus_settings) {
      this.output.bus_settings = new OutputBusConfig();
    }
  };

  cloneOutput(s: Output): Output {
    const output = new Output();
    for (const prop in s) {
      if (prop) {
        output[prop] = s[prop];
      }
    }
    return output;
  }

}


