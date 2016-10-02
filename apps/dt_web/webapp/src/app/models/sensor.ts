import { Partition } from './partition';

export class Sensor {
  id: number;
  address: string;
  port: number;
  name: string;
  enabled: boolean;
  partitions: Partition[];

  constructor() {};
}
