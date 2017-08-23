import { Output } from './output';

export class Event {
  id: number;
  name: string;
  description: string;
  source: string;
  source_config: string; // tslint:disable-line
  outputs: Output[];

  constructor() { };
}

export class EventSensorConfig {
  address: string;
  port: number;
  type: string;
}

export class EventPartitionConfig {
  name: string;
  type: string;
}

export class EventArmingConfig {
  name: string;
}
