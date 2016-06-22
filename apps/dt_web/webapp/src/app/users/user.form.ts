import {Component, Input} from '@angular/core';
// import {FORM_DIRECTIVES, FormBuilder, Control, ControlGroup, Validators} from '@angular/common';
import {REACTIVE_FORM_DIRECTIVES, FormBuilder,
  FormGroup, FormControl, Validators} from '@angular/forms';

import {InputText} from 'primeng/primeng';

@Component({
    selector: 'user-form',
    directives: [
      REACTIVE_FORM_DIRECTIVES,
      InputText
    ],
    template: require('./user.form.html'),
    styles: [ require('./user.form.css') ]
})

export class UserForm {
  @Input() user;

  form: FormGroup;

  constructor(fb: FormBuilder) {
    this.form = fb.group({
      'id':  new FormControl(),
      'role':  new FormControl(),
      'password':  new FormControl(),
      'name': new FormControl('', Validators.required),
      'username': new FormControl('', Validators.required)
    });
  };

  onSubmit() {
    console.log(this.form);
  };
}

