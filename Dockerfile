FROM ubuntu:16.04

RUN apt-get update
RUN apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev libpcap-dev\
    build-essential autoconf automake libtool libnet1-dev \
    libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 \
    make flex bison git wget libmagic-dev pkg-config libnuma-dev strace \
    perl libio-socket-ssl-perl libcrypt-ssleay-perl ca-certificates libwww-perl \
    python-pip python-pcapy python-dpkt supervisor openssh-server net-tools \
    iputils-ping

# Fetch source
RUN cd /usr/local/src && \
    wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz && \
    tar xzf daq-2.0.6.tar.gz && \
    cd /usr/local/src && \
    wget https://www.snort.org/downloads/snort/snort-2.9.9.0.tar.gz && \
    tar xzf snort-2.9.9.0.tar.gz && \
    cd /usr/local/src && \
    wget https://github.com/dugsong/libdnet/archive/libdnet-1.12.tar.gz  && \
    tar xzf libdnet-1.12.tar.gz

# Build DAQ
RUN cd /usr/local/src/daq-* && \
    ldconfig -v && \
    ./configure && \
    make && \
    make install

RUN echo "/opt/daq/lib/daq" > /etc/ld.so.conf.d/daq.conf && \
    ldconfig && \
    PATH="/opt/daq/bin:$PATH"


# Build libdnet
RUN cd /usr/local/src/libdnet-libdnet-* && \
    ./configure --prefix=/opt/snort "CFLAGS=-fPIC" && \
    make && \
    make install && \
    echo "/opt/snort/lib" > /etc/ld.so.conf.d/snort.conf && \
    cp /opt/snort/lib/libdnet.1.0.1 /opt/snort/lib/libdnet.so.1.0.1 && \
    ldconfig -v

# Build snort
RUN cd /usr/local/src/snort-* && \
    ./configure \
        --with-dnet-includes=/opt/snort/include \
        --with-dnet-libraries=/opt/snort/lib && \
    make && \
    make install && \
    PATH="/opt/snort/bin:$PATH" && \
    ldconfig && \
    groupadd snort && \
    useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort && \
    mkdir /etc/snort /etc/snort/rules /usr/local/lib/snort_dynamicrules /var/log/snort && \
    touch /etc/snort/rules/white_list.rules /etc/snort/rules/black_list.rules /etc/snort/rules/local.rules && \
    chmod -R 5775 /etc/snort /var/log/snort /usr/local/lib/snort_dynamicrules && \
    chown -R snort:snort /etc/snort /var/log/snort /usr/local/lib/snort_dynamicrules && \
    cp /usr/local/src/snort-2.9.9.0/etc/*.conf* /etc/snort && \
    cp /usr/local/src/snort-2.9.9.0/etc/*.map /etc/snort && \
    ln -s /usr/local/bin/snort /usr/sbin/snort

RUN pip install pygeoip dnif idstools

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
    sed -i 's/BLACK\_LIST\_PATH \.\.\/rules/BLACK\_LIST\_PATH \/etc\/snort\/rules/' /etc/snort/snort.conf && \
    sed -i -e '0,/\# output unified2/{//i\output unified2\: filename snort\.u2\, limit 50' -e '}' /etc/snort/snort.conf

ENV HOME_NET "[10.0.0.0/8,172.16.0.0/12,192.168.0.0/16]"

ENV INTERFACE eth0

RUN sed -i "s|ipvar HOME\_NET any|ipvar HOME\_NET $HOME_NET|" /etc/snort/snort.conf && \
    mkdir /usr/local/lookups && \
    cd /usr/local/lookups && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && \
    wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz && \
    gunzip GeoLiteCity.dat.gz GeoIPASNum.dat.gz

RUN cd /usr/local/src/ && \
    wget http://rules.emergingthreats.net/open/snort-2.9.0-enhanced/emerging.rules.tar.gz && \
    tar -zxvf emerging.rules.tar.gz && \
    cd rules && \
    cp * /etc/snort/rules && \
    sed -i 's/\#include/include/' /etc/snort/rules/emerging.conf && \
    sed -i 's/\$RULE\_PATH/\/etc\/snort\/rules/' /etc/snort/rules/emerging.conf && \
    sed -i '/\-BLOCK/d' /etc/snort/rules/emerging.conf && \
    cat /etc/snort/rules/emerging.conf >> /etc/snort/snort.conf

RUN cd /usr/local/src/ && \
    wget https://github.com/dnif/snort-agent/archive/0.8.tar.gz && \
    tar -zxvf 0.8.tar.gz && \
    mv snort-agent-* snort-agent

# Setting up ssh on host
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY kickstart.sh /usr/local/bin/
RUN chmod +rx /usr/local/bin/kickstart.sh
CMD ["/bin/bash", "/usr/local/bin/kickstart.sh"]
ADD VERSION .
CMD ["/usr/bin/supervisord"]
