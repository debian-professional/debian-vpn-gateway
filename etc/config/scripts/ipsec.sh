#!/bin/bash

ipsec up $2 > /dev/null 2>&1

while true
 do
   ping -c 1 $1 > /dev/null 2>&1
   ipsec up $2 > /dev/null 2>&1
   sleep 200
 done

