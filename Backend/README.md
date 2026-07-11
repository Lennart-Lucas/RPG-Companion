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
notepad .deploy.local   # set DEPLOY_HOST and DEPLOY_SSH_KEY_PATH
```

Most VPS hosts only accept **SSH key** auth. Point `DEPLOY_SSH_KEY_PATH` at your private key (the same one you use for Companion, e.g. `C:\Users\you\.ssh\id_ed25519`). Password auth is optional and only works if the server allows it.

Requires **OpenSSH** (`ssh` on PATH), **PuTTY plink**, or **Posh-SSH**. OpenSSH is preferred for key auth on Windows 10+.

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
$env:DEPLOY_SSH_KEY_PATH = 'C:\Users\you\.ssh\id_ed25519'
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
