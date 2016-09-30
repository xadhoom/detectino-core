export class PartitionScenario {
  id: number;
  mode: string;
  scenario_id: number; // tslint:disable-line
  partition_id: number; // tslint:disable-line

  constructor(scenario_id) {
    this.scenario_id = scenario_id;
  };
}
