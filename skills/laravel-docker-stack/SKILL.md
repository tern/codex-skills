---
name: laravel-docker-stack
description: Build a Docker-based local Laravel development environment in the current folder with Ubuntu 24.04, Nginx, PHP-FPM, MySQL, and phpMyAdmin. Use when the user wants to create or bootstrap a PHP or Laravel project folder, asks for an Ubuntu 24.04 web stack, wants Nginx+PHP+MySQL in Docker, wants phpMyAdmin added, wants Laravel Breeze installed, wants SQL initialization files auto-imported, or wants multi-site or custom-port support in the local stack.
---

# Laravel Docker Stack

Create a Docker Compose stack in the current folder instead of modifying the host machine directly.

This version is currently implemented and validated on Windows 11 only.

Do not assume the workflow is already verified on Ubuntu or other Linux distributions.

If future work adds Ubuntu or other Linux package and host-environment support, expand this skill then.

Prefer this layout:

- `docker-compose.yml`
- `.docker/web/Dockerfile`
- `.docker/web/default.conf`
- `.docker/web/sites/`
- `.docker/web/start.sh`
- `.env.example`
- `.env`
- `.docker/mysql/initdb/`
- `www/`

Use these service defaults:

- `web`: build from `ubuntu:24.04`
- `db`: `mysql:8.4`
- `phpmyadmin`: `phpmyadmin:5-apache`

Use these port defaults unless the folder already uses them:

- app: `8080`
- phpMyAdmin: `8081`
- MySQL: `33060`

## Build The Stack

Create a `web` container that installs:

- `nginx`
- `php8.3-fpm`
- `php8.3-cli`
- `php8.3-mysql`
- `php8.3-mbstring`
- `php8.3-xml`
- `php8.3-curl`
- `php8.3-zip`
- `php8.3-gd`
- `php8.3-bcmath`
- `composer`
- `git`
- `curl`
- `unzip`
- `tzdata`

Run `php-fpm8.3 -D` and then `nginx -g 'daemon off;'` from `start.sh`.

Mount `./www` into `/var/www/html`.

Configure the database service with:

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD`

Add a MySQL health check with `mysqladmin ping`.

Configure phpMyAdmin with:

- `PMA_HOST=db`
- `PMA_PORT=3306`
- `PMA_USER=root`
- `PMA_PASSWORD=${MYSQL_ROOT_PASSWORD}`
- `PMA_ARBITRARY=0`

## Configure Nginx

If the folder is a plain PHP project, point Nginx root to `/var/www/html`.

If the folder is a Laravel project, point Nginx root to `/var/www/html/public` and use:

```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}

location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.3-fpm.sock;
}
```

If the user wants multiple sites, do not overload one config file. Create one Nginx server file per site under `.docker/web/sites/` and copy them into `/etc/nginx/sites-available/` during image build. Keep one exposed host port per site in `docker-compose.yml`.

For multi-site Laravel stacks, prefer a structure like:

- `sites/admin/public`
- `sites/app/public`

Map each site root explicitly in its own server config and expose separate ports such as `8080`, `8082`, `8083`.

## Bootstrap Laravel

If the user asks to create a Laravel project:

1. Rebuild the `web` image after adding Composer and Laravel-required PHP extensions.
2. Run `composer create-project laravel/laravel .` inside `www/`.
3. Run `php artisan key:generate`.
4. Update `www/.env` and `www/.env.example` to use MySQL:
   - `DB_CONNECTION=mysql`
   - `DB_HOST=db`
   - `DB_PORT=3306`
   - `DB_DATABASE=app`
   - `DB_USERNAME=app`
   - `DB_PASSWORD=app1234`
5. For a new local setup, prefer:
   - `SESSION_DRIVER=file`
   - `CACHE_STORE=file`
   - `QUEUE_CONNECTION=sync`
6. Set `APP_URL=http://localhost:8080`.
7. Run:
   - `php artisan config:clear`
   - `php artisan cache:clear`
   - `php artisan migrate --force`

If the user asks for Laravel Breeze:

1. Run `composer require laravel/breeze --dev`.
2. Prefer `php artisan breeze:install blade` unless the user asks for Vue, React, or API-only auth.
3. Run `npm install`.
4. Run `npm run build`.
5. Run `php artisan migrate --force`.
6. Verify the login and register routes render successfully.

If Node.js is not already present in the `web` image, add `nodejs` and `npm` to the image before installing Breeze.

## Add phpMyAdmin

If the user asks for phpMyAdmin, add the `phpmyadmin` service by default rather than making it optional scaffolding only. Expose it on `8081` unless that port conflicts.

Tell the user:

- URL
- server name
- username
- password

## Import SQL Automatically

If the user wants SQL initialization:

1. Create `.docker/mysql/initdb/`.
2. Put `.sql`, `.sql.gz`, or `.sh` initialization files there.
3. Mount that folder into `/docker-entrypoint-initdb.d` on the MySQL container.
4. Warn that MySQL only auto-runs those files on first initialization of a fresh data volume.

If a volume already exists and the user still wants the SQL applied:

- ask whether to import into the running database or recreate the volume
- prefer non-destructive import unless the user explicitly asks to reset data

If importing into a running database, use `docker compose exec -T db mysql ... < file.sql` and report which database the import targeted.

## Support Custom Ports

If the user asks for custom ports:

- expose them through `.env`
- keep `docker-compose.yml` reading values like `${WEB_PORT}`, `${PHPMYADMIN_PORT}`, `${DB_PORT}`
- update `APP_URL` and any per-site URLs to match the chosen ports

If the user does not specify ports, use the defaults from `references/defaults.md`.

## Support Multiple Sites

If the user asks for multiple sites in one stack:

1. Decide whether they want multiple Laravel apps, multiple plain PHP sites, or a mix.
2. Create a separate document root per site.
3. Create a separate Nginx config file per site.
4. Expose a unique host port per site from Compose.
5. Document each site URL clearly in the final response.

Prefer one `web` container with multiple Nginx server blocks unless the user specifically asks for isolated containers per site.

## Fix Common Failure Modes

If Docker commands fail because the daemon is unavailable:

- Check whether Docker Desktop is installed.
- Launch Docker Desktop if needed.
- Re-run `docker version` or `docker compose ps` with elevated permissions if the pipe is permission-gated.

If Laravel returns `500` immediately after creation:

- Inspect `www/.env`.
- Do not leave a fresh app on `SESSION_DRIVER=database` and `CACHE_STORE=database` unless the required tables already exist and the connection is valid.
- Clear config and cache after changing `.env`.

If Laravel hangs or Nginx shows FastCGI upstream timeout:

- Check `storage`, `storage/logs`, and `bootstrap/cache` permissions.
- Ensure those directories are writable from PHP-FPM.
- A pragmatic local-dev fallback is `chmod -R 777 storage bootstrap/cache`.

If Breeze assets are missing or auth pages render without styles:

- verify `node` and `npm` exist in the `web` container
- re-run `npm install`
- run `npm run build`

If SQL initialization did not run:

- verify the init files are mounted into `/docker-entrypoint-initdb.d`
- check whether the MySQL data volume already existed before container creation
- explain that old volumes skip first-run init scripts

If a custom port or multi-site URL does not respond:

- inspect `docker compose ps`
- confirm the port mapping exists
- confirm the matching Nginx server block listens on port `80` inside the container and is routed from the host port in Compose

## Validate

After changes, verify in this order:

1. `docker compose config`
2. `docker compose up -d --build`
3. `docker compose ps`
4. `Invoke-WebRequest http://localhost:8080`
5. `Invoke-WebRequest http://localhost:8081` if phpMyAdmin is enabled
6. `docker compose exec -T web php artisan --version` if Laravel was created
7. `docker compose exec -T web php artisan route:list` if Breeze was installed
8. verify each custom site URL if multiple sites were added
9. verify imported tables exist if SQL initialization was requested

Keep responses concise and tell the user exactly which URLs and credentials to use.

Read [references/defaults.md](./references/defaults.md) for exact defaults and [references/variants.md](./references/variants.md) for Breeze, SQL init, multi-site, and custom-port patterns.
