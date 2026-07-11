$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Test-Path ".env.dev")) {
    Copy-Item ".env.dev.example" ".env.dev"
    Write-Host "Created .env.dev from .env.dev.example"
}

Write-Host "Setup complete."
