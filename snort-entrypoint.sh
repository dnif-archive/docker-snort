#!/bin/bash

# Reference: https://github.com/HurricaneLabs/docker-snort/blob/master/docker-entrypoint.sh

# Expects:
#   -e INTERFACE - sniffing interface ON THE HOST
#   -e INSTANCE - the name of the per-interface instance to support multiple configs per interface
#   -e SENSOR_IP - the IP of the HOST
#   -e OPTS - additional options to pass to snort
#   -e HOMENET - to override HOME_NET setting in snort.conf

source /zerocopy.sh

if [ -n "$PFRING_DAQ_MODULE_DNA" ]; then
    /compile_pfring_dna_daq.sh
fi

if [ "$1" = "snort" ]; then
    LOGDIR=/data/$INSTANCE/logs/$HOSTNAME
    [ -d $LOGDIR ] || mkdir -p $LOGDIR

    CONFDIR=/data/$INSTANCE/etc
    CONFIG=$CONFDIR/snort.conf
    RULES=$CONFDIR/rules

    if [ -z "$DISABLE_PULLEDPORK" ]; then
        /pulledpork.sh
        OPTS="$OPTS -S RULES_FILE=snort.$HOSTNAME.rules"
    fi

    [ -z "$HOMENET" ] || OPTS="$OPTS -S HOME_NET=$HOMENET"
    [ -z "$SENSOR_IP" ] || OPTS="$OPTS -S SENSOR_IP=$SENSOR_IP"

    exec /opt/snort/bin/snort -m 027 -d -l $LOGDIR $OPTS -c $CONFIG -i $INTERFACE
fi

exec "$@"