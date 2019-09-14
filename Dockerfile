# Set the base image for subsequent instructions
FROM php:7.3-apache

# Update packages
RUN apt-get update && \

    # Install gnupg, which is required for NodeSource
    apt-get install gnupg -y && \

    # Upgrade to Node v12
    ( curl -sL https://deb.nodesource.com/setup_12.x | bash - ) && \

    # Install PHP and composer dependencies
    apt-get install -qq git curl libmcrypt-dev libjpeg-dev libpng-dev libfreetype6-dev libbz2-dev nodejs \
        libcurl4-gnutls-dev libicu-dev libvpx-dev libxpm-dev zlib1g-dev libxml2-dev libexpat1-dev libgmp3-dev \
        libldap2-dev unixodbc-dev libpq-dev libsqlite3-dev libaspell-dev libsnmp-dev libpcre3-dev libtidy-dev \
        libzip-dev && \

    # Clear out the local repository of retrieved package files
    apt-get clean

# Install needed extensions
# Here you can install any other extension that you need during the test and deployment process
RUN docker-php-ext-install pdo_mysql zip mbstring pdo_sqlite curl json intl gd xml bz2 opcache gmp pcntl bcmath

# Install & enable Xdebug for code coverage reports
RUN pecl install xdebug && \
    docker-php-ext-enable xdebug

# Install Composer
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
