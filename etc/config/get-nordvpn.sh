#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)

