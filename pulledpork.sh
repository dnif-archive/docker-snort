#!/bin/sh

# Reference: https://github.com/HurricaneLabs/docker-snort/blob/master/pulledpork.sh

PPDIR=/data/$INSTANCE/pulledpork
PPCONFIG=$PPDIR/pulledpork.conf

mkdir -p /var/lib/pulledpork
cp /data/rules/* /var/lib/pulledpork
mkdir -p /opt/snort/lib/snort_dynamicrules
mkdir -p /opt/snort/rules

/opt/snort/bin/pulledpork.pl -n -P -v -T \
    -c $PPCONFIG \
    -m $CONFDIR/sid-msg.map \
    -s /opt/snort/lib/snort_dynamicrules \
    -L $RULES/local.rules,$RULES/hd.rules \
    -o $RULES/snort.$HOSTNAME.rules \
    -e $PPDIR/enablesid.conf \
    -i $PPDIR/disablesid.conf \
    -M $PPDIR/modifysid.conf \
    -b $PPDIR/dropsid.conf \
    -h $LOGDIR/pulledpork.log

rm -rf /var/lib/pulledpork