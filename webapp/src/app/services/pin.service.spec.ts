/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { PinService } from './pin.service';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../app.module';

describe('PinService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    });
  });

  it('should ...', inject([PinService], (service: PinService) => {
    expect(service).toBeTruthy();
  }));
});
