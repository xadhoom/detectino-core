export class EventLogDetails {
  source: string;
  ev: Object;
}

export class Eventlog {
  id: number;
  type: string;
  acked: boolean;
  operation: string;
  details: EventLogDetails;
  inserted_at: Date;
}
