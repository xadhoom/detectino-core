import { TestBed, inject } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../app.module';
import { EventlogService } from './eventlog.service';

describe('EventlogService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    });
  });

  it('should ...', inject([EventlogService], (service: EventlogService) => {
    expect(service).toBeTruthy();
  }));
});
