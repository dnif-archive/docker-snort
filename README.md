# docker-snort
Snort is an open-source, free and lightweight network intrusion detection system (NIDS) software for Linux and Windows to detect emerging threats. This container is designed to run snort with standard configurations and forward logs to the DNIF Adapter (AD) over the http API.

## Sample Commands

`docker run -it -e HOME_NET=1.2.3.4 --net=host --cap-add=NET_ADMIN dnif/snort /bin/bash`