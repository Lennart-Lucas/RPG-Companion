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

function Resolve-DeployPath {
    param(
        [string]$Path,
        [string]$BackendRoot
    )

    if (-not $Path) {
        return $null
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if ([System.IO.Path]::IsPathRooted($expanded)) {
        return $expanded
    }

    return (Join-Path $BackendRoot $expanded)
}

function Get-DefaultSshKeyCandidates {
    $userHome = $env:USERPROFILE
    if (-not $userHome) {
        return @()
    }

    $sshDir = Join-Path $userHome ".ssh"
    $names = @("id_ed25519", "id_rsa", "id_ecdsa")
    $candidates = @()
    foreach ($name in $names) {
        $path = Join-Path $sshDir $name
        if (Test-Path $path) {
            $candidates += $path
        }
    }
    return $candidates
}

function Test-SshKeyEncrypted {
    param([string]$SshKeyPath)

    $sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
    if (-not $sshKeygen) {
        return $false
    }

    $result = Invoke-ExternalCommand -Executable $sshKeygen.Source -Arguments @(
        "-y", "-P", '""', "-f", $SshKeyPath
    )
    return ($result.Output -match "incorrect passphrase|passphrase supplied")
}

function Get-SshKeyFingerprint {
    param([string]$SshKeyPath)

    $pubPath = "$SshKeyPath.pub"
    if (-not (Test-Path $pubPath)) {
        return $null
    }
    $line = ssh-keygen -lf $pubPath 2>$null
    if (-not $line) {
        return $null
    }
    return ($line -split '\s+')[1]
}

function Test-SshAgentHasKey {
    param([string]$Fingerprint)

    if (-not $Fingerprint) {
        return $false
    }
    $sshAdd = Get-Command ssh-add -ErrorAction SilentlyContinue
    if (-not $sshAdd) {
        return $false
    }

    $listed = Invoke-ExternalCommand -Executable $sshAdd.Source -Arguments @("-l")
    if ($listed.ExitCode -ne 0) {
        return $false
    }
    return ($listed.Output -match [regex]::Escape($Fingerprint))
}

function Ensure-SshAgentWithKey {
    param([string]$SshKeyPath)

    $fingerprint = Get-SshKeyFingerprint -SshKeyPath $SshKeyPath
    if ($fingerprint -and (Test-SshAgentHasKey -Fingerprint $fingerprint)) {
        return
    }

    $service = Get-Service ssh-agent -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne "Running") {
        Write-Host "Starting ssh-agent..."
        try {
            Start-Service ssh-agent -ErrorAction Stop
        }
        catch {
            throw "Could not start ssh-agent (try an elevated PowerShell): $($_.Exception.Message)"
        }
    }

    $sshAdd = Get-Command ssh-add -ErrorAction SilentlyContinue
    if (-not $sshAdd) {
        throw "SSH key has a passphrase. Install OpenSSH and run: ssh-add `"$SshKeyPath`""
    }

    Write-Host "SSH key requires a passphrase. Enter it when prompted..."
    & $sshAdd.Source $SshKeyPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to add SSH key to agent (exit code $LASTEXITCODE)."
    }
}

function Ensure-SshKeyReady {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$SshKeyPath
    )

    if (-not $SshKeyPath) {
        return
    }
    if (Test-SshKeyAuth -User $User -DeployHost $DeployHost -SshKeyPath $SshKeyPath) {
        return
    }

    Write-Host "SSH key is not ready for batch deploy; loading it into ssh-agent..."
    Ensure-SshAgentWithKey -SshKeyPath $SshKeyPath

    if (Test-SshKeyAuth -User $User -DeployHost $DeployHost -SshKeyPath $SshKeyPath) {
        return
    }

    $errorMessage = Format-PublicKeyOnlyError `
        -User $User `
        -DeployHost $DeployHost `
        -ConfiguredKeyPath $SshKeyPath
    if (Test-SshKeyEncrypted -SshKeyPath $SshKeyPath) {
        $errorMessage += [Environment]::NewLine + [Environment]::NewLine
        $errorMessage += "Your key has a passphrase. Load it manually, then rerun deploy:"
        $errorMessage += "  Start-Service ssh-agent"
        $errorMessage += "  ssh-add `"$SshKeyPath`""
    }
    throw $errorMessage
}

function Test-SshKeyAuth {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$SshKeyPath
    )

    $ssh = Get-Command ssh -ErrorAction SilentlyContinue
    if (-not $ssh) {
        return $false
    }

    $result = Invoke-ExternalCommand -Executable $ssh.Source -Arguments @(
        "-i", $SshKeyPath,
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=10",
        "-o", "StrictHostKeyChecking=accept-new",
        "${User}@${DeployHost}",
        "exit"
    )
    return ($result.ExitCode -eq 0)
}

function Resolve-WorkingSshKeyPath {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$PreferredPath
    )

    if ($PreferredPath) {
        if (-not (Test-Path $PreferredPath)) {
            throw "SSH private key not found: $PreferredPath"
        }
        if (Test-SshKeyAuth -User $User -DeployHost $DeployHost -SshKeyPath $PreferredPath) {
            return $PreferredPath
        }
        foreach ($candidate in (Get-DefaultSshKeyCandidates)) {
            if ($candidate -ne $PreferredPath -and
                (Test-SshKeyAuth -User $User -DeployHost $DeployHost -SshKeyPath $candidate)) {
                Write-Host "Configured key failed; using working key: $candidate"
                return $candidate
            }
        }
        return $PreferredPath
    }

    foreach ($candidate in (Get-DefaultSshKeyCandidates)) {
        if (Test-SshKeyAuth -User $User -DeployHost $DeployHost -SshKeyPath $candidate) {
            Write-Host "Auto-selected SSH key: $candidate"
            return $candidate
        }
    }
    return $null
}

function Format-PublicKeyOnlyError {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$ConfiguredKeyPath
    )

    $lines = @(
        "SSH to ${User}@${DeployHost} requires a private key (password auth is disabled on the server)."
        ""
        "Add this to Backend/.deploy.local:"
        "  DEPLOY_SSH_KEY_PATH=C:\Users\you\.ssh\id_ed25519"
        ""
        "Use the private key whose public half is in the server's /root/.ssh/authorized_keys."
    )

    if ($ConfiguredKeyPath) {
        $lines += ""
        $lines += "Configured key was tested and rejected: $ConfiguredKeyPath"
        $lines += "On the server, verify the key fingerprint is listed:"
        $lines += "  ssh-keygen -lf /root/.ssh/authorized_keys"
        $pubPath = "$ConfiguredKeyPath.pub"
        if (Test-Path $pubPath) {
            $fp = (ssh-keygen -lf $pubPath 2>$null | ForEach-Object { ($_ -split '\s+')[1] })
            if ($fp) {
                $lines += "  Expected: $fp"
            }
            $pubKey = (Get-Content $pubPath -TotalCount 1).Trim()
            $lines += "If missing or wrapped across lines, run on the server:"
            $lines += "  chmod 700 /root && install -d -m 700 /root/.ssh"
            $lines += "  printf '%s\n' '$pubKey' >> /root/.ssh/authorized_keys"
            $lines += "  chmod 600 /root/.ssh/authorized_keys"
        }
    }
    else {
        $defaultKey = Join-Path $env:USERPROFILE ".ssh\id_ed25519"
        if (Test-Path $defaultKey) {
            $lines += ""
            $lines += "Your default key was tried but is not authorized: $defaultKey"
            $pubPath = "$defaultKey.pub"
            if (Test-Path $pubPath) {
                $pubKey = (Get-Content $pubPath -TotalCount 1).Trim()
                $lines += "Authorize it on the server with:"
                $lines += "  echo '$pubKey' >> /root/.ssh/authorized_keys"
            }
        }
    }

    $lines += ""
    $lines += "Run this helper for step-by-step setup:"
    $lines += "  .\scripts\setup-ssh-access.ps1"

    return ($lines -join [Environment]::NewLine)
}

function Get-DeployConfig {
    $backendRoot = Split-Path $PSScriptRoot -Parent
    $localFile = Join-Path $backendRoot ".deploy.local"

    $deployHost = $env:DEPLOY_HOST
    $password = $env:DEPLOY_PASSWORD
    $user = $env:DEPLOY_USER
    $repoPath = $env:DEPLOY_REPO_PATH
    $hostKeyFingerprint = $env:DEPLOY_HOST_KEY_FINGERPRINT
    $sshKeyPath = $env:DEPLOY_SSH_KEY_PATH

    if (Test-Path $localFile) {
        $fileValues = Read-DeployLocalFile -Path $localFile
        if (-not $deployHost) { $deployHost = $fileValues["DEPLOY_HOST"] }
        if (-not $password) { $password = $fileValues["DEPLOY_PASSWORD"] }
        if (-not $user) { $user = $fileValues["DEPLOY_USER"] }
        if (-not $repoPath) { $repoPath = $fileValues["DEPLOY_REPO_PATH"] }
        if (-not $hostKeyFingerprint) {
            $hostKeyFingerprint = $fileValues["DEPLOY_HOST_KEY_FINGERPRINT"]
        }
        if (-not $sshKeyPath) { $sshKeyPath = $fileValues["DEPLOY_SSH_KEY_PATH"] }
    }

    if (-not $user) { $user = "root" }
    if (-not $repoPath) { $repoPath = "~/RPG-Companion" }
    $configuredKeyPath = Resolve-DeployPath -Path $sshKeyPath -BackendRoot $backendRoot

    if (-not $deployHost) {
        throw "DEPLOY_HOST is required. Set `$env:DEPLOY_HOST or add it to .deploy.local."
    }
    if (-not $password -and -not $configuredKeyPath) {
        throw "Set DEPLOY_SSH_KEY_PATH (recommended) or DEPLOY_PASSWORD in .deploy.local."
    }

    $resolvedKeyPath = Resolve-WorkingSshKeyPath `
        -User $user `
        -DeployHost $deployHost `
        -PreferredPath $configuredKeyPath

    if ($resolvedKeyPath) {
        $sshKeyPath = $resolvedKeyPath
    }
    elseif ($configuredKeyPath) {
        $sshKeyPath = $configuredKeyPath
    }
    else {
        $sshKeyPath = $null
    }

    if (-not $sshKeyPath -and $password) {
        throw (Format-PublicKeyOnlyError -User $user -DeployHost $deployHost -ConfiguredKeyPath $null)
    }

    Ensure-SshKeyReady -User $user -DeployHost $deployHost -SshKeyPath $sshKeyPath

    return @{
        DeployHost         = $deployHost
        Password           = $password
        User               = $user
        RepoPath           = $repoPath
        HostKeyFingerprint = $hostKeyFingerprint
        SshKeyPath         = $sshKeyPath
    }
}

function Get-RemoteDeployCommand {
    param([string]$RepoPath)

    $repoPath = $RepoPath.TrimEnd("/")
    return @"
cd $repoPath && git fetch origin && git reset --hard origin/main && cd Backend && docker compose -p rpg-companion-prod -f docker-compose.prod.yml up --build -d && docker compose -p rpg-companion-prod -f docker-compose.prod.yml exec -T api alembic upgrade head
"@
}

function Get-PlinkExecutable {
    $cmd = Get-Command plink -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $candidates = @(
        Join-Path ${env:ProgramFiles} "PuTTY\plink.exe"
        Join-Path ${env:ProgramFiles(x86)} "PuTTY\plink.exe"
        Join-Path $env:LOCALAPPDATA "Programs\PuTTY\plink.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

function Get-WslDistroWithSshpass {
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        return $null
    }

    $rawList = wsl -l -q 2>$null
    if (-not $rawList) {
        return $null
    }

    $distros = $rawList |
        ForEach-Object { $_.Trim().Trim([char]0xFEFF) } |
        Where-Object {
            $_ -and
            $_ -notmatch "docker-desktop" -and
            $_ -notmatch "podman" -and
            $_ -ne "NAME"
        }

    foreach ($distro in $distros) {
        $check = wsl -d $distro -e sh -c "command -v sshpass" 2>$null
        if ($LASTEXITCODE -eq 0 -and $check) {
            return @{
                Distro  = $distro
                Sshpass = $check.Trim()
            }
        }
    }
    return $null
}

function Invoke-ExternalCommand {
    param(
        [string]$Executable,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $Executable @Arguments 2>&1
        return @{
            Output   = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
            ExitCode = $LASTEXITCODE
        }
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Get-PlinkCommonArgs {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$Password,
        [string]$SshKeyPath,
        [string]$HostKeyFingerprint
    )

    $args = @("-batch", "-ssh", "${User}@${DeployHost}")
    if ($HostKeyFingerprint) {
        $args += @("-hostkey", $HostKeyFingerprint)
    }
    if ($SshKeyPath) {
        $args += @("-i", $SshKeyPath)
    }
    elseif ($Password) {
        $args += @("-pw", $Password)
    }
    return $args
}

function Ensure-PlinkHostKeyCached {
    param(
        [string]$PlinkPath,
        [string]$User,
        [string]$DeployHost,
        [string]$Password,
        [string]$SshKeyPath,
        [string]$HostKeyFingerprint
    )

    if ($HostKeyFingerprint -or $SshKeyPath) {
        return
    }

    if (-not $Password) {
        throw "Password auth requires DEPLOY_HOST_KEY_FINGERPRINT or a cached host key."
    }

    $probeArgs = Get-PlinkCommonArgs `
        -User $User `
        -DeployHost $DeployHost `
        -Password $Password `
        -SshKeyPath $null `
        -HostKeyFingerprint $null
    $probe = Invoke-ExternalCommand -Executable $PlinkPath -Arguments ($probeArgs + @("exit"))

    if ($probe.ExitCode -eq 0) {
        return
    }

    if ($probe.Output -match "No supported authentication methods" -or
        $probe.Output -match "publickey") {
        throw (Format-PublicKeyOnlyError -User $User -DeployHost $DeployHost -ConfiguredKeyPath $SshKeyPath)
    }

    if ($probe.Output -notmatch "Cannot confirm a host key" -and
        $probe.Output -notmatch "host key is not cached") {
        throw "SSH connection failed before deploy: $($probe.Output)"
    }

    Write-Host "Caching SSH host key for ${DeployHost} (one-time)..."
    $acceptArgs = @("-ssh", "${User}@${DeployHost}", "-pw", $Password, "exit")
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $acceptOutput = "y" | & $PlinkPath @acceptArgs 2>&1
        $acceptText = ($acceptOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to cache SSH host key: $acceptText"
        }
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Invoke-RemoteViaOpenSsh {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$SshKeyPath,
        [string]$RemoteCommand
    )

    $ssh = Get-Command ssh -ErrorAction SilentlyContinue
    if (-not $ssh) {
        return $false
    }

    Write-Host "Using OpenSSH to connect to ${User}@${DeployHost}..."
    $sshArgs = @(
        "-i", $SshKeyPath,
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=15",
        "-o", "StrictHostKeyChecking=accept-new",
        "${User}@${DeployHost}",
        $RemoteCommand
    )
    $result = Invoke-ExternalCommand -Executable $ssh.Source -Arguments $sshArgs
    if ($result.Output) {
        Write-Host $result.Output
    }
    if ($result.ExitCode -ne 0) {
        throw "Remote deploy failed (ssh exit code $($result.ExitCode))."
    }
    return $true
}

function Invoke-RemoteViaPlink {
    param(
        [string]$PlinkPath,
        [string]$User,
        [string]$DeployHost,
        [string]$Password,
        [string]$SshKeyPath,
        [string]$RemoteCommand,
        [string]$HostKeyFingerprint
    )

    Ensure-PlinkHostKeyCached `
        -PlinkPath $PlinkPath `
        -User $User `
        -DeployHost $DeployHost `
        -Password $Password `
        -SshKeyPath $SshKeyPath `
        -HostKeyFingerprint $HostKeyFingerprint

    $plinkArgs = Get-PlinkCommonArgs `
        -User $User `
        -DeployHost $DeployHost `
        -Password $Password `
        -SshKeyPath $SshKeyPath `
        -HostKeyFingerprint $HostKeyFingerprint

    Write-Host "Using plink to connect to ${User}@${DeployHost}..."
    $result = Invoke-ExternalCommand -Executable $PlinkPath -Arguments ($plinkArgs + @($RemoteCommand))
    if ($result.Output) {
        Write-Host $result.Output
    }
    if ($result.ExitCode -ne 0) {
        throw "Remote deploy failed (plink exit code $($result.ExitCode))."
    }
}

function Invoke-RemoteViaWslSshpass {
    param(
        [hashtable]$WslInfo,
        [string]$User,
        [string]$DeployHost,
        [string]$Password,
        [string]$RemoteCommand
    )

    Write-Host "Using WSL ($($WslInfo.Distro)) sshpass to connect to ${User}@${DeployHost}..."
    $escapedPassword = $Password.Replace("'", "'\\''")
    $escapedCommand = $RemoteCommand.Replace("'", "'\\''")
    wsl -d $WslInfo.Distro -e sh -c "sshpass -p '$escapedPassword' ssh -o StrictHostKeyChecking=accept-new ${User}@${DeployHost} '$escapedCommand'"
    if ($LASTEXITCODE -ne 0) {
        throw "Remote deploy failed (WSL ssh exit code $LASTEXITCODE)."
    }
}

function Invoke-RemoteViaPoshSSH {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$Password,
        [string]$SshKeyPath,
        [string]$RemoteCommand
    )

    if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
        return $false
    }

    Import-Module Posh-SSH -ErrorAction Stop
    Write-Host "Using Posh-SSH to connect to ${User}@${DeployHost}..."

    if ($SshKeyPath) {
        $session = New-SSHSession `
            -ComputerName $DeployHost `
            -Username $User `
            -KeyFile $SshKeyPath `
            -AcceptKey `
            -ErrorAction Stop
    }
    else {
        $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($User, $securePassword)
        $session = New-SSHSession -ComputerName $DeployHost -Credential $credential -AcceptKey -ErrorAction Stop
    }

    try {
        $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $RemoteCommand
        if ($result.Output) {
            Write-Host $result.Output
        }
        if ($result.Error) {
            Write-Host $result.Error
        }
        if ($result.ExitStatus -ne 0) {
            throw "Remote deploy failed (ssh exit code $($result.ExitStatus))."
        }
    }
    finally {
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
    }
    return $true
}

function Invoke-RemoteCommand {
    param(
        [string]$User,
        [string]$DeployHost,
        [string]$Password,
        [string]$SshKeyPath,
        [string]$RemoteCommand,
        [string]$HostKeyFingerprint
    )

    if ($SshKeyPath) {
        if (Invoke-RemoteViaOpenSsh `
                -User $User `
                -DeployHost $DeployHost `
                -SshKeyPath $SshKeyPath `
                -RemoteCommand $RemoteCommand) {
            return
        }

        $plinkPath = Get-PlinkExecutable
        if ($plinkPath) {
            Invoke-RemoteViaPlink `
                -PlinkPath $plinkPath `
                -User $User `
                -DeployHost $DeployHost `
                -Password $null `
                -SshKeyPath $SshKeyPath `
                -RemoteCommand $RemoteCommand `
                -HostKeyFingerprint $HostKeyFingerprint
            return
        }

        if (Invoke-RemoteViaPoshSSH `
                -User $User `
                -DeployHost $DeployHost `
                -Password $null `
                -SshKeyPath $SshKeyPath `
                -RemoteCommand $RemoteCommand) {
            return
        }

        throw "SSH key auth requires OpenSSH (ssh), PuTTY plink, or the Posh-SSH module."
    }

    $plinkPath = Get-PlinkExecutable
    if ($plinkPath) {
        Invoke-RemoteViaPlink `
            -PlinkPath $plinkPath `
            -User $User `
            -DeployHost $DeployHost `
            -Password $Password `
            -SshKeyPath $null `
            -RemoteCommand $RemoteCommand `
            -HostKeyFingerprint $HostKeyFingerprint
        return
    }

    $wslInfo = Get-WslDistroWithSshpass
    if ($wslInfo) {
        Invoke-RemoteViaWslSshpass `
            -WslInfo $wslInfo `
            -User $User `
            -DeployHost $DeployHost `
            -Password $Password `
            -RemoteCommand $RemoteCommand
        return
    }

    if (Invoke-RemoteViaPoshSSH `
            -User $User `
            -DeployHost $DeployHost `
            -Password $Password `
            -SshKeyPath $null `
            -RemoteCommand $RemoteCommand) {
        return
    }

    throw @"
No SSH helper found for password auth.

If your server only accepts public keys (common on VPS hosts), set DEPLOY_SSH_KEY_PATH in .deploy.local:
  DEPLOY_SSH_KEY_PATH=C:\Users\you\.ssh\id_ed25519

Otherwise install PuTTY plink:
  winget install PuTTY.PuTTY
"@
}

$config = Get-DeployConfig
$remoteCommand = Get-RemoteDeployCommand -RepoPath $config.RepoPath

Write-Host "Deploying RPG-Companion backend to $($config.User)@$($config.DeployHost)..."
Write-Host "Repo path: $($config.RepoPath)"
if ($config.SshKeyPath) {
    Write-Host "Auth: SSH key ($($config.SshKeyPath))"
}
Write-Host ""

Invoke-RemoteCommand `
    -User $config.User `
    -DeployHost $config.DeployHost `
    -Password $config.Password `
    -SshKeyPath $config.SshKeyPath `
    -RemoteCommand $remoteCommand `
    -HostKeyFingerprint $config.HostKeyFingerprint

Write-Host ""
Write-Host "Deploy finished successfully."
