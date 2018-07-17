FROM ubuntu:16.04
MAINTAINER Jim Gwynn jim.gwynn@bakStaaJ.com

RUN apt-get update \
   && apt-get -y remove sendmail \
   && DEBIAN_FRONTEND=noninteractive apt-get -y install curl build-essential ntp ssmtp unixodbc-dev libvpb1 libssl-dev libsrtp0-dev nano sox libsox-fmt-mp3 awscli

COPY ./mysql-connector-odbc-5.3.10-linux-ubuntu16.04-x86-64bit.tar.gz /tmp/

RUN cd /tmp \
    && tar -xvf  mysql-connector-odbc-5.3.10-linux-ubuntu16.04-x86-64bit.tar.gz \
    && cd  mysql-connector-odbc-5.3.10-linux-ubuntu16.04-x86-64bit \
    && cp lib/libmyodbc*.so /usr/lib/x86_64-linux-gnu/odbc/ \
    && bin/myodbc-installer -d -a -n "MySQL" -t "DRIVER=/usr/lib/x86_64-linux-gnu/odbc/libmyodbc5w.so;" \
    && cd /tmp \
    && rm -rf *

RUN cd /tmp \
    && curl http://usecallmanager.nz/includes/cisco-usecallmanager-13.21.0.patch -o /tmp/cisco-usecallmanager-13.21.0.patch \
    && curl http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz -o /tmp/asterisk-13-current.tar.gz

RUN cd /tmp \
    && tar -xvzf /tmp/asterisk-13-current.tar.gz \
    && rm -v /tmp/asterisk-13-current.tar.gz \
    && mv /tmp/asterisk-13* /tmp/asterisk \
    && echo Y | /tmp/asterisk/contrib/scripts/install_prereq install

RUN cd /tmp/asterisk/ \
    && patch -p1 < ../cisco-usecallmanager-13.21.0.patch

RUN cd /tmp/asterisk/ \
    && ./configure --with-pjproject-bundled \
    && make \
    && make install \
    && make samples \
    && make config


COPY ./odbc.ini /etc/
COPY ./odbcinst.ini /etc/
COPY ./ssmtp.conf /etc/ssmtp/
COPY ./groupmwi.sh /usr/bin/
COPY ./etc/ /etc/asterisk/

RUN rm -rf /usr/sbin/sendmail \
    && ln -s /usr/sbin/ssmtp /usr/sbin/sendmail

RUN mv /var/lib/asterisk/sounds/en /var/lib/asterisk/sounds/en.bak \
    && ln -s /etc/asterisk/salli/ /var/lib/asterisk/sounds/en

COPY ./aws/ /root/.aws
COPY ./entrypoint.sh /root

VOLUME ["/etc/asterisk"]

CMD ["/root/entrypoint.sh"]
