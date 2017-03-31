#!/bin/sh

# Reference: https://github.com/HurricaneLabs/docker-snort/blob/master/compile_pfring_dna_daq.sh

FILENAME=$( basename $PFRING_DAQ_MODULE_DNA )

cd /usr/local/src
cp $PFRING_DAQ_MODULE_DNA .
tar xzf $FILENAME
cd pfring-daq-module-dna

autoreconf -ivf
./configure --prefix="/opt/daq" \
    --with-libdaq-includes=/opt/daq/include \
    --with-libsfbpf-includes=/opt/daq/include \
    --with-libsfbpf-libraries=/opt/daq/lib \
    --with-libpfring-includes=/opt/pf_ring/include \
    --with-libpfring-libraries=/opt/pf_ring/lib
make
make install