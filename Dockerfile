# ─────────────────────────────────────────────────────────────
# Dockerfile — Laravel 13 + PHP-FPM
#
# PHP 8.3 é o mínimo exigido pelo Laravel 13.
# Usamos 8.4 por padrão (versão estável atual com OPcache JIT).
# Para fixar em 8.3, basta passar --build-arg PHP_VERSION=8.3
# ─────────────────────────────────────────────────────────────
ARG PHP_VERSION=8.4

FROM php:${PHP_VERSION}-fpm

# ─────────────────────────────────────────────────────────────
# Argumentos de build (UID/GID do host para evitar problemas
# de permissão em volumes montados em ambiente local)
# ─────────────────────────────────────────────────────────────
ARG UID=1000
ARG GID=1000

# ─────────────────────────────────────────────────────────────
# Variáveis de ambiente úteis dentro do container
# ─────────────────────────────────────────────────────────────
ENV TZ=America/Sao_Paulo \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    DEBIAN_FRONTEND=noninteractive

# ─────────────────────────────────────────────────────────────
# Dependências de sistema
# - Mantemos a lista enxuta; nada de pacotes "para o caso de"
# - libpq-dev → PostgreSQL
# - libonig-dev → mbstring
# - libzip-dev → zip
# - libicu-dev → intl (formatação de datas, locales)
# - libpng-dev / libjpeg-dev / libfreetype6-dev → gd
# ─────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        unzip \
        zip \
        libpq-dev \
        libonig-dev \
        libzip-dev \
        libicu-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libxml2-dev \
        tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────
# Extensões PHP nativas
# ─────────────────────────────────────────────────────────────
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        gd \
        intl \
        opcache \
        pcntl \
        pdo_pgsql \
        pgsql \
        zip

# ─────────────────────────────────────────────────────────────
# Extensão Redis via PECL
# ─────────────────────────────────────────────────────────────
RUN pecl install redis \
    && docker-php-ext-enable redis

# ─────────────────────────────────────────────────────────────
# Composer (copiado da imagem oficial — sempre na última versão)
# ─────────────────────────────────────────────────────────────
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ─────────────────────────────────────────────────────────────
# Usuário não-root (boa prática + alinha UID com o host)
# ─────────────────────────────────────────────────────────────
RUN groupadd -g ${GID} app \
    && useradd -u ${UID} -g app -m -s /bin/bash app \
    && mkdir -p /var/www/html \
    && chown -R app:app /var/www/html

WORKDIR /var/www/html

USER app

EXPOSE 9000

CMD ["php-fpm"]
