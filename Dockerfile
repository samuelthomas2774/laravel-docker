ARG PHP_VERSION=8.0

# Set the base image for subsequent instructions
FROM php:$PHP_VERSION-apache

ARG NODE_VERSION=14

ADD --chown=root:root nodesource.gpg /etc/apt/keyrings/nodesource.gpg

# Update packages
RUN apt-get update && \
    # Install gnupg, which is required for NodeSource
    apt-get install gnupg -y && \
    # Add NodeSource
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    # Add install-php-extensions
    curl -L -o /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    # Install PHP and composer dependencies
    apt-get install -qq git curl nodejs && \
    # Clear out the local repository of retrieved package files
    apt-get clean

# Install needed extensions
# Here you can install any other extension that you need during the test and deployment process
RUN install-php-extensions pdo_mysql zip intl gd bz2 opcache gmp pcntl bcmath

# Install & enable Xdebug for code coverage reports
RUN pecl install xdebug && \
    docker-php-ext-enable xdebug

# Install Composer
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
