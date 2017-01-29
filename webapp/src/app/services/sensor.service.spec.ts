/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { SensorService } from './sensor.service';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../app.module';

describe('SensorService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    });
  });

  it('should ...', inject([SensorService], (service: SensorService) => {
    expect(service).toBeTruthy();
  }));
});
