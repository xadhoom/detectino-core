/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { PartitionScenarioService } from './partition-scenario.service';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../app.module';

describe('PartitionScenarioService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    });
  });

  it('should ...', inject([PartitionScenarioService], (service: PartitionScenarioService) => {
    expect(service).toBeTruthy();
  }));
});
