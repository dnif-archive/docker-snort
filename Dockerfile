FROM ubuntu:16.04

RUN apt-get update
RUN apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev

RUN apt-get -y install build-essential autoconf automake libtool libnet1-dev \
    libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 \
    make flex bison git wget libmagic-dev pkg-config libnuma-dev strace \
    perl libio-socket-ssl-perl libcrypt-ssleay-perl ca-certificates libwww-perl

RUN apt-get -y install libpcap-dev

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

# Build DAQ
RUN cd /usr/local/src/daq-* && \
    ldconfig -v && \
    ./configure && \
    make && \
    make install
RUN echo "/opt/daq/lib/daq" > /etc/ld.so.conf.d/daq.conf
RUN ldconfig
ENV PATH /opt/daq/bin:$PATH


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
    ./configure \
        --with-dnet-includes=/opt/snort/include \
        --with-dnet-libraries=/opt/snort/lib && \
    make && \
    make install
ENV PATH /opt/snort/bin:$PATH

RUN ldconfig