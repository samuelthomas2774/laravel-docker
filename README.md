laravel-docker
===

Docker image with tools for building Laravel projects, created for use in GitLab CI builds.

Images are automatically updated twice a month (`0 4 1,15 * *`).

Tags
---

Tag                 | PHP version   | Node.js version
--------------------|---------------|-------------------
latest              | Latest (8.0)  | Latest LTS (16)
php7.4              | 7.4           | Latest LTS (16)
php8.0              | 8.0           | Latest LTS (16)
php8.1              | 8.1-rc        | Latest LTS (16)
node12              | Latest (8.0)  | 12
node14              | Latest (8.0)  | 14
node16              | Latest (8.0)  | 16
node17              | Latest (8.0)  | 17
php7.4-node12       | 7.4           | 12
php7.4-node14       | 7.4           | 14
php7.4-node16       | 7.4           | 16
php7.4-node17       | 7.4           | 17
php8.0-node12       | 8.0           | 12
php8.0-node14       | 8.0           | 14
php8.0-node16       | 8.0           | 16
php8.0-node17       | 8.0           | 17
php8.1-node12       | 8.1-rc        | 12
php8.1-node14       | 8.1-rc        | 14
php8.1-node16       | 8.1-rc        | 16
php8.1-node17       | 8.1-rc        | 17

All images are based on the [library/php:`version`-apache](https://github.com/docker-library/php) images. No other variants are available.

### Alternate branches/\[git\] tags

Alternate branches are pushed to the branch/tag name prefixed by `ref-`. For example, builds for the branch `test` will be pushed to the \[registry\] tag `ref-test`. Alternate branches are only built with the latest version of PHP and the latest LTS version of Node.js.

Registry
---

All images (except alternate branches) are pushed to `https://gitlab.fancy.org.uk:5005` and `https://index.docker.io`.

Usage as a build step
---

This image should include all extensions commonly used by Laravel. It is not designed to be used to run Laravel apps in production. You should use this image for development or to run tests, or use it in a build stage in your application's own Dockerfile.

<details><summary>Example Dockerfile</summary>

This Dockerfile updates the search path so you can run Artisan commands like `docker run --rm your-app-image artisan ...` (or `docker exec -it your-app-container artisan ...` to use an existing container).

```dockerfile
FROM gitlab.fancy.org.uk:5005/samuel/laravel-docker:latest as build

WORKDIR /app
COPY . /app

# Install Composer dependencies
RUN composer install

# Build static files
RUN npm install && \
    npm run production && \
    rm -rf node_modules

# Compile all Blade and Twig templates and cache routes
RUN php artisan view:cache && \
    # Remove the next two lines if you aren't using TwigBridge
    php artisan twig:lint && \
    php artisan twig:cache && \
    php artisan route:cache

FROM php:8.0-apache

# Install required PHP extensions
RUN curl -L -o /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    # Only install extensions your app uses
    install-php-extensions pdo_mysql zip intl gd bz2 opcache gmp pcntl bcmath && \
    # Remove install-php-extension *in the same layer* as it isn't necessary to run the app
    rm /usr/local/bin/install-php-extensions

# Enable the headers and rewrite Apache extensions
RUN a2enmod headers && \
    a2enmod rewrite

WORKDIR /app
ENV PATH=/app:$PATH

# Copy files from the build stage and link the public directory
COPY --from=build /app /app
RUN rm -rf /var/www/html && \
    ln -s /app/public /var/www/html

VOLUME /app/storage
```

</details>

<details><summary>Example .docker-compose.yml</summary>

```yaml
version: '3'

services:
    db:
        image: mysql
        restart: always
        environment:
            MYSQL_DATABASE: laravel
            MYSQL_USER: laravel
            MYSQL_PASSWORD: laravel
            MYSQL_ROOT_PASSWORD: laravel
        networks:
            - internal_network
        volumes:
            - ./storage/database:/var/lib/mysql

    redis:
        image: redis:alpine
        restart: always
        networks:
            - internal_network
        volumes:
            - ./storage/redis:/data

    web:
        build: .
        restart: always
        depends_on:
            - db
            - redis
        networks:
            - external_network
            - internal_network
        ports:
            # [address]:[port]:80
            - "127.0.0.1:8080:80"
        volumes:
            - ./.env:/app/.env
            - ./bootstrap/cache:/app/bootstrap/cache
            - ./storage:/app/storage

    # Remove this service and uncomment the horizon service if you are using Laravel Horizon
    queue-worker:
        build: .
        restart: always
        command: artisan queue:work
        deploy:
            mode: replicated
            replicas: 8
        depends_on:
            - db
            - redis
        networks:
            - external_network
            - internal_network
        volumes:
            - ./.env:/app/.env
            - ./bootstrap/cache:/app/bootstrap/cache
            - ./storage:/app/storage

    # horizon:
    #     build: .
    #     restart: always
    #     command: artisan horizon
    #     depends_on:
    #         - db
    #         - redis
    #     networks:
    #         - external_network
    #         - internal_network
    #     volumes:
    #         - ./.env:/app/.env
    #         - ./bootstrap/cache:/app/bootstrap/cache
    #         - ./storage:/app/storage

    scheduler:
        build: .
        restart: always
        command: |
            echo "while [ true ]
            do
                ./artisan schedule:run --verbose --no-interaction &
                sleep 60
            done" | bash
        depends_on:
            - db
            - redis
        networks:
            - external_network
            - internal_network
        volumes:
            - ./.env:/app/.env
            - ./bootstrap/cache:/app/bootstrap/cache
            - ./storage:/app/storage

networks:
    external_network:
    internal_network:
        internal: true
```

</details>
