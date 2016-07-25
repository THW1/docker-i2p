FROM ubuntu:16.04
# ORG: MAINTAINER Mikal "Meeh" Villa "mikal@privacysolutions.no"
# ORG: https://github.com/PrivacySolutions/docker-i2p

# mod with Ubuntu 16.04 and auto-security updates
LABEL forkedfrom="PrivacySolutions/docker-i2p"
MAINTAINER TH

# forked differences:
# * fixing ubuntu to 16.04
# * quick&dirty: unattended upgrades added to cron.d in case of long-term running as service

RUN apt-get update && apt-get install -y unattended-upgrades && rm -rf /var/lib/apt/lists/*
RUN echo "53 01 * * * root /usr/bin/unattended-upgrade" >> /etc/cron.d/unattended-upgrade.cron

# make sure the package repository is up to date
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 67ECE5605BCF1346
RUN echo "deb http://deb.i2p2.no/ trusty main" >> /etc/apt/sources.list.d/i2p.list

RUN apt-get update
RUN apt-get -y --force-yes install i2p
RUN sed -i s/RUN_DAEMON=\"false\"/RUN_DAEMON=\"true\"/ /etc/default/i2p
RUN /etc/init.d/i2p start
RUN echo "i2cp.tcp.bindAllInterfaces=true" >> /var/lib/i2p/i2p-config/router.config
# Allows docker to NAT the port
RUN sed -i s/::1,127.0.0.1/0.0.0.0/ /var/lib/i2p/i2p-config/clients.config

# Allow persistent config
VOLUME ["/var/lib/i2p/i2p-config"]

EXPOSE 7657
EXPOSE 4444
EXPOSE 4445
CMD /etc/init.d/i2p start && tail -f /var/log/i2p/wrapper.log

# running container including restart on boot
# docker run -d --name i2p  -p 127.0.0.1: 7657:7657 -p 127.0.0.1:4444-4445:4444-4445  -v /data/docker/btsync/:/mnt/sync   --restart on-failure th/i2p:v20160725.1