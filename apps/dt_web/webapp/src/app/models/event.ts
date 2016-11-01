import { Output } from "./output";

export class Event {
  id: number;
  name: string;
  description: string;
  source: string;
  source_config: string; // tslint:disable-line
  outputs: Output[];

  constructor() { };
}
