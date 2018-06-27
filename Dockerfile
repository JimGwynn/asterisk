FROM phusion/baseimage:0.9.18
MAINTAINER Jim Gwynn <jim.gwynn@bakstaaj.com>

# Set environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV ASTERISKUSER asterisk

CMD ["/sbin/my_init"]

# Setup services
COPY start-asterisk.sh /etc/service/asterisk/run
RUN chmod +x /etc/service/asterisk/run

# Install Required Dependencies
RUN apt-get update \
	&& apt-get upgrade -y \
        && apt-get remove sendmail -y \
	&& apt-get install -y \
		autoconf \
		automake \
		bison \
		build-essential \
		curl \
		flex \
		git \
                ntp \
                ssmtp \
		libasound2-dev \
		libcurl4-openssl-dev \
		libical-dev \
		libmyodbc \
		libmysqlclient-dev \
		libncurses5-dev \
		libneon27-dev \
		libnewt-dev \
		libodbc1 \
		libogg-dev \
		libspandsp-dev \
		libsqlite3-dev \
		libsrtp0-dev \
		libssl-dev \
		libtool \
		libvorbis-dev \
		libxml2-dev \
		libjansson-dev \
		mpg123 \
		mysql-client \
		openssh-server \
		sox \
		subversion \
		sqlite3 \
                unixodbc \
		unixodbc-dev \
		uuid \
		uuid-dev \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Compile and install pjproject
WORKDIR /usr/src

RUN curl -sf -o pjproject.tar.bz2 -L http://www.pjsip.org/release/2.4/pjproject-2.4.tar.bz2 \
	&& tar -xjvf pjproject.tar.bz2 \
	&& rm -f pjproject.tar.bz2 \
	&& cd pjproject-2.4 \
	&& CFLAGS='-DPJ_HAS_IPV6=1' ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr \
	&& make dep \
	&& make \ 
	&& make install \
	&& rm -r /usr/src/pjproject-2.4

# Compile and Install Asterisk
WORKDIR /usr/src

RUN curl -sf -o asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-15-current.tar.gz \
	&& mkdir asterisk \
	&& tar -xzf /usr/src/asterisk.tar.gz -C /usr/src/asterisk --strip-components=1 \
	&& rm asterisk.tar.gz \
	&& cd asterisk

COPY cisco-usecallmanager-15.0.patch /usr/src/

RUN cd /usr/src/asterisk \
	&& patch -p1 -s < /usr/src/cisco-usecallmanager-15.0.patch

COPY chan_sip.c.15p /usr/src/asterisk/channels/chan_sip.c
COPY irc2pc.c.15p /usr/src/asterisk/codecs/lpc10/irc2pc.c

RUN cd /usr/src/asterisk \
        && mkdir /etc/asterisk \
	&& ./configure \
	&& contrib/scripts/get_mp3_source.sh \
	&& make menuselect.makeopts \
	&& sed -i "s/format_mp3//" menuselect.makeopts \
	&& sed -i "s/BUILD_NATIVE//" menuselect.makeopts \
	&& make \
	&& make basic-pbx \
	&& make install \
	&& make config \
	&& ldconfig \
	&& update-rc.d -f asterisk remove \
	&& rm -r /usr/src/asterisk \
	&& rm /usr/src/cisco-usecallmanager-15.0.patch

# Download extra sounds
WORKDIR /var/lib/asterisk/sounds
RUN curl -sf -o asterisk-core-sounds-en-wav-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz \
	&& tar -xzf asterisk-core-sounds-en-wav-current.tar.gz \
	&& rm -f asterisk-core-sounds-en-wav-current.tar.gz \
	&& curl -sf -o asterisk-extra-sounds-en-wav-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz \
	&& tar -xzf asterisk-extra-sounds-en-wav-current.tar.gz \
	&& rm -f asterisk-extra-sounds-en-wav-current.tar.gz \
	&& curl -sf -o asterisk-core-sounds-en-g722-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-g722-current.tar.gz \
	&& tar -xzf asterisk-core-sounds-en-g722-current.tar.gz \
	&& rm -f asterisk-core-sounds-en-g722-current.tar.gz \
	&& curl -sf -o asterisk-extra-sounds-en-g722-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz \
	&& tar -xzf asterisk-extra-sounds-en-g722-current.tar.gz \
	&& rm -f asterisk-extra-sounds-en-g722-current.tar.gz

# Add Asterisk user
RUN useradd -m $ASTERISKUSER \
	&& chown $ASTERISKUSER. /var/run/asterisk \ 
	&& chown -R $ASTERISKUSER. /etc/asterisk \
	&& chown -R $ASTERISKUSER. /var/lib/asterisk \
	&& chown -R $ASTERISKUSER. /var/log/asterisk \
	&& chown -R $ASTERISKUSER. /var/spool/asterisk \
	&& chown -R $ASTERISKUSER. /usr/lib/asterisk 

#Make CDRs work
COPY ssmtp.conf /etc/ssmtp/
COPY groupmwi.sh /usr/bin/
COPY conf/cdr/odbc.ini /etc/odbc.ini
COPY conf/cdr/odbcinst.ini /etc/odbcinst.ini
COPY conf/cdr/cdr_adaptive_odbc.conf /etc/asterisk/cdr_adaptive_odbc.conf
RUN chown asterisk:asterisk /etc/asterisk/cdr_adaptive_odbc.conf \
	&& chmod 775 /etc/asterisk/cdr_adaptive_odbc.conf \
	&& rm -rf /usr/sbin/sendmail \
        && ln -s /usr/sbin/ssmtp /usr/sbin/sendmail

WORKDIR /

#EXPOSE 50601 5000-31000/udp

VOLUME ["/etc/asterisk"]
