export class Eventlog {
  id: number;
  type: string;
  acked: boolean;
  operation: string;
  details: Object;
  inserted_at: Date;
}
