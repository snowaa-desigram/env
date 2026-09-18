# Symfony core: FrankenPHP (Caddy + PHP 8.4 ZTS)
FROM dunglas/frankenphp:1-php8.4 AS base

WORKDIR /app

# grpc собирается из исходников — первый build долгий (~10-20 мин), поэтому отдельным слоем: он кешируется,
# даже если следующий шаг упадёт. Версии пинятся (см. platform в core/composer.json).
RUN install-php-extensions grpc-1.84.0
RUN install-php-extensions protobuf-5.36.2
RUN install-php-extensions amqp redis intl opcache pdo_mysql zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    SERVER_NAME=:8080

EXPOSE 8080

# ---------- dev ----------
FROM base AS dev

RUN install-php-extensions xdebug

# XDEBUG_MODE=debug включает отладчик (порт 9003 -> host.docker.internal)
ENV APP_ENV=dev \
    XDEBUG_MODE=off \
    XDEBUG_CONFIG="client_host=host.docker.internal"

# код монтируется volume'ом, vendor доустанавливается при старте
CMD ["sh", "-c", "composer install --no-interaction && frankenphp run --config /etc/frankenphp/Caddyfile"]

# ---------- prod ----------
FROM base AS prod

ENV APP_ENV=prod

COPY composer.json composer.lock symfony.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-progress

COPY . .
RUN composer dump-autoload --no-dev --classmap-authoritative \
    && bin/console cache:warmup
