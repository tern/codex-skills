# Defaults

## Host Support

- Current implemented and validated host OS: Windows 11
- Ubuntu and other Linux host implementations are not yet documented in this skill
- Extend this skill after those host environments are actually implemented and verified

## Ports

- App: `8080`
- phpMyAdmin: `8081`
- MySQL: `33060`

## Database Defaults

- Root password: `root`
- Database: `app`
- User: `app`
- Password: `app1234`

## Expected Layout

```text
.docker/
  mysql/
    initdb/
  web/
    Dockerfile
    default.conf
    sites/
    start.sh
.env
.env.example
docker-compose.yml
sites/
www/
```

## Verification Checklist

```powershell
docker compose config
docker compose up -d --build
docker compose ps
docker compose exec -T web php artisan --version
docker compose exec -T web php artisan route:list
```

## HTTP Checks

```powershell
(Invoke-WebRequest -UseBasicParsing http://localhost:8080).StatusCode
(Invoke-WebRequest -UseBasicParsing http://localhost:8081).StatusCode
```

## Breeze Defaults

- Installer: `php artisan breeze:install blade`
- Frontend build: `npm install` then `npm run build`

## SQL Init Rule

- First-run init dir: `.docker/mysql/initdb/`
- Container path: `/docker-entrypoint-initdb.d`
- Auto-import runs only on a fresh MySQL data volume
