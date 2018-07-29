FROM alpine:3.8

WORKDIR /app

RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

RUN apk update \
    && apk add --no-cache \
        ca-certificates \
        certbot \
        composer \
        curl \
        dcron \
        nginx \
        php7 \
        php7-bcmath \
        php7-common \
        php7-ctype \
        php7-dom \
        php7-fpm \
        php7-gd \
        php7-json \
        php7-mbstring \
        php7-openssl \
        php7-pdo \
        php7-pdo_mysql \
        php7-phar \
        php7-session \
        php7-simplexml \
        php7-tokenizer \
        php7-zip \
        tini \
        wget \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY . ./

COPY .dev/docker/default.conf /etc/nginx/conf.d/default.conf

RUN cp .env.example .env && composer install --no-dev

EXPOSE 80 443

RUN chown -R www-data:www-data . && chmod -R 755 storage/* bootstrap/cache

ENTRYPOINT ["ash", ".dev/entrypoint.sh"]

