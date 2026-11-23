$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$dist = Join-Path $projectRoot "dist"
$exe = Join-Path $dist "Envia2.exe"
$blob = Join-Path $dist "sea-prep.blob"

New-Item -ItemType Directory -Force -Path $dist | Out-Null
node --experimental-sea-config (Join-Path $projectRoot "sea-config.json")
Copy-Item -Force (Get-Command node).Source $exe
& (Join-Path $projectRoot "node_modules\.bin\postject.cmd") $exe NODE_SEA_BLOB $blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2
if ($LASTEXITCODE -ne 0) { throw "No se pudo crear Envia2.exe" }
Remove-Item -Force $blob
Write-Host "Creado: $exe"
