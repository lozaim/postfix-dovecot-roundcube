#!/bin/bash
service postfix start
service rsyslog start
service apache2 start
service dovecot start
postmap /etc/postfix/client_checks && \
postmap /etc/postfix/sender_checks && \
postfix reload
rm /etc/dovecot/conf.d/15-mailboxes.conf
service dovecot stop
/usr/sbin/dovecot -F
