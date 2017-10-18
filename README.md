[![Build Status](https://travis-ci.org/xadhoom/detectino-core.svg)](https://travis-ci.org/xadhoom/detectino-core) [![Coverage Status](https://coveralls.io/repos/github/xadhoom/detectino-core/badge.svg?branch=develop)](https://coveralls.io/github/xadhoom/detectino-core?branch=develop)

Detectino
=========

** TODO: Finish this project :) **

This is (ehm "will be") the Detectino Alarm project.

The project is made by 3 parts:

* some hardware: https://github.com/xadhoom/dt-expander-hardware
* software for the hardware: https://github.com/xadhoom/dt-expander
* self

Detectino Core is the software part that will run over a RaspberryPi B+
and handles all events sent by alarm sensors over CAN bus (mediated
by the Arduino Detectino piggy back board).

Core provides all the logic to handle alarms, trigger notifications
and a web interface to configure or activate/deactivate the alarm system.

Detectino is born to create a professional grade alarm system, for 2 main reasons:

* commercial systems cannot be easily expanded with custom hardware/software
  (read: a stupid https board costs big bucks and have no public APIs);
* arduino/raspberry alarm systems are pretty... "meh";
* be able to use commercial alarm sensors, because they're the ones that just work;
* learn something new: basic hardware skills and Elixir (http://elixir-lang.org/).

Right now this project is running in my home with 4 outdoor sensors and 1 indoor.

All alarms are reported by email (for now).

A tablet in kiosk mode fixed on a wall provides the access to the web frontend.

TODO: add some nice pics and some more docs

