FROM ubuntu:16.04

RUN apt-get update
RUN apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev libpcap-dev\
    build-essential autoconf automake libtool libnet1-dev \
    libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 \
    make flex bison git wget libmagic-dev pkg-config libnuma-dev strace \
    perl libio-socket-ssl-perl libcrypt-ssleay-perl ca-certificates libwww-perl \
    python-pip redis-server python-pcapy python-dpkt

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

RUN pip install pygeoip redis

RUN groupadd snort && \
    useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort && \
    mkdir /etc/snort /etc/snort/rules /usr/local/lib/snort_dynamicrules /var/log/snort && \
    touch /etc/snort/rules/white_list.rules /etc/snort/rules/black_list.rules /etc/snort/rules/local.rules && \
    chmod -R 5775 /etc/snort /var/log/snort /usr/local/lib/snort_dynamicrules && \
    chown -R snort:snort /etc/snort /var/log/snort /usr/local/lib/snort_dynamicrules

RUN cp /usr/local/src/snort-2.9.9.0/etc/*.conf* /etc/snort && \
    cp /usr/local/src/snort-2.9.9.0/etc/*.map /etc/snort && \
    ln -s /usr/local/bin/snort /usr/sbin/snort

RUN cd /usr/local/src/ && \
    wget https://www.snort.org/rules/community -O community.tar.gz && \
    tar -xvf community.tar.gz && \
    sed -i 's/include \$RULE\_PATH/# include \$RULE\_PATH/' /etc/snort/snort.conf && \
    cd community-rules && \
    rm snort.conf && \
    cp * /etc/snort/rules && \
    echo "include /etc/snort/rules/local.rules" >> /etc/snort/snort.conf && \
    echo "include /etc/snort/rules/community.rules" >> /etc/snort/snort.conf && \
    sed -i 's/WHITE\_LIST\_PATH \.\.\/rules/WHITE\_LIST\_PATH \/etc\/snort\/rules/' /etc/snort/snort.conf && \
    sed -i 's/BLACK\_LIST\_PATH \.\.\/rules/BLACK\_LIST\_PATH \/etc\/snort\/rules/' /etc/snort/snort.conf 

ENV HOME_NET "[10.0.0.0/8,172.16.0.0/12,192.168.0.0/16]"

ENV INTERFACE eth0

RUN sed -i "s|ipvar HOME\_NET any|ipvar HOME\_NET $HOME_NET|" /etc/snort/snort.conf

COPY kickstart.sh /usr/local/bin/

RUN chmod +rx /usr/local/bin/kickstart.sh