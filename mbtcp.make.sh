#!/bin/sh

gcc -o mbtcp mbtcp.c -lrt -I/usr/include/modbus -lmodbus
