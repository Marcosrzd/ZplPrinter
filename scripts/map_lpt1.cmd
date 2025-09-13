@echo off
setlocal ENABLEEXTENSIONS

:: Recusar execução elevada (Admin)
whoami /groups | find "S-1-5-32-544" >nul
if not errorlevel 1 (
  echo Este script NAO deve ser executado como Administrador. Feche e execute normalmente.
  exit /b 1
)

set "PRINTER_SHARE=ZPL_TCP9101"
set "TARGET=\\%COMPUTERNAME%\%PRINTER_SHARE%"

echo Removendo mapeamento existente de LPT1 (se houver)...
net use LPT1: /delete /y >nul 2>&1

echo Mapeando LPT1 para %TARGET% ...
net use LPT1: %TARGET% /persistent:yes
if errorlevel 1 (
  echo Falha ao mapear LPT1. Verifique se a impressora ^"%PRINTER_SHARE%^" esta compartilhada e acessivel.
  exit /b 2
)

echo Sucesso. LPT1 mapeada para %TARGET%.
exit /b 0

