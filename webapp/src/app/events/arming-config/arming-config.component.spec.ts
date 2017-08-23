/* tslint:disable:no-unused-variable */
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { DebugElement } from '@angular/core';
import { RouterTestingModule } from '@angular/router/testing';
import { AppModule } from '../../app.module';

import { ArmingConfigComponent } from './arming-config.component';

describe('ArmingConfigComponent', () => {
  let component: ArmingConfigComponent;
  let fixture: ComponentFixture<ArmingConfigComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [AppModule, RouterTestingModule]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ArmingConfigComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
