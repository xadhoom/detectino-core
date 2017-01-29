/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { PartitionService } from './partition.service';

describe('PartitionService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [PartitionService]
    });
  });

  it('should ...', inject([PartitionService], (service: PartitionService) => {
    expect(service).toBeTruthy();
  }));
});
