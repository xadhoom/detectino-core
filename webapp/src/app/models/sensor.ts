import { Partition } from './partition';

export class Sensor {
  id: number;
  address: string;
  port: number;
  name: string;
  enabled: boolean;

  balance: string; // type of balance, one of NC, NO, EOL, DEOL, TEOL
  th1: number; // these are the thresholds for various balance modes
  th2: number;
  th3: number;
  th4: number;
  // tamp24h: boolean;
  full24h: boolean;
  entry_delay: boolean;
  exit_delay: boolean;
  internal: boolean;

  partitions: Partition[];

  constructor() { };
}
