/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { ScenarioService } from './scenario.service';

describe('ScenarioService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [ScenarioService]
    });
  });

  it('should ...', inject([ScenarioService], (service: ScenarioService) => {
    expect(service).toBeTruthy();
  }));
});
