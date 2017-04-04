#!/bin/bash

sed -i "s|ipvar HOME\_NET any|ipvar HOME\_NET $HOME_NET|" /etc/snort/snort.conf
snort -i $INTERFACE -u snort -g snort -d -D -c /etc/snort/snort.conf -l /var/log/snort &