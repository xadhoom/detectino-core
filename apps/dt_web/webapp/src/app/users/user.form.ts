import {Component, Input} from '@angular/core';
import {FORM_DIRECTIVES, FormBuilder, Control, ControlGroup, Validators} from '@angular/common';

import {InputText} from 'primeng/primeng';

@Component({
    selector: 'user-form',
    directives: [
      FORM_DIRECTIVES,
      InputText
    ],
    template: require('./user.form.html'),
    styles: [ require('./user.form.css') ]
})

export class UserForm {
  @Input() user;

  form: ControlGroup;
  name: Control = new Control('', Validators.required);

  constructor(fb: FormBuilder) {
    this.form = fb.group({
      'name': this.name,
      'username': ['', Validators.required]
    });
  };

  onSubmit() {
    console.log(this.form);
  };
}

