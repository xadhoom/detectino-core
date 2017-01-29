/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { SensorService } from './sensor.service';

describe('SensorService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [SensorService]
    });
  });

  it('should ...', inject([SensorService], (service: SensorService) => {
    expect(service).toBeTruthy();
  }));
});
