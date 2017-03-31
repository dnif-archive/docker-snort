FROM ubuntu:16.04

# Credits: https://github.com/HurricaneLabs/docker-pfring/blob/master/Dockerfile

RUN apt-get update
RUN apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev \
    build-essential autoconf automake libtool libnet1-dev \
    libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 \
    make flex bison git wget libmagic-dev pkg-config libnuma-dev strace \
    perl libio-socket-ssl-perl libcrypt-ssleay-perl ca-certificates libwww-perl

RUN cd /usr/local/src && git clone https://github.com/ntop/PF_RING.git

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/pf_ring/lib

# Build the userland library
RUN cd /usr/local/src/PF_RING/userland/lib && \
    LIBS="-L/opt/pf_ring/lib -lrt -lnuma" ./configure --prefix=/opt/pf_ring && \
    make && \
    make install

# Build libpcap
RUN cd /usr/local/src/PF_RING/userland/libpcap-* && \
    LIBS="-L/opt/pf_ring/lib -lpfring -lpthread -lrt -lnuma" \
        ./configure --prefix=/opt/pf_ring && \
    make && \
    make install

# Build tcpdump against new libpcap
RUN cd /usr/local/src/PF_RING/userland/tcpdump-* && \
    LIBS="-L/opt/pf_ring/lib -lrt -lnuma" ./configure --prefix=/opt/pf_ring && \
    make && \
    make install

# Build example userland tools
RUN cd /usr/local/src/PF_RING/userland/examples && \
    make
RUN cd /usr/local/src/PF_RING/userland/examples_zc && \
    make

# Copy the pf_ring kernel source header
RUN cp /usr/local/src/PF_RING/kernel/linux/pf_ring.h /usr/include/linux/pf_ring.h

# Configure LD_LIBRARY_PATH
RUN echo "/opt/pf_ring/lib" > /etc/ld.so.conf.d/pfring.conf
RUN ldconfig

# Add /opt/pf_ring to $PATH
ENV PATH /opt/pf_ring/bin:/opt/pf_ring/sbin:$PATH

ADD docker-entrypoint.sh /entrypoint.sh
ADD zerocopy.sh /zerocopy.sh

RUN chmod +rx entrypoint.sh

# Fetch source
RUN cd /usr/local/src && \
    wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz && \
    tar xzf daq-2.0.6.tar.gz
RUN cd /usr/local/src && \
    wget https://www.snort.org/downloads/snort/snort-2.9.9.0.tar.gz && \
    tar xzf snort-2.9.9.0.tar.gz
RUN cd /usr/local/src && \
    wget https://github.com/dugsong/libdnet/archive/libdnet-1.12.tar.gz  && \
    tar xzf libdnet-1.12.tar.gz
RUN cd /usr/local/src && \
    wget https://github.com/shirkdog/pulledpork/archive/v0.7.2.tar.gz && \
    tar xzf v0.7.2.tar.gz

# Build DAQ
RUN cd /usr/local/src/daq-* && \
    ldconfig -v && \
    LIBS="-lrt -lnuma" ./configure --prefix="/opt/daq" \
        --disable-nfq-module \
        --disable-ipq-module \
        --with-libpcap-includes=/opt/pf_ring/include \
        --with-libpcap-libraries=/opt/pf_ring/lib && \
    make && \
    make install
RUN echo "/opt/daq/lib/daq" > /etc/ld.so.conf.d/daq.conf
RUN ldconfig
ENV PATH /opt/daq/bin:$PATH

# Build pfring-daq-module
RUN cd /usr/local/src/PF_RING/userland/snort/pfring-daq-module && \
    autoreconf -ivf
RUN cd /usr/local/src/PF_RING/userland/snort/pfring-daq-module && \
    LIBS="-lrt -lnuma" ./configure --prefix="/opt/daq" \
        --with-libdaq-includes=/opt/daq/include \
        --with-libsfbpf-includes=/opt/daq/include \
        --with-libsfbpf-libraries=/opt/daq/lib \
        --with-libpfring-includes=/opt/pf_ring/include \
        --with-libpfring-libraries=/opt/pf_ring/lib && \
    make && \
    make install

# Build libdnet
RUN cd /usr/local/src/libdnet-libdnet-* && \
    ./configure --prefix=/opt/snort "CFLAGS=-fPIC" && \
    make && \
    make install
RUN echo "/opt/snort/lib" > /etc/ld.so.conf.d/snort.conf
RUN cp /opt/snort/lib/libdnet.1.0.1 /opt/snort/lib/libdnet.so.1.0.1
RUN ldconfig -v

# Build snort
RUN cd /usr/local/src/snort-* && \
    ./configure --prefix=/opt/snort \
        --enable-ipv6 \
        --enable-zlib \
        --enable-gre \
        --enable-mpls \
        --enable-targetbased \
        --enable-decoder-preprocessor-rules \
        --enable-pthread \
        --enable-dynamicplugin \
        --enable-normalizer \
        --disable-static-daq \
        --with-daq-includes=/opt/daq/include \
        --with-daq-libraries=/opt/daq/lib \
        --with-dnet-includes=/opt/snort/include \
        --with-dnet-libraries=/opt/snort/lib \
        --with-libpcap-includes=/opt/pf_ring/include \
        --with-libpcap-libraries=/opt/pf_ring/lib \
        --with-libpfring-includes=/opt/pf_ring/include \
        --with-libpfring-libraries=/opt/pf_ring/lib && \
    make && \
    make install
ENV PATH /opt/snort/bin:$PATH

# Install pulledpork
RUN cp /usr/local/src/pulledpork-*/pulledpork.pl /opt/snort/bin && \
    chmod 0755 /opt/snort/bin/pulledpork.pl

ADD compile_pfring_dna_daq.sh /compile_pfring_dna_daq.sh
ADD snort-entrypoint.sh /snort-entrypoint.sh
ADD pulledpork.sh /pulledpork.sh

RUN chmod +rx snort-entrypoint.sh && \
    chmod +rx zerocopy.sh && \
    chmod +rx compile_pfring_dna_daq.sh && \
    chmod +rx pulledpork.sh

RUN /entrypoint.sh
RUN /snort-entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]
# ENTRYPOINT ["/snort-entrypoint.sh"]
# CMD ["snort"]