/* tslint:disable:no-unused-variable */

import { TestBed, async, inject } from '@angular/core/testing';
import { NotificationService } from './notification.service';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../app.module';

describe('NotificationService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    });
  });

  it('should ...', inject([NotificationService], (service: NotificationService) => {
    expect(service).toBeTruthy();
  }));
});
