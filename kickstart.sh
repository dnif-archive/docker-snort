#!/bin/bash

sed -i "s|ipvar HOME\_NET \[10\.0\.0\.0\/8\,172\.16\.0\.0\/12\,192\.168\.0\.0\/16\i]|ipvar HOME\_NET $HOME_NET|" /etc/snort/snort.conf
# python /usr/local/src/snort-agent/snort-agent.py &
# snort -i $INTERFACE -u snort -g snort -d -c /etc/snort/snort.conf -l /var/log/snort
