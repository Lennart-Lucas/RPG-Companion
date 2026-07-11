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

$backendRoot = Split-Path $PSScriptRoot -Parent
$localFile = Join-Path $backendRoot ".deploy.local"

$deployHost = $env:DEPLOY_HOST
$user = $env:DEPLOY_USER
$sshKeyPath = $env:DEPLOY_SSH_KEY_PATH

if (Test-Path $localFile) {
    $fileValues = Read-DeployLocalFile -Path $localFile
    if (-not $deployHost) { $deployHost = $fileValues["DEPLOY_HOST"] }
    if (-not $user) { $user = $fileValues["DEPLOY_USER"] }
    if (-not $sshKeyPath) { $sshKeyPath = $fileValues["DEPLOY_SSH_KEY_PATH"] }
}

if (-not $user) { $user = "root" }
if (-not $deployHost) {
    throw "Set DEPLOY_HOST in Backend/.deploy.local first."
}
if (-not $sshKeyPath) {
    $sshKeyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519"
}
if (-not (Test-Path $sshKeyPath)) {
    throw "SSH private key not found: $sshKeyPath"
}

$pubPath = "$sshKeyPath.pub"
if (-not (Test-Path $pubPath)) {
    throw "Public key not found: $pubPath"
}

$pubKey = (Get-Content $pubPath -TotalCount 1).Trim()
$fingerprint = (ssh-keygen -lf $pubPath 2>$null | ForEach-Object { ($_ -split '\s+')[1] })
$serverCommand = @"
chmod 700 /root
install -d -m 700 /root/.ssh
KEY='$pubKey'
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
grep -qxF "`$KEY" /root/.ssh/authorized_keys || printf '%s\n' "`$KEY" >> /root/.ssh/authorized_keys
echo '--- authorized_keys (must be one line per key) ---'
cat -A /root/.ssh/authorized_keys
echo '--- fingerprints (expect $fingerprint for your key) ---'
ssh-keygen -lf /root/.ssh/authorized_keys
"@

Write-Host "SSH access setup for ${user}@${deployHost}"
Write-Host "Private key: $sshKeyPath"
if ((Get-Content $sshKeyPath -TotalCount 3) -match 'bcrypt|aes256') {
    Write-Host "Note: this key has a passphrase. If deploy still fails after server setup,"
    Write-Host "run: Start-Service ssh-agent; ssh-add `"$sshKeyPath`""
}
Write-Host ""
Write-Host "1) Open your VPS web console (DigitalOcean: Droplet -> Access -> Launch Droplet Console)."
Write-Host "2) Log in as root."
Write-Host "3) Paste and run this entire block:"
Write-Host ""
Write-Host $serverCommand
Write-Host ""

try {
    Set-Clipboard -Value $serverCommand
    Write-Host "Server commands copied to clipboard."
}
catch {
    Write-Host "Could not copy to clipboard; copy the block above manually."
}

Write-Host ""
$answer = Read-Host "Press Enter after running the commands on the server (or type q to quit)"
if ($answer -eq "q") {
    exit 0
}

$ssh = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $ssh) {
    throw "OpenSSH client (ssh) not found. Install it, then rerun this script."
}

Write-Host "Testing SSH key..."
if (Test-SshKeyEncrypted -SshKeyPath $sshKeyPath) {
    $service = Get-Service ssh-agent -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne "Running") {
        Start-Service ssh-agent
    }
    $fingerprint = (ssh-keygen -lf $pubPath 2>$null | ForEach-Object { ($_ -split '\s+')[1] })
    $agentList = ssh-add -l 2>$null
    if ($LASTEXITCODE -ne 0 -or ($fingerprint -and $agentList -notmatch [regex]::Escape($fingerprint))) {
        Write-Host "SSH key requires a passphrase. Enter it when prompted..."
        ssh-add $sshKeyPath
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add SSH key to agent."
        }
    }
}

& $ssh.Source -i $sshKeyPath -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new "${user}@${deployHost}" "echo connected"
if ($LASTEXITCODE -ne 0) {
    throw "SSH still failed. Verify the public key was appended on the server."
}

Write-Host ""
Write-Host "SSH access works. Run deploy with:"
Write-Host "  .\scripts\deploy-remote.ps1"
