#!/bin/bash
#
# this must be run as root, on a system that supports 
# the virtual socket CAN bus driver.
#
# See also https://www.kernel.org/doc/Documentation/networking/can.txt
#
# Having https://github.com/linux-can/can-utils/ installed
# can be useful for advanced simulation/setup
#

modprobe vcan
ip link add type vcan
ip link add dev vcan0 type vcan
ip link set vcan0 up

