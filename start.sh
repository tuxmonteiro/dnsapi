#!/bin/bash

/etc/init.d/pdns start > /dev/null 2>&1 &
/etc/init.d/bind9 start > /dev/null 2>&1 &
#/etc/init.d/gdns2pdns start > /dev/null 2>&1 &
/bin/bash
