<#
    Mirador — instalador

    Copia Mirador a tu carpeta de usuario y crea el acceso directo, con su
    ícono, en el Escritorio y en el menú Inicio.

    NO pide permisos de administrador: todo queda dentro de tu perfil.

    Uso:
        .\instalar.ps1                 instala o actualiza
        .\instalar.ps1 -Desinstalar    quita todo lo que instaló
#>

[CmdletBinding()]
param(
    [switch] $Desinstalar
)

$ErrorActionPreference = 'Stop'

# La consola de Windows no viene en UTF-8. Sin estas dos lineas, los acentos
# de los mensajes de abajo salen rotos en cualquier equipo cuya pagina de
# codigos no sea la 65001 -- que son casi todos.
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding            = [System.Text.Encoding]::UTF8
} catch { }

$origen   = Split-Path -Parent $MyInvocation.MyCommand.Path
$destino  = Join-Path $env:LOCALAPPDATA 'Mirador'
$escritorio = [Environment]::GetFolderPath('Desktop')
$menuInicio = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'

$accesoEscritorio = Join-Path $escritorio 'Mirador.lnk'
$accesoMenu       = Join-Path $menuInicio 'Mirador.lnk'

function Escribir { param([string] $T, [string] $Color = 'Gray') Write-Host $T -ForegroundColor $Color }

# ---------------------------------------------------------------------------
# Desinstalar
# ---------------------------------------------------------------------------

if ($Desinstalar) {
    Escribir ''
    Escribir '  Desinstalando Mirador...' 'Yellow'

    foreach ($acceso in @($accesoEscritorio, $accesoMenu)) {
        if (Test-Path $acceso) {
            Remove-Item $acceso -Force
            Escribir "    quitado  $acceso"
        }
    }

    if (Test-Path $destino) {
        Remove-Item $destino -Recurse -Force
        Escribir "    quitado  $destino"
    }

    Escribir ''
    Escribir '  Listo. Mirador ya no está instalado.' 'Green'
    Escribir '  scrcpy y adb NO se tocaron: si los quieres quitar, usa winget o choco.' 'DarkGray'
    Escribir ''
    return
}

# ---------------------------------------------------------------------------
# Instalar
# ---------------------------------------------------------------------------

Escribir ''
Escribir '  Mirador — tu celular en tu pantalla' 'Cyan'
Escribir '  -----------------------------------' 'DarkCyan'
Escribir ''

# 1. Comprobar que están los archivos que hay que copiar
$archivos = @(
    @{ De = Join-Path $origen 'mirador.ps1';                A = 'mirador.ps1' },
    @{ De = Join-Path $origen 'recursos\mirador.ico';       A = 'mirador.ico' }
)

foreach ($a in $archivos) {
    if (-not (Test-Path $a.De)) {
        Escribir "  No encuentro '$($a.De)'." 'Red'
        Escribir '  Ejecuta este instalador desde la carpeta donde descargaste Mirador.' 'Red'
        Escribir ''
        exit 1
    }
}

# 2. Copiar
if (-not (Test-Path $destino)) { New-Item -ItemType Directory -Path $destino -Force | Out-Null }
foreach ($a in $archivos) {
    Copy-Item $a.De (Join-Path $destino $a.A) -Force
}
Escribir "  Instalado en  $destino" 'Green'

# 3. Accesos directos
#    -WindowStyle Hidden es a propósito: Mirador no usa consola, todo lo
#    que necesita preguntar lo pregunta en ventanas de Windows.
$shell = New-Object -ComObject WScript.Shell

foreach ($ruta in @($accesoEscritorio, $accesoMenu)) {
    $lnk = $shell.CreateShortcut($ruta)
    $lnk.TargetPath       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $lnk.Arguments        = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$destino\mirador.ps1`""
    $lnk.WorkingDirectory = $destino
    $lnk.IconLocation     = "$destino\mirador.ico,0"
    $lnk.Description      = 'Abre la pantalla de tu celular en el computador'
    $lnk.Save()
}
Escribir '  Acceso directo creado en el Escritorio y en el menú Inicio' 'Green'

# 4. Avisar si falta scrcpy — Mirador lo instala solo la primera vez,
#    pero es mejor que la persona sepa qué va a pasar.
if (-not (Get-Command scrcpy -ErrorAction SilentlyContinue)) {
    Escribir ''
    Escribir '  Nota: scrcpy todavía no está instalado.' 'Yellow'
    Escribir '  La primera vez que abras Mirador lo instalará solo (con winget, sin pedir' 'DarkGray'
    Escribir '  permisos de administrador). Tarda un par de minutos esa única vez.' 'DarkGray'
}

Escribir ''
Escribir '  Listo. Abre «Mirador» desde el Escritorio.' 'Cyan'
Escribir ''
Escribir '  Antes del primer uso, en el celular:' 'Gray'
Escribir '    Ajustes › Acerca del teléfono › toca 7 veces «Número de compilación»' 'DarkGray'
Escribir '    Ajustes › Opciones de desarrollador › activa «Depuración USB»' 'DarkGray'
Escribir '    (y «Depuración inalámbrica» si lo vas a usar sin cable)' 'DarkGray'
Escribir ''
