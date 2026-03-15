# Variants

## Laravel Breeze

Prefer Blade unless the user names another stack.

Typical command sequence:

```powershell
docker compose exec -T web composer require laravel/breeze --dev
docker compose exec -T web php artisan breeze:install blade
docker compose exec -T web npm install
docker compose exec -T web npm run build
docker compose exec -T web php artisan migrate --force
```

If the user requests React or Vue, switch the Breeze installer argument accordingly.

## SQL Initialization

Use this pattern in `docker-compose.yml` for MySQL:

```yaml
volumes:
  - mysql_data:/var/lib/mysql
  - ./.docker/mysql/initdb:/docker-entrypoint-initdb.d:ro
```

Recommended usage:

- place schema or seed files in lexical order such as `001-schema.sql`, `002-seed.sql`
- keep the target database aligned with `MYSQL_DATABASE`
- mention clearly that these scripts run only on first container initialization

For importing into an existing database without destroying data, prefer:

```powershell
Get-Content .\.docker\mysql\initdb\001-schema.sql | docker compose exec -T db mysql -uapp -papp1234 app
```

## Custom Ports

Expose app settings through `.env`, for example:

```dotenv
WEB_PORT=8080
PHPMYADMIN_PORT=8081
DB_PORT=33060
ADMIN_PORT=8082
SHOP_PORT=8083
```

Reflect the chosen app port in Laravel:

```dotenv
APP_URL=http://localhost:8080
```

## Multi-Site Pattern

Prefer one web container with multiple Nginx server files when the sites share the same PHP runtime.

Example host port mappings:

```yaml
ports:
  - "${APP_PORT:-8080}:80"
  - "${ADMIN_PORT:-8082}:8082"
  - "${SHOP_PORT:-8083}:8083"
```

Example site layout:

```text
sites/
  admin/
    public/
  shop/
    public/
```

Example Nginx approach:

- keep one server block listening on `80` for the main app
- add extra server blocks listening on `8082`, `8083`, or route by hostname if the user wants local domains
- match each server block to the correct `root`

If the user wants true isolation between sites, use separate services instead of one shared `web` service.
