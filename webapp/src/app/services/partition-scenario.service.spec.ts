/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { PartitionScenarioService } from './partition-scenario.service';

describe('PartitionScenarioService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [PartitionScenarioService]
    });
  });

  it('should ...', inject([PartitionScenarioService], (service: PartitionScenarioService) => {
    expect(service).toBeTruthy();
  }));
});
