$ErrorActionPreference = 'Stop'

$appPath = Join-Path $env:LOCALAPPDATA 'Programs\Envia2\Envia2.exe'

foreach ($protocol in @('TCP', 'UDP')) {
    $displayName = "Envia2 $protocol 53317"
    Get-NetFirewallRule -DisplayName $displayName -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue

    New-NetFirewallRule `
        -DisplayName $displayName `
        -Description 'Permite descubrir dispositivos y transferir archivos con Envia2 en la red local.' `
        -Direction Inbound `
        -Action Allow `
        -Protocol $protocol `
        -LocalPort 53317 `
        -Program $appPath `
        -Profile Private | Out-Null
}

Set-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -NetworkCategory Private

