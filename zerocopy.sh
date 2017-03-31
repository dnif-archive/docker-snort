#!/bin/bash

# Reference: https://github.com/HurricaneLabs/docker-pfring/blob/master/zerocopy.sh

if [[ $INTERFACE == zc:* ]]; then
    # PF_RING ZeroCopy
    if [ -n "$ZC_LICENSE_DATA" ]; then
        mkdir -p /etc/pf_ring
        echo $ZC_LICENSE_DATA > /etc/pf_ring/$ZC_LICENSE_MAC
    fi

    # You can use -v to mount the host's /mnt/huge
    # Which allows you to do load balancing magic
    if [ ! -d /mnt/huge ]; then
        mkdir /mnt/huge
        mount -t hugetlbfs nodev /mnt/huge
    fi
fi