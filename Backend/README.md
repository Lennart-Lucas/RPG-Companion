# RPG Companion Backend

FastAPI auth API with PostgreSQL, Alembic migrations, and Docker.

## Local development

```powershell
cd Backend
.\scripts\setup.ps1
.\scripts\dev.ps1 up
```

- API: http://localhost:8010/docs
- Health: http://localhost:8010/health
- Postgres (host): localhost:5434

## Production (local prod-like stack)

```powershell
.\scripts\setup.ps1
.\scripts\prod.ps1 up
.\scripts\prod.ps1 migrate
```

Compose project: `rpg-companion-prod`. API on host port **8010**.

## Remote server deployment

Deploy from your Windows machine to a Linux host with Docker. Credentials stay local — never committed to git.

### One-time local setup

```powershell
cd Backend
Copy-Item .deploy.local.example .deploy.local
notepad .deploy.local   # set DEPLOY_HOST and DEPLOY_PASSWORD
```

Requires **PuTTY `plink`** in PATH, or **WSL** with `sshpass` installed.

### One-time server setup

```bash
cd ~/RPG-Companion/Backend
cp .env.prod.example .env.prod
nano .env.prod          # set JWT_SECRET (and CORS_ORIGINS if needed)
docker compose -p rpg-companion-prod -f docker-compose.prod.yml up --build -d
docker compose -p rpg-companion-prod -f docker-compose.prod.yml exec api alembic upgrade head
```

### Deploy latest `main`

Push your changes to GitHub first, then:

```powershell
cd Backend
.\scripts\deploy-remote.ps1
```

Or pass credentials for this session only (not saved to disk):

```powershell
$env:DEPLOY_HOST = 'YOUR_IP'
$env:DEPLOY_PASSWORD = 'YOUR_PASSWORD'
.\scripts\deploy-remote.ps1
```

The script SSHs as `root`, runs `git fetch` + `git reset --hard origin/main`, rebuilds the prod stack, and applies migrations.

### Verify on server

```bash
curl -s http://localhost:8010/health
docker compose -p rpg-companion-prod -f docker-compose.prod.yml ps
```

## Tests

```powershell
.\.venv\Scripts\python -m pytest tests/ -v
```

Full auth tests require Postgres (e.g. `.\scripts\dev.ps1 up`).
