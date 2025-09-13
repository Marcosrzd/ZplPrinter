Param(
    [int]$Port = 9101,
    [string]$Host = '127.0.0.1',
    [string]$PrinterName = 'ZPL_TCP9101',
    [string]$ShareName = 'ZPL_TCP9101',
    [string]$DriverName = 'Generic / Text Only'
)

$ErrorActionPreference = 'Stop'

function Ensure-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Execute este script em um PowerShell aberto como Administrador.'
    }
}

function Ensure-PrintSpooler {
    $svc = Get-Service -Name Spooler -ErrorAction Stop
    if ($svc.Status -ne 'Running') { Start-Service -Name Spooler }
}

Ensure-Admin
Ensure-PrintSpooler

$portName = "IP_${Host}_${Port}"
if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
    Write-Host "Criando porta $portName ($Host:$Port)"
    Add-PrinterPort -Name $portName -PrinterHostAddress $Host -PortNumber $Port -Protocol Raw | Out-Null
} else {
    Write-Host "Porta $portName já existe"
}

if (-not (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue)) {
    Write-Host "Adicionando impressora $PrinterName"
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $portName | Out-Null
} else {
    Write-Host "Impressora $PrinterName já existe"
}

Write-Host "Compartilhando impressora como $ShareName"
Set-Printer -Name $PrinterName -Shared $true -ShareName $ShareName | Out-Null

Write-Host "Habilitando serviços SMB (Server e Workstation)"
sc.exe config lanmanserver start= auto | Out-Null
sc.exe start lanmanserver | Out-Null
sc.exe config lanmanworkstation start= auto | Out-Null
sc.exe start lanmanworkstation | Out-Null

Write-Host 'Concluído.'

