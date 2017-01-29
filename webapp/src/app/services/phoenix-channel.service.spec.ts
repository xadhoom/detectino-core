/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { PhoenixChannelService } from './phoenix-channel.service';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../app.module';

describe('PhoenixChannelService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    });
  });

  it('should ...', inject([PhoenixChannelService], (service: PhoenixChannelService) => {
    expect(service).toBeTruthy();
  }));
});
