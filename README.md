laravel-docker
===

Docker image with tools for building Laravel projects, created for use in GitLab CI builds.

Images are automatically updated twice a month (`0 4 1,15 * *`).

Tags
---

Tag                 | PHP version   | Node.js version
--------------------|---------------|-------------------
latest              | Latest (8.0)  | Latest LTS (14)
php7.4              | 7.4           | Latest LTS (14)
php8.0              | 8.0           | Latest LTS (14)
node12              | Latest (8.0)  | 12
node14              | Latest (8.0)  | 14
node16              | Latest (8.0)  | 16
php7.4-node12       | 7.4           | 12
php7.4-node14       | 7.4           | 14
php7.4-node16       | 7.4           | 16
php8.0-node12       | 8.0           | 12
php8.0-node14       | 8.0           | 14
php8.0-node16       | 8.0           | 16

All images are based on the [library/php:`version`-apache](https://github.com/docker-library/php) images. No other variants are available.

### Alternate branches/\[git\] tags

Alternate branches are pushed to the branch/tag name prefixed by `ref-`. For example, builds for the branch `test` will be pushed to the \[registry\] tag `ref-test`. Alternate branches are only built with the latest version of PHP and the latest LTS version of Node.js.

Registry
---

All images (except alternate branches) are pushed to `https://gitlab.fancy.org.uk:5005` and `https://index.docker.io`.
