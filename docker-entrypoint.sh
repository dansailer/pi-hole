#!/bin/bash
set -e

if [ "$1" = 'pihole' ]; then
    pihole -a -p "${WEBPASSWORD}"
    service lighttpd start
    service cron start
    service dnsmasq start
    pihole updateGravity &
    tail -F /var/log/lighttpd/*.log /var/log/pihole.log
else
    exec "$@"
fi
