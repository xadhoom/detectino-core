import { TestBed, inject } from '@angular/core/testing';
import { BeeperService } from './beeper.service';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../app.module';

describe('BeeperService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    });
  });

  it('should ...', inject([BeeperService], (service: BeeperService) => {
    expect(service).toBeTruthy();
  }));
});
