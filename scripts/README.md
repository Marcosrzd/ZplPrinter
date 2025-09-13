# Scripts de Configuração de Impressão ZPL

Este diretório contém scripts para preparar a porta RAW 9101, a impressora compartilhada e o mapeamento de `LPT1:`.

## 1) Criar porta RAW 9101 e impressora compartilhada (PowerShell — requer Admin)

Executar em PowerShell elevado (Run as Administrator):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\app\ZPL\scripts\setup_tcp9101.ps1"
```

Parâmetros opcionais:

```powershell
-Port 9101 -Host 127.0.0.1 -PrinterName "ZPL_TCP9101" -ShareName "ZPL_TCP9101"
```

O script realiza:
- Criação da porta RAW `IP_127.0.0.1_9101`
- Instalação da impressora `ZPL_TCP9101` (driver: Generic / Text Only)
- Compartilhamento como `ZPL_TCP9101`
- Ativação dos serviços SMB (Server/Workstation)

## 2) Mapear `LPT1:` para o compartilhamento SMB (CMD — executar SEM Admin)

IMPORTANTE: Execute o mapeamento sem privilégios de administrador. Se for criado como Admin, apenas processos elevados verão o mapeamento e aplicativos comuns não conseguirão usar `LPT1:`.

CMD não-elevado:

```bat
"C:\app\ZPL\scripts\map_lpt1.cmd"
```

O script:
- Remove mapeamento existente de `LPT1:` (se houver)
- Mapeia `LPT1:` para `\\%COMPUTERNAME%\ZPL_TCP9101` com persistência
- Recusa execução elevada (Admin)

## 3) Teste de envio ZPL

Crie `C:\temp\teste.zpl` com conteúdo, por exemplo:

```text
^XA
^PW400
^LL300
^FO50,50^A0N,40,40^FDTeste^FS
^XZ
```

Envie para `LPT1:`:

```bat
copy /b "C:\temp\teste.zpl" LPT1:
```

Alternativa (direto ao compartilhamento caso tenha erros no envio a LPT1):

```bat
copy /b "C:\temp\teste.zpl" \\%COMPUTERNAME%\ZPL_TCP9101
```

## Observações
- No app Zpl Printer, configure Host/Port conforme o redirecionamento (ex.: 127.0.0.1:9101).
- O app usa `C:\temp\` como diretório padrão para salvar rótulos.
- O ZPL deve ser completo (terminar em `^XZ`).
