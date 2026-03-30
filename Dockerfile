FROM wordpress:6.5-php8.2-fpm

ENV PHP_FPM_LISTEN=9000

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx supervisor gettext-base ca-certificates default-mysql-client msmtp-mta && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/php /var/log/supervisor

# Keep runtime logs clean from plugin PHP warnings on production.
RUN printf "display_errors=Off\nlog_errors=On\nerror_reporting=E_ERROR | E_PARSE\n" > /usr/local/etc/php/conf.d/zz-production.ini

# Install WP-CLI to perform serialized-safe URL rewrites after SQL import.
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# Ensure WordPress core exists in web root.
RUN cp -a /usr/src/wordpress/. /var/www/html/

# Keep base snapshot used to restore missing core files on startup.
RUN mkdir -p /opt/base-core/wp-includes && cp -a /var/www/html/wp-includes/. /opt/base-core/wp-includes/

# Project overrides and SQL dump.
COPY wp-content /var/www/html/wp-content
COPY wp-config.php /var/www/html/wp-config.php
COPY eurotracksdb.sql /var/www/html/eurotracksdb.sql

# Snapshot for recovery if persistent disk starts empty.
RUN mkdir -p /opt/www-seed && cp -a /var/www/html/wp-content/. /opt/www-seed/wp-content/

RUN chown -R www-data:www-data /var/www/html

COPY docker/nginx.conf.template /etc/nginx/nginx.conf.template
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN if [ -f /usr/local/etc/php-fpm.d/www.conf ]; then \
      sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /usr/local/etc/php-fpm.d/www.conf; \
    fi

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
