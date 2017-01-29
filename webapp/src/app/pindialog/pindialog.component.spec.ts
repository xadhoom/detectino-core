/* tslint:disable:no-unused-variable */
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { DebugElement } from '@angular/core';

import { PindialogComponent } from './pindialog.component';

describe('PindialogComponent', () => {
  let component: PindialogComponent;
  let fixture: ComponentFixture<PindialogComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ PindialogComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PindialogComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
