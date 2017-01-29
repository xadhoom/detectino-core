/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { PinService } from './pin.service';

describe('PinService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [PinService]
    });
  });

  it('should ...', inject([PinService], (service: PinService) => {
    expect(service).toBeTruthy();
  }));
});
