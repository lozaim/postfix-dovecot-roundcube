FROM ubuntu:20.04

ENV TZ=Europe/Kiev 
ENV DOMAINNAME=domic.com
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo "postfix postfix/main_mailer_type string Satellite system" > preseed.txt && \
	echo "postfix postfix/mailname string $DOMAINNAME" >> preseed.txt
RUN debconf-set-selections preseed.txt
RUN apt-get update && \
    apt-get install -y wget mysql-client systemd rsyslog nano \
	apache2 libapache2-mod-security2 libapache2-mod-php7.4 \
    dovecot-core dovecot-mysql dovecot-imapd dovecot-pop3d dovecot-lmtpd 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y postfix	
RUN apt-get install -y postfix-mysql postfix-policyd-spf-python \
    php7.4 php7.4-mysql php7.4-curl php7.4-gd php7.4-mbstring php7.4-imap php7.4-xml php-apcu && \
	mkdir -p /var/vmail/ && \
	groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d /var/vmail && \
	chmod 770 /var/vmail && \
	chown -R vmail:vmail /var/vmail && \
	mkdir -p /var/www/mailadmin.domic.com/html && \
	mkdir -p /var/www/mail.domic.com/html && \
    wget -q https://sourceforge.net/projects/postfixadmin/files/postfixadmin/postfixadmin-3.2/postfixadmin-3.2.tar.gz && \
    tar -C /var/www/ -xf postfixadmin-3.2.tar.gz  && \
	cp -r /var/www/postfixadmin-3.2/* /var/www/mailadmin.domic.com/html/ && \
	chown -R www-data:www-data /var/www/mailadmin.domic.com/html  && \
    wget -q https://github.com/roundcube/roundcubemail/releases/download/1.4.6/roundcubemail-1.4.6-complete.tar.gz && \
    tar -C /var/www/ -xf roundcubemail-1.4.6-complete.tar.gz  && \
	cp -r /var/www/roundcubemail-1.4.6/* /var/www/mail.domic.com/html/ && \
	chown -R www-data:www-data /var/www/mail.domic.com/html  && \
    mkdir -p /var/www/mailadmin.domic.com/html/templates_c  && \
    chown -R www-data:www-data /var/www/mailadmin.domic.com/html/templates_c  && \
    chown :syslog /var/log/ && \
    chmod 775 /var/log/ && \
	ln -s /etc/apache2/sites-available/mailadmin.domic.com.conf /etc/apache2/sites-enabled/mailadmin.domic.com.conf && \
	ln -s /etc/apache2/sites-available/mail.domic.com.conf /etc/apache2/sites-enabled/mail.domic.com.conf && \
    rm /etc/apache2/sites-enabled/000-default.conf && \
	a2enmod rewrite ssl security2 deflate expires headers
RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh
COPY --chown=vmail:dovecot dovecot /etc/dovecot
COPY postfix /etc/postfix
COPY apache2 /etc/apache2
RUN mkdir -p /var/log/apache2/ && \
    chmod -R 744 /var/log/apache2/ 
COPY --chown=www-data:www-data postfixadmin /var/www/mailadmin.domic.com/html
COPY --chown=www-data:www-data roundcube /var/www/mail.domic.com/html

##  sudo chown -R www-data:www-data /var/www/mailadmin.domic.com/html/config.local.php



VOLUME [ "/var/log/", "/var/vmail/", "/var/lib/mysql","/var/www/mail.domic.com/html/logs" ]

EXPOSE 25 80 110 143 465 993 995

ENTRYPOINT /run.sh 
