export class PartitionScenario {
  id: number;
  mode: string;
  scenario_id: number; // tslint:disable-line
  partition_id: number; // tslint:disable-line

  constructor(scenarioId) {
    this.scenario_id = scenarioId; // tslint:disable-line
  };
}
