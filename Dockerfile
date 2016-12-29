# vim:set ft=dockerfile:
# Docker Image of the Raspberry Pi project Pi-Hole
# - https://github.com/pi-hole/pi-hole/
# - https://pi-hole.net
# Many inspirations based on the Docker image of
# - https://github.com/diginc/docker-pi-hole
FROM ubuntu:latest
MAINTAINER dansailer
LABEL version="1.0"
LABEL description="pi-hole.net Ubuntu based image that incorporates StevenBlack's porn gambling and fakenews \
filter list. As DNS servers OpenDNS is being used (for further optional filtering)."

# Set defaults
USER root
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    USER=root \
    WEBPASSWORD=piholeweb

# Update and prepare Ubuntu
# - Install pi-hole dependencies.
# - Move systemctl as it fails the pihole scripts. For more info see docker/docker issue #7459
# - Fix resolvconf not to use systemctl but service
# - Fix dnsmasq in docker
RUN set -x \
    && apt-get update \
    && apt-get install -y apt-utils debconf dhcpcd5 git whiptail bc cron curl dnsmasq dnsutils iproute2 iputils-ping lighttpd lsof netcat net-tools php-common php-cgi sudo unzip wget nano \
    && apt-get upgrade -y \
    && mv `which systemctl` /bin/no_systemctl \
    && sed -i 's/\/bin\/systemctl try-restart ${dnsmasq_service}/service ${dnsmasq_service} restart/p' /lib/resolvconf/dnsmasq \
    && sed -i 's/\/bin\/systemctl try-restart ${libc_service}/\/usr\/sbin\/service ${libc_service} onestatus >\/dev\/null 2>&1 && \/usr\/sbin\/service ${libc_service} restart/p' /lib/resolvconf/libc \
    && sed -i 's/\/bin\/systemctl try-restart ${named_service}/service ${named_service} restart/p' /lib/resolvconf/named \
    && sed -i 's/\/bin\/systemctl try-restart ${unbound_service}/service ${unbound_service} restart/p' /lib/resolvconf/unbound \
    && grep -q '^user=root' || echo 'user=root' >> /etc/dnsmasq.conf

# Install pi-hole and add additional block list to default list as well as fix bug in installer of debian lighttpd.conf
COPY setupVars.conf /etc/pihole/setupVars.conf
COPY pihole.crontab.daily /etc/cron.daily/pihole
COPY pihole.crontab.weekly /etc/cron.weekly/pihole
COPY docker-entrypoint.sh /
ADD https://raw.githubusercontent.com/pi-hole/pi-hole/master/automated%20install/basic-install.sh /tmp/
RUN set -x \
    && bash /tmp/basic-install.sh --unattended \
    && echo -e "\n#\n#\n# dansailer/pi-hole: Add porn gambling and fakenews filter as well\n# See \`https://github.com/StevenBlack/hosts\` for details\nhttps://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts" >> /etc/pihole/adlists.default \
    && pihole updateGravity \
    && chmod -R 755 /docker-entrypoint.sh \
    && cp /etc/.pihole/advanced/lighttpd.conf.fedora /etc/lighttpd/lighttpd.conf \
    && sed -i 's/server\.username\s*=\s*"lighttpd"/server\.username = "www-data"/g' /etc/lighttpd/lighttpd.conf \
    && sed -i 's/server\.groupname\s*=\s*"lighttpd"/server\.groupname = "www-data"/g' /etc/lighttpd/lighttpd.conf

# Cleanup installation
RUN set -x \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Define interface and start processes
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 53 53/udp
EXPOSE 80
CMD ["pihole"]

