laravel-docker
===

Docker image with tools for building Laravel projects, created for use in GitLab CI builds.

Images are automatically updated twice a month (`0 4 1,15 * *`).

Tags
---

Tag                 | PHP version   | Node.js version
--------------------|---------------|-------------------
latest              | Latest (8.2)  | Latest LTS (18)
php8.0              | 8.0           | Latest LTS (18)
php8.1              | 8.1           | Latest LTS (18)
php8.2              | 8.2           | Latest LTS (18)
node14              | Latest (8.2)  | 14
node16              | Latest (8.2)  | 16
node18              | Latest (8.2)  | 18
node19              | Latest (8.2)  | 19
php8.0-node14       | 8.0           | 14
php8.0-node16       | 8.0           | 16
php8.0-node18       | 8.0           | 18
php8.0-node19       | 8.0           | 19
php8.1-node14       | 8.1           | 14
php8.1-node16       | 8.1           | 16
php8.1-node18       | 8.1           | 18
php8.1-node19       | 8.1           | 19
php8.2-node14       | 8.2           | 14
php8.2-node16       | 8.2           | 16
php8.2-node18       | 8.2           | 18
php8.2-node19       | 8.2           | 19

All images are based on the [library/php:`version`-apache](https://github.com/docker-library/php) images. No other variants are available.

### Alternate branches/\[git\] tags

Alternate branches are pushed to the branch/tag name prefixed by `ref-`. For example, builds for the branch `test` will be pushed to the \[registry\] tag `ref-test`. Alternate branches are only built with the latest version of PHP and the latest LTS version of Node.js.

Registry
---

All images (except alternate branches) are pushed to `https://registry.fancy.org.uk` and `https://index.docker.io`.

Usage as a build step
---

This image should include all extensions commonly used by Laravel. It is not designed to be used to run Laravel apps in production. You should use this image for development or to run tests, or use it in a build stage in your application's own Dockerfile.

<details><summary>Example Dockerfile</summary>

This Dockerfile updates the search path so you can run Artisan commands like `docker run --rm your-app-image artisan ...` (or `docker exec -it your-app-container artisan ...` to use an existing container).

```dockerfile
FROM registry.fancy.org.uk/samuel/laravel-docker:latest as build

WORKDIR /app
COPY . /app

# Install Composer dependencies
RUN composer install

# Compile all Blade and Twig templates and cache routes
RUN php artisan view:cache && \
    # Uncommect the next two lines if you are using TwigBridge
    # php artisan twig:lint && \
    # php artisan twig:cache && \
    php artisan route:cache

# Publish files from dependencies
# RUN php artisan telescope:publish
# RUN php artisan horizon:publish

# Build static files
# This is done in a separate stage so the image does not include node_modules
FROM build as build-frontend
RUN npm install
RUN npm run production

FROM php:8.2-apache

# Install required PHP extensions
# Only install extensions your app uses
RUN --mount=target=/usr/local/bin/install-php-extensions,source=/usr/local/bin/install-php-extensions,from=build \
    install-php-extensions pdo_mysql zip intl gd bz2 opcache gmp pcntl bcmath

# Enable the headers and rewrite Apache extensions
RUN a2enmod headers && \
    a2enmod rewrite

WORKDIR /app
ENV PATH=/app:$PATH

# Copy files from the build stage
COPY --from=build /app /app
COPY --from=build-frontend /app/public/build /app/public/build

# Link public directories and set file permissions
RUN rm -rf /var/www/html && \
    ln -s /app/public /var/www/html &&
    chown -R www-data:www-data /app/storage && \
    chown -R www-data:www-data /app/bootstrap/cache && \
    php artisan storage:link

# Run config:cache when starting the image
RUN echo "#!/bin/sh" > /usr/bin/docker-entrypoint.sh && \
    echo "php artisan config:cache" > /usr/bin/docker-entrypoint.sh && \
    echo "exec \$@" > /usr/bin/docker-entrypoint.sh && \
    chmod +x /usr/bin/docker-entrypoint.sh

ENTRYPOINT [ "/usr/bin/docker-entrypoint.sh" ]

VOLUME /app/storage
```

</details>

<details><summary>Example .docker-compose.yml</summary>

```yaml
version: '3'

services:
  db:
    image: mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: laravel
      MYSQL_ROOT_PASSWORD: laravel
    networks:
      - internal
    volumes:
      - mysql-data:/var/lib/mysql

  redis:
    image: redis:alpine
    restart: unless-stopped
    networks:
      - internal
    volumes:
      - redis-data:/data

  web:
    build: .
    restart: unless-stopped
    env_file: .env
    depends_on:
      - db
      - redis
    networks:
      - default
      - internal
    ports:
      # [address]:[port]:80
      - "127.0.0.1:8080:80"
    volumes:
      - app-storage:/app/storage

  # Remove this service and uncomment the horizon service if you are using Laravel Horizon
  queue-worker:
    build: .
    restart: unless-stopped
    command: artisan queue:work
    env_file: .env
    deploy:
      mode: replicated
      replicas: 8
    depends_on:
      - db
      - redis
    networks:
      - default
      - internal
    volumes:
      - app-storage:/app/storage

  # horizon:
  #   build: .
  #   restart: unless-stopped
  #   command: artisan horizon
  #   env_file: .env
  #   depends_on:
  #     - db
  #     - redis
  #   networks:
  #     - default
  #     - internal
  #   volumes:
  #     - app-storage:/app/storage

  scheduler:
    build: .
    restart: unless-stopped
    command: |
      echo "while [ true ]
      do
          ./artisan schedule:run --verbose --no-interaction &
          sleep 60
      done" | bash
    env_file: .env
    depends_on:
      - db
      - redis
    networks:
      - default
      - internal
    volumes:
      - app-storage:/app/storage

volumes:
  mysql-data:
  redis-data:
  app-storage:

networks:
  internal:
    internal: true
```

</details>
