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
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB9660B9EB2CC88B
RUN echo "deb http://ppa.launchpad.net/i2p-maintainers/i2p/ubuntu xenial main" >> /etc/apt/sources.list.d/i2p.list

RUN apt-get update
RUN apt-get -y --force-yes install i2p
RUN sed -i s/RUN_DAEMON=\"false\"/RUN_DAEMON=\"true\"/ /etc/default/i2p
RUN /etc/init.d/i2p start
RUN echo "i2cp.tcp.bindAllInterfaces=true" >> /var/lib/i2p/i2p-config/router.config
# Allows docker to NAT the port
RUN sed -i s/::1,127.0.0.1/0.0.0.0/ /var/lib/i2p/i2p-config/clients.config
# Control I2P's port to be controlled via an envvar
#RUN sed -i "s/i2np.udp.internalPort=.*/i2np.udp.internalPort="$I2PPORT"/g" /var/lib/i2p/i2p-config/router.config &&  sed -i "s/i2np.udp.port=.*/i2np.udp.port="$I2PPORT"/g" /var/lib/i2p/i2p-config/router.config


# Allow persistent config
VOLUME ["/var/lib/i2p/i2p-config"]

EXPOSE 7657
EXPOSE 4444
EXPOSE 4445
CMD /etc/init.d/i2p start && tail -f /var/log/i2p/wrapper.log

# running container including restart on boot
# docker run -d --name i2p -p 7657:7657 -p 4444-4445:4444-4445 -p $I2PPORT -p $I2PPORT/udp --restart on-failure th/i2p:v20160725.1
# docker's port forwarding apparently only binds tcp by default
# have to forward udp in addition...
# -p 127.0.0.1:12345:12345 -p 127.0.0.1:12345:12345/udp
# remember to open ports in fw if enabled
# remember to add --ipv6 to Docker's options in /etc/default/docker
# not working ---and remember to chmod the persistent directory to be writable for all, since the container's syslog etc might be writing to it (no idea, what the containers UIDs are actually mapped on the host, but the container UIDs seem to end up with the corresponding one in the fs perms)--- host fs bind screw up with UIDs, some processes have issues writing to it/no permissions, staying with persistent data valoumes :-/