# FROM httpd:2.4-alpine AS giftsanity-dev

# RUN set -x \
   # && runDeps=' \
      # perl \
      # opensp \
      # ca-certificates \
   # ' \
   # && apk add --no-cache --virtual .build-deps \
      # perl-dev \
      # libc-dev \
      # opensp-dev \
      # gcc \
      # g++ \
      # make \
      # libxml2-dev \
      # zlib-dev \
      # git \
      # tar \
      # wget \
   # \
   # && perl -MCPAN -e 'install HTML::Tidy' \
   # && wget --quiet http://mirror.intergrid.com.au/apache/perl/mod_perl-2.0.10.tar.gz \
   # && tar -zxvf mod_perl-2.0.10.tar.gz \
   # && rm mod_perl-2.0.10.tar.gz \
   # && cd mod_perl-2.0.10 \
   # && perl Makefile.PL MP_AP_PREFIX=/usr/local/apache2 \
   # && make \
   # && make install \
   # && cd .. \
   # && rm -Rf mod_perl-2.0.10 \
   # && mkdir -p /usr/local \
   # && echo 'LoadModule perl_module modules/mod_perl.so' >> /usr/local/apache2/conf/httpd.conf \
   # && sed 's/#LoadModule rewrite_module/LoadModule rewrite_module/' -i /usr/local/apache2/conf/httpd.conf \
   # && sed 's/#LoadModule expires_module/LoadModule expires_module/' -i /usr/local/apache2/conf/httpd.conf \
   # && sed 's/#LoadModule cgid_module/LoadModule cgid_module/' -i /usr/local/apache2/conf/httpd.conf \
   # && sed 's/#LoadModule cgi_module/LoadModule cgi_module/' -i /usr/local/apache2/conf/httpd.conf \
   # && sed 's/#LoadModule include_module/LoadModule include_module/' -i /usr/local/apache2/conf/httpd.conf \
   # && sed 's/#LoadModule deflate_module/LoadModule deflate_module/' -i /usr/local/apache2/conf/httpd.conf \
   # && sed 's/#LoadModule negotiation_module/LoadModule negotiation_module/' -i /usr/local/apache2/conf/httpd.conf \
   # && apk add --virtual .validator-rundeps $runDeps \
# && apk del .build-deps
# 
## RUN apk add apache2
## Add mod_perl build dependencies
#RUN set -x \
#    && apk add make gcc perl-dev
##  Fetch mod_perl source, build and install it
##  Note: The fetch URL should be adjusted to point to a local mirror
#ADD http://mirror.intergrid.com.au/apache/perl/mod_perl-2.0.10.tar.gz mod_perl-2.0.10.tar.gz
#RUN set -x \
#    && ln -s /usr/lib/x86_64-linux-gnu/libgdbm.so.3.0.0 /usr/lib/libgdbm.so \
#    && tar -zxvf mod_perl-2.0.10.tar.gz \
#    && rm mod_perl-2.0.10.tar.gz \
#    && cd mod_perl-2.0.10 \
#    && perl Makefile.PL MP_AP_PREFIX=/usr/local/apache2 \
#    && make \
#    && make install
#
## Remove mod_perl build dependencies
#RUN set -x \
#    && rm -r mod_perl-2.0.10  \
#    && apt-get purge -y --auto-remove make gcc libperl-dev \
#    && rm -rf /var/lib/apt/lists/*

# RUN apk add openrc --no-cache

# RUN mkdir -p /var/log/apache2
# ENV APACHE_LOG_DIR /var/log/apache2


FROM httpd:latest AS giftsanity-dev
# Add mod_perl build dependencies
RUN set -x \
    && apt-get update \
    && apt-get install -y libfile-spec-native-perl make gcc wget libperl-dev


# Fetch mod_perl source, build and install it
# Note: The fetch URL should be adjusted to point to a local mirror
RUN wget -O mod_perl-2.0.10.tar.gz http://mirror.intergrid.com.au/apache/perl/mod_perl-2.0.10.tar.gz
RUN set -x \
    && ln -s /usr/lib/x86_64-linux-gnu/libgdbm.so.3.0.0 /usr/lib/libgdbm.so \
    && tar -zxvf mod_perl-2.0.10.tar.gz \
    && rm mod_perl-2.0.10.tar.gz \
    && cd mod_perl-2.0.10 \
    && perl Makefile.PL MP_AP_PREFIX=/usr/local/apache2 \
    && make \
    && make install
# RUN wget -O mod_perl-1.31.tar.gz http://mirror.ventraip.net.au/apache/perl/mod_perl-1.31.tar.gz
# RUN apt-get install -y apache2-dev
# RUN apt-get source apache2
# RUN set -x \
    # && ln -s /usr/lib/x86_64-linux-gnu/libgdbm.so.3.0.0 /usr/lib/libgdbm.so \
    # && tar -zxvf mod_perl-1.31.tar.gz \
    # && rm mod_perl-1.31.tar.gz \
    # && cd mod_perl-1.31 \
    # && perl Makefile.PL MP_AP_PREFIX=/usr/local/apache2 \
    # && make \
    # && make install
# RUN apt-get install -y libapache2-mod-perl2


## Remove mod_perl build dependencies
#RUN set -x \
#    && rm -r mod_perl-2.0.10  \
#    && apt-get purge -y --auto-remove make gcc libperl-dev \
#    && rm -rf /var/lib/apt/lists/*

# ENV PERL5LIB /usr/share/perl/5.24
RUN perl -MCPAN -e "install 'YAML'"
RUN perl -MCPAN -e "install 'Apache2_4::AuthCookie'" \
    && perl -MCPAN -e "install 'Apache::DBI'" \
    && perl -MCPAN -e "install 'Digest::SHA1'" \
    && perl -MCPAN -e "install 'Digest::SHA1::sha1_hex'" \
    && perl -MCPAN -e "install 'HTML::Entities'"

RUN perl -MCPAN -e "install 'HTML::Mason'"

RUN apt-get install -y mysql-client
RUN apt-get install -y vim
# ENV APACHE_RUN_USER  www-data
# ENV APACHE_RUN_GROUP www-data
# ENV APACHE_LOG_DIR   /var/log/apache2
# ENV APACHE_PID_FILE  /var/run/apache2/apache2.pid
# ENV APACHE_RUN_DIR   /var/run/apache2
# ENV APACHE_LOCK_DIR  /var/lock/apache2
# ENV APACHE_LOG_DIR   /var/log/apache2

# RUN mkdir -p $APACHE_RUN_DIR
# RUN mkdir -p $APACHE_LOCK_DIR
# RUN mkdir -p $APACHE_LOG_DIR

# COPY apache2.conf /usr/local/apache2/conf/httpd.conf
COPY --chown=root:www-data httpd.conf /usr/local/apache2/conf
COPY --chown=root:www-data sites-enabled /usr/local/apache2/sites-enabled
COPY --chown=root:www-data src /srv/www/presents
RUN chown -R root:www-data /srv
RUN mkdir -p /var/cache/mason/presents
RUN chmod 777 /var/cache/mason/presents

ENV env production
# CMD ["/bin/bash"]
# CMD ["/usr/local/sbin/apache2", "-D",  "FOREGROUND"]
CMD ["/usr/local/bin/httpd-foreground"]
# RUN rc-update add apache2

# ENTRYPOINT ["tail", "-f", "/dev/null"]

FROM giftsanity-dev AS giftsanity-production
