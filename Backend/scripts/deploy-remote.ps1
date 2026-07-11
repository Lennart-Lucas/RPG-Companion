$ErrorActionPreference = "Stop"

function Read-DeployLocalFile {
    param([string]$Path)

    $values = @{}
    foreach ($line in Get-Content $Path) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) {
            continue
        }
        $eq = $trimmed.IndexOf("=")
        if ($eq -lt 1) {
            continue
        }
        $key = $trimmed.Substring(0, $eq).Trim()
        $value = $trimmed.Substring($eq + 1).Trim()
        $values[$key] = $value
    }
    return $values
}

function Get-DeployConfig {
    $backendRoot = Split-Path $PSScriptRoot -Parent
    $localFile = Join-Path $backendRoot ".deploy.local"

    $deployHost = $env:DEPLOY_HOST
    $password = $env:DEPLOY_PASSWORD
    $user = $env:DEPLOY_USER
    $repoPath = $env:DEPLOY_REPO_PATH

    if ((-not $deployHost -or -not $password) -and (Test-Path $localFile)) {
        $fileValues = Read-DeployLocalFile -Path $localFile
        if (-not $deployHost) { $deployHost = $fileValues["DEPLOY_HOST"] }
        if (-not $password) { $password = $fileValues["DEPLOY_PASSWORD"] }
        if (-not $user) { $user = $fileValues["DEPLOY_USER"] }
        if (-not $repoPath) { $repoPath = $fileValues["DEPLOY_REPO_PATH"] }
    }

    if (-not $user) { $user = "root" }
    if (-not $repoPath) { $repoPath = "~/RPG-Companion" }

    if (-not $deployHost) {
        throw "DEPLOY_HOST is required. Set `$env:DEPLOY_HOST or add it to .deploy.local (copy from .deploy.local.example)."
    }
    if (-not $password) {
        throw "DEPLOY_PASSWORD is required. Set `$env:DEPLOY_PASSWORD or add it to .deploy.local."
    }

    return @{
        DeployHost = $deployHost
        Password   = $password
        User       = $user
        RepoPath   = $repoPath
    }
}

function Get-RemoteDeployCommand {
    param([string]$RepoPath)

    $repoPath = $RepoPath.TrimEnd("/")
    return @"
cd $repoPath && git fetch origin && git reset --hard origin/main && cd Backend && docker compose -p rpg-companion-prod -f docker-compose.prod.yml up --build -d && docker compose -p rpg-companion-prod -f docker-compose.prod.yml exec -T api alembic upgrade head
"@
}

function Invoke-RemoteCommand {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$Password,
        [string]$RemoteCommand
    )

    $plink = Get-Command plink -ErrorAction SilentlyContinue
    if ($plink) {
        Write-Host "Using plink to connect to ${User}@${DeployHost}..."
        & plink -batch -ssh "${User}@${DeployHost}" -pw $Password $RemoteCommand
        if ($LASTEXITCODE -ne 0) {
            throw "Remote deploy failed (plink exit code $LASTEXITCODE)."
        }
        return
    }

    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wsl) {
        $sshpassCheck = wsl bash -lc "command -v sshpass" 2>$null
        if ($LASTEXITCODE -eq 0 -and $sshpassCheck) {
            Write-Host "Using WSL sshpass to connect to ${User}@${DeployHost}..."
            $escapedPassword = $Password.Replace("'", "'\\''")
            $escapedCommand = $RemoteCommand.Replace("'", "'\\''")
            wsl bash -lc "sshpass -p '$escapedPassword' ssh -o StrictHostKeyChecking=accept-new ${User}@${DeployHost} '$escapedCommand'"
            if ($LASTEXITCODE -ne 0) {
                throw "Remote deploy failed (WSL ssh exit code $LASTEXITCODE)."
            }
            return
        }
    }

    throw @"
No SSH password helper found. Install one of:
  - PuTTY plink (add to PATH), or
  - WSL with sshpass: sudo apt install sshpass
"@
}

$config = Get-DeployConfig
$remoteCommand = Get-RemoteDeployCommand -RepoPath $config.RepoPath

Write-Host "Deploying RPG-Companion backend to $($config.User)@$($config.DeployHost)..."
Write-Host "Repo path: $($config.RepoPath)"
Write-Host ""

Invoke-RemoteCommand `
    -User $config.User `
    -DeployHost $config.DeployHost `
    -Password $config.Password `
    -RemoteCommand $remoteCommand

Write-Host ""
Write-Host "Deploy finished successfully."
