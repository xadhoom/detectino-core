/* tslint:disable:no-unused-variable */
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { DebugElement } from '@angular/core';

import { IntrusionComponent } from './intrusion.component';

describe('IntrusionComponent', () => {
  let component: IntrusionComponent;
  let fixture: ComponentFixture<IntrusionComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ IntrusionComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(IntrusionComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
