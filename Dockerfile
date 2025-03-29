FROM ubuntu:20.04
LABEL maintainer="mwaeckerlin"

# Set non-interactive mode for apt-get to avoid tzdata prompt
ENV DEBIAN_FRONTEND=noninteractive
EXPOSE 80
ENV TIMEZONE "Europe/Zurich"

RUN mkdir /sugar
WORKDIR /sugar

RUN apt-get update && \
    apt-get install -y wget unzip apache2 libapache2-mod-php7.4 php7.4-curl php7.4-gd php7.4-imap php7.4-json php7.4-mysql mysql-client && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O- -q "http://sourceforge.net/projects/sugarcrm/files/latest/download?source=files" > sugar.zip && \
    unzip sugar.zip && \
    rm sugar.zip && \
    mv * crm

RUN sed -i 's,DocumentRoot.*,DocumentRoot /sugar/crm,' /etc/apache2/sites-available/000-default.conf

RUN sed -i 's,;*\(date.timezone *=\).*,\1 "'${TIMEZONE}'",g' /etc/php/7.4/apache2/php.ini && \
    sed -i 's,;*\(display_errors *=\).*,\1 Off,g' /etc/php/7.4/apache2/php.ini && \
    sed -i 's,;*\(post_max_size *=\).*,\1 100M,g' /etc/php/7.4/apache2/php.ini && \
    sed -i 's,;*\(session.use_cookies *=\).*,\1 1,g' /etc/php/7.4/apache2/php.ini && \
    sed -i 's,;*\(upload_max_filesize *=\).*,\1 100M,g' /etc/php/7.4/apache2/php.ini && \
    sed -i 's,;*\(session.gc_maxlifetime *=\).*,\1 14400,g' /etc/php/7.4/apache2/php.ini

RUN bash -c "chown www-data:www-data crm/{.htaccess,config.php,config_override.php,sugarcrm.log}" && \
    bash -c "chown -R www-data:www-data crm/{cache,custom,data,modules,upload}"

RUN echo "<Directory /sugar/crm>" > /etc/apache2/conf-available/sugarcrm.conf && \
    echo "  Options Indexes FollowSymLinks" >> /etc/apache2/conf-available/sugarcrm.conf && \
    echo "  AllowOverride All" >> /etc/apache2/conf-available/sugarcrm.conf && \
    echo "  Require all granted" >> /etc/apache2/conf-available/sugarcrm.conf && \
    echo "</Directory>" >> /etc/apache2/conf-available/sugarcrm.conf

RUN a2enconf sugarcrm

RUN phpenmod curl imap mysql pdo gd json mysqli opcache pdo_mysql

RUN echo '*    *    *    *    *     cd /sugar/crm; php -f cron.php > /dev/null 2>&1' > /etc/cron.d/sugar

CMD cron && apache2ctl -DFOREGROUND

VOLUME /sugar
