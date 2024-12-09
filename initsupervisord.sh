#!/bin/bash

echo "Creating log dir"
mkdir -p /opt/log
echo $(ls -l /opt)
echo "Starting supervisor deamon"
/usr/bin/supervisord -n
