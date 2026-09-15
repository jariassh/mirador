<#
    Mirador - tu celular en tu pantalla
    ------------------------------------------------
    Abre la pantalla del celular en el computador, por cable o por Wi-Fi,
    sin dejar bloqueado al usuario en ningun escenario.

    Decisiones de diseno (el porque, para no volver a investigarlo):

    - ARCHIVO EN UTF-8 CON BOM. Windows PowerShell 5.1 lee un .ps1 sin BOM
      como pagina de codigos ANSI, y las tildes salen como "Ã³". Con BOM,
      las tildes funcionan en consola y en los cuadros de dialogo.

    - TODO ES GRAFICO, CERO Read-Host. El acceso directo del escritorio
      lanza con -WindowStyle Hidden: cualquier menu de consola queda
      invisible y Read-Host deja el proceso colgado para siempre.

    - EL TECNO NO TIENE PUERTO USB UTIL. Por eso la Depuracion inalambrica
      (emparejar por codigo) es un camino de primera clase y no un extra:
      si ese telefono se reinicia se pierde el modo TCP/IP y sin cable no
      hay manera de volver a activarlo con "adb tcpip".

    - LA IP CAMBIA porque el router la reparte por DHCP. No se pregunta:
      se descubre, en este orden -> cache, mDNS, escaneo de la subred.

    Uso:
        mirador.ps1              flujo normal
        mirador.ps1 -Elegir      fuerza el menu de dispositivos
        mirador.ps1 -Emparejar   va directo a emparejar por Wi-Fi
#>

[CmdletBinding()]
param(
    [switch] $Elegir,
    [switch] $Emparejar
)

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------------------------------------------------------------------
# Configuracion y estado
# ---------------------------------------------------------------------------

# El estado va en LOCALAPPDATA y no junto al script: ProgramData puede
# requerir permisos de administrador para escribir en otros equipos.
$script:CarpetaEstado = Join-Path $env:LOCALAPPDATA 'Mirador'
$script:ArchivoEstado = Join-Path $script:CarpetaEstado 'dispositivos.json'
$script:ArchivoLog    = Join-Path $script:CarpetaEstado 'mirador.log'
$script:PuertoAdb     = 5555
$script:AdbExe        = 'adb'
$script:ScrcpyExe     = 'scrcpy'

if (-not (Test-Path $script:CarpetaEstado)) {
    New-Item -ItemType Directory -Path $script:CarpetaEstado -Force | Out-Null
}

function Escribir-Log {
    param([string] $Mensaje)
    $linea = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Mensaje
    try { Add-Content -Path $script:ArchivoLog -Value $linea -Encoding UTF8 } catch { }
    Write-Verbose $linea
}

# El log no crece sin control: se conservan las ultimas 400 lineas.
if (Test-Path $script:ArchivoLog) {
    try {
        $lineas = Get-Content $script:ArchivoLog
        if ($lineas.Count -gt 400) {
            $lineas | Select-Object -Last 400 | Set-Content -Path $script:ArchivoLog -Encoding UTF8
        }
    } catch { }
}

Escribir-Log "----- Inicio (Elegir=$Elegir Emparejar=$Emparejar) -----"

function Leer-Estado {
    if (-not (Test-Path $script:ArchivoEstado)) { return @() }
    try {
        $crudo = Get-Content $script:ArchivoEstado -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($crudo)) { return @() }

        # El resultado se guarda en una variable ANTES de envolverlo en @().
        # ConvertFrom-Json de PS 5.1 emite una lista JSON como UN SOLO objeto,
        # asi que "@($crudo | ConvertFrom-Json)" devuelve un arreglo de un
        # elemento que contiene el arreglo entero. Sobre una variable, en
        # cambio, @() si aplana. El sintoma era silencioso: con dos telefonos
        # guardados, el paso de cache intentaba conectarse UNA vez a las dos
        # direcciones pegadas y siempre fallaba.
        $datos = ConvertFrom-Json -InputObject $crudo
        return @($datos)
    } catch {
        Escribir-Log "No se pudo leer el estado: $($_.Exception.Message)"
        return @()
    }
}

function Guardar-Estado {
    param([array] $Conocidos)
    try {
        # Sin la coma: ",@($x) | ConvertTo-Json" serializa el ENVOLTORIO del
        # arreglo y escribe {"value":[...],"Count":1} en vez de la lista.
        # Con un solo registro esto guarda un objeto suelto en vez de una
        # lista, y por eso Leer-Estado siempre envuelve el resultado en @().
        @($Conocidos) | ConvertTo-Json -Depth 4 | Set-Content -Path $script:ArchivoEstado -Encoding UTF8
    } catch {
        Escribir-Log "No se pudo guardar el estado: $($_.Exception.Message)"
    }
}

function Recordar-Dispositivo {
    param([string] $Serial, [string] $Nombre, [string] $Direccion)

    if ([string]::IsNullOrWhiteSpace($Serial)) { return }
    $conocidos = @(Leer-Estado | Where-Object { $_.serial -ne $Serial })
    $registro = [pscustomobject]@{
        serial    = $Serial
        nombre    = $Nombre
        direccion = $Direccion
        ultimoUso = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }
    Guardar-Estado (@($registro) + $conocidos)
}

# ---------------------------------------------------------------------------
# Ventanas de Windows (traer al frente)
# ---------------------------------------------------------------------------

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MiradorWin32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

function Obtener-VentanaDe {
    param([string] $Titulo)
    return Get-Process -Name 'scrcpy' -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq $Titulo } |
        Select-Object -First 1
}

function Traer-AlFrente {
    param($Proceso)
    [MiradorWin32]::ShowWindow($Proceso.MainWindowHandle, 9) | Out-Null   # 9 = SW_RESTORE
    [MiradorWin32]::SetForegroundWindow($Proceso.MainWindowHandle) | Out-Null
}

# ---------------------------------------------------------------------------
# Dialogos
# ---------------------------------------------------------------------------

function Mostrar-Mensaje {
    param(
        [string] $Texto,
        [string] $Titulo = 'Mirador',
        [ValidateSet('Information', 'Error', 'Warning')] [string] $Icono = 'Information'
    )
    [System.Windows.Forms.MessageBox]::Show($Texto, $Titulo, 'OK', $Icono) | Out-Null
}

function Nueva-Ventana {
    param([string] $Titulo, [int] $Ancho = 430, [int] $Alto = 300)
    $f = New-Object System.Windows.Forms.Form
    $f.Text            = $Titulo
    $f.Size            = New-Object System.Drawing.Size($Ancho, $Alto)
    $f.StartPosition   = 'CenterScreen'
    $f.FormBorderStyle = 'FixedDialog'
    $f.MaximizeBox     = $false
    $f.MinimizeBox     = $false
    $f.TopMost         = $true
    $f.Font            = New-Object System.Drawing.Font('Segoe UI', 9)
    return $f
}

function Nueva-Etiqueta {
    param([string] $Texto, [int] $X, [int] $Y, [int] $Ancho, [int] $Alto = 20, [switch] $Negrita)
    $l = New-Object System.Windows.Forms.Label
    $l.Text     = $Texto
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.Size     = New-Object System.Drawing.Size($Ancho, $Alto)
    if ($Negrita) { $l.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold) }
    return $l
}

function Nuevo-Boton {
    param([string] $Texto, [int] $X, [int] $Y, [int] $Ancho = 110, [int] $Alto = 28)
    $b = New-Object System.Windows.Forms.Button
    $b.Text     = $Texto
    $b.Location = New-Object System.Drawing.Point($X, $Y)
    $b.Size     = New-Object System.Drawing.Size($Ancho, $Alto)
    return $b
}

# ---------------------------------------------------------------------------
# Instalacion de scrcpy (trae adb en el mismo paquete)
# ---------------------------------------------------------------------------

function Asegurar-Scrcpy {
    if (Get-Command $script:ScrcpyExe -ErrorAction SilentlyContinue) { return $true }

    Escribir-Log 'scrcpy no esta instalado'

    # winget primero: instala sin pedir permisos de administrador.
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Mostrar-Mensaje "scrcpy no está instalado. Se va a instalar una sola vez; puede tardar un par de minutos."
        Escribir-Log 'Instalando con winget'
        & winget install --id Genymobile.scrcpy --exact --silent `
            --accept-source-agreements --accept-package-agreements | Out-Null
        Refrescar-Path
        if (Get-Command $script:ScrcpyExe -ErrorAction SilentlyContinue) {
            Escribir-Log 'Instalado con winget'
            return $true
        }
    }

    # Chocolatey como respaldo: este camino si necesita administrador.
    $esAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $esAdmin) {
        Mostrar-Mensaje "Hay que instalar scrcpy y Windows va a pedir permiso de administrador."
        Start-Process powershell -Verb RunAs -ArgumentList `
            "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        return $false
    }

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Escribir-Log 'Instalando Chocolatey'
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol =
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
            'https://community.chocolatey.org/install.ps1'))
        Refrescar-Path
    }

    & choco install scrcpy -y | Out-Null
    Refrescar-Path

    if (-not (Get-Command $script:ScrcpyExe -ErrorAction SilentlyContinue)) {
        Mostrar-Mensaje "No se pudo instalar scrcpy. Instálalo a mano con 'winget install Genymobile.scrcpy'." 'Mirador' 'Error'
        return $false
    }

    Escribir-Log 'Instalado con choco'
    return $true
}

function Refrescar-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

# ---------------------------------------------------------------------------
# adb
# ---------------------------------------------------------------------------

function Invocar-Adb {
    param([string[]] $Argumentos)
    try {
        $salida = & $script:AdbExe @Argumentos 2>$null
        return ($salida | Out-String)
    } catch {
        Escribir-Log "adb $($Argumentos -join ' ') fallo: $($_.Exception.Message)"
        return ''
    }
}

<#
    Devuelve TODOS los dispositivos que adb conoce, con su estado, no solo
    los que estan listos. Distinguir "unauthorized" y "offline" es lo que
    evita el callejon sin salida: el caso mas frecuente de todos es el
    telefono mostrando el dialogo "¿Permitir depuración USB?", y reportarlo
    como "no hay dispositivos" deja al usuario sin saber que hacer.
#>
function Obtener-Dispositivos {
    $texto = Invocar-Adb @('devices', '-l')
    $lista = @()

    foreach ($linea in ($texto -split "`r?`n")) {
        $t = $linea.Trim()
        if ($t -eq '' -or $t -like 'List of devices*' -or $t -like '*daemon*') { continue }

        $partes = $t -split '\s+'
        if ($partes.Count -lt 2) { continue }

        $id     = $partes[0]
        $estado = $partes[1]
        $modelo = ''
        if ($t -match 'model:(\S+)') { $modelo = $Matches[1] -replace '_', ' ' }

        $lista += [pscustomobject]@{
            Id      = $id
            Estado  = $estado
            Modelo  = $modelo
            EsWifi  = ($id -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' -or $id -match '^adb-')
            Serial  = ''
            Nombre  = ''
        }
    }
    <#
        OJO con el tipo de retorno. Dos trampas encadenadas de PowerShell,
        las dos verificadas midiendo:

        1. .Count sobre un PSCustomObject NO vale 1: vale $null, porque lo
           interpreta como una propiedad llamada Count que el objeto no
           tiene. Con un solo telefono, "if ($equipos.Count -eq 1)" daba
           falso y el script caia al selector, que se quedaba esperando en
           una ventana invisible.

        2. El arreglo se fuerza con @() EN EL SITIO DE LA LLAMADA, nunca con
           "return ,@(...)" aqui. Las dos tecnicas juntas se anulan: la coma
           mete el arreglo dentro de otro arreglo y el @() de afuera ya no lo
           aplana, asi que dos telefonos llegaban como UN solo Object[].
    #>
    return $lista
}

function Obtener-Propiedad {
    param([string] $Id, [string] $Propiedad)
    $valor = (Invocar-Adb @('-s', $Id, 'shell', 'getprop', $Propiedad)).Trim()
    return $valor
}

<#
    Completa nombre legible y serial fisico.

    El serial fisico (ro.serialno) es lo unico estable: el identificador de
    adb cambia segun el transporte, asi que el MISMO telefono aparece dos
    veces cuando esta por USB y por Wi-Fi a la vez. Sin esto, el menu
    muestra dos entradas cripticas del mismo aparato.
#>
function Completar-Datos {
    param([array] $Dispositivos)

    foreach ($d in $Dispositivos) {
        if ($d.Estado -ne 'device') {
            $d.Nombre = "$($d.Id) (sin autorizar)"
            continue
        }

        $marca  = Obtener-Propiedad $d.Id 'ro.product.manufacturer'
        $modelo = $d.Modelo
        if ([string]::IsNullOrWhiteSpace($modelo)) {
            $modelo = Obtener-Propiedad $d.Id 'ro.product.model'
        }
        $d.Serial = Obtener-Propiedad $d.Id 'ro.serialno'
        if ([string]::IsNullOrWhiteSpace($d.Serial)) { $d.Serial = $d.Id }

        # Sin esto el TECNO sale como "TECNO TECNO KL4": el fabricante ya
        # viene dentro del modelo. Y al reves pasa con Motorola, donde el
        # fabricante es "motorola" y el modelo "moto g60" -- por eso se
        # comparan los dos sentidos y no solo uno.
        $primeraDelModelo = ''
        if (-not [string]::IsNullOrWhiteSpace($modelo)) {
            $primeraDelModelo = ($modelo.Trim() -split '\s+')[0]
        }

        $repetido = $false
        if (-not [string]::IsNullOrWhiteSpace($marca) -and -not [string]::IsNullOrWhiteSpace($modelo)) {
            if ($modelo -imatch ('^' + [regex]::Escape($marca))) { $repetido = $true }
            if ($marca  -imatch ('^' + [regex]::Escape($primeraDelModelo))) { $repetido = $true }
        }

        if ($repetido -or [string]::IsNullOrWhiteSpace($marca)) {
            $nombre = "$modelo".Trim()
        } else {
            $nombre = (('{0} {1}' -f $marca, $modelo)).Trim()
        }

        if ([string]::IsNullOrWhiteSpace($nombre)) { $nombre = $d.Id }
        $d.Nombre = $nombre
    }
    return $Dispositivos
}

<#
    Un aparato fisico = una entrada. Si esta por USB y por Wi-Fi a la vez se
    prefiere el USB: mejor latencia y sin techo de ancho de banda.
#>
function Unificar-Dispositivos {
    param([array] $Dispositivos)

    $resultado = @()
    foreach ($grupo in ($Dispositivos | Group-Object -Property Serial)) {
        $porUsb  = $grupo.Group | Where-Object { -not $_.EsWifi } | Select-Object -First 1
        $porWifi = $grupo.Group | Where-Object { $_.EsWifi }      | Select-Object -First 1

        if ($porUsb) { $elegido = $porUsb } else { $elegido = $porWifi }

        if ($porUsb -and $porWifi) { $enlace = 'USB + Wi-Fi' }
        elseif ($porUsb)           { $enlace = 'USB' }
        else                       { $enlace = 'Wi-Fi' }

        $resultado += [pscustomobject]@{
            Id            = $elegido.Id
            Serial        = $elegido.Serial
            Nombre        = $elegido.Nombre
            Estado        = $elegido.Estado
            Enlace        = $enlace
            EsWifi        = $elegido.EsWifi
            DireccionWifi = $(if ($porWifi) { $porWifi.Id } else { '' })
        }
    }
    return $resultado
}

# ---------------------------------------------------------------------------
# Recuperacion: encontrar el telefono aunque le haya cambiado la IP
# ---------------------------------------------------------------------------

<#
    La direccion guardada puede ser "192.168.1.8:5555" (modo adb tcpip) o el
    nombre mDNS "adb-SERIAL-xxxx._adb-tls-connect._tcp" (Depuracion
    inalambrica). adb acepta las dos -- verificado -- y el NOMBRE es el que
    sobrevive a un cambio de IP, porque la Depuracion inalambrica ademas usa
    un puerto aleatorio distinto en cada reconexion.
#>
function Reconectar-DesdeCache {
    $conocidos = @(Leer-Estado | Where-Object { -not [string]::IsNullOrWhiteSpace($_.direccion) })
    if ($conocidos.Count -eq 0) { return $false }

    $algo = $false
    foreach ($c in $conocidos) {
        Escribir-Log "Intentando cache: $($c.direccion)"
        $r = Invocar-Adb @('connect', $c.direccion)
        if ($r -match 'connected to') { $algo = $true; Escribir-Log "Cache OK: $($c.direccion)" }
    }
    return $algo
}

<#
    Descubrimiento mDNS: la respuesta correcta a "¿y si cambió la IP?".
    Con la Depuración inalámbrica encendida, el teléfono se anuncia con un
    nombre estable y adb lo encuentra sin que nadie sepa la IP.
#>
function Buscar-PorMdns {
    param([int] $SegundosEspera = 4)

    $fin = (Get-Date).AddSeconds($SegundosEspera)
    $encontrado = $false

    while ((Get-Date) -lt $fin) {
        $texto = Invocar-Adb @('mdns', 'services')
        foreach ($linea in ($texto -split "`r?`n")) {
            if ($linea -match '_adb-tls-connect\._tcp' -or $linea -match '_adb\._tcp') {
                $partes = @($linea.Trim() -split '\s+')
                if ($partes.Count -lt 2) { continue }

                # Se conecta por el NOMBRE del servicio, no por la IP: el
                # nombre es estable y la IP es lo que cambia. La IP queda
                # como respaldo por si adb no resuelve el nombre.
                $nombre = '{0}.{1}' -f $partes[0], $partes[1]
                $ipPuerto = $partes | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' } | Select-Object -First 1

                foreach ($destino in @($nombre, $ipPuerto)) {
                    if ([string]::IsNullOrWhiteSpace($destino)) { continue }
                    Escribir-Log "mDNS intenta $destino"
                    $r = Invocar-Adb @('connect', $destino)
                    if ($r -match 'connected to') { $encontrado = $true; break }
                }
            }
        }
        if ($encontrado) { break }
        Start-Sleep -Milliseconds 700
    }
    return $encontrado
}

function Obtener-ServicioEmparejamiento {
    $texto = Invocar-Adb @('mdns', 'services')
    foreach ($linea in ($texto -split "`r?`n")) {
        if ($linea -match '_adb-tls-pairing\._tcp') {
            $partes = ($linea.Trim() -split '\s+')
            $direccion = $partes | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' } | Select-Object -First 1
            if ($direccion) { return $direccion }
        }
    }
    return ''
}

<#
    Ultimo recurso: barrer la subred buscando el puerto 5555 abierto.
    Solo redes /24 o mas pequenas y se excluyen los adaptadores virtuales
    (Hyper-V trae un /20 = 4.094 direcciones, que no se puede barrer).
#>
function Buscar-EnLaRed {
    $bases = @()
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*' -and
            $_.PrefixLength -ge 24 -and
            $_.InterfaceAlias -notmatch 'vEthernet|Loopback|VirtualBox|VMware|Hyper-V'
        } | ForEach-Object {
            $o = $_.IPAddress -split '\.'
            $bases += @{ Base = "$($o[0]).$($o[1]).$($o[2])"; Propia = $_.IPAddress }
        }

    if ($bases.Count -eq 0) { return $false }

    $pendientes = @()
    foreach ($b in $bases) {
        Escribir-Log "Barriendo $($b.Base).0/24 en el puerto $($script:PuertoAdb)"
        for ($i = 1; $i -le 254; $i++) {
            $ip = "$($b.Base).$i"
            if ($ip -eq $b.Propia) { continue }
            $cliente = New-Object System.Net.Sockets.TcpClient
            try {
                $async = $cliente.BeginConnect($ip, $script:PuertoAdb, $null, $null)
                $pendientes += [pscustomobject]@{ Ip = $ip; Cliente = $cliente; Async = $async }
            } catch {
                $cliente.Close()
            }
        }
    }

    Start-Sleep -Milliseconds 900

    $encontrado = $false
    foreach ($p in $pendientes) {
        try {
            if ($p.Async.IsCompleted) {
                $p.Cliente.EndConnect($p.Async)
                if ($p.Cliente.Connected) {
                    $direccion = "$($p.Ip):$($script:PuertoAdb)"
                    Escribir-Log "Barrido encontro $direccion"
                    $r = Invocar-Adb @('connect', $direccion)
                    if ($r -match 'connected to') { $encontrado = $true }
                }
            }
        } catch {
        } finally {
            $p.Cliente.Close()
        }
    }
    return $encontrado
}

<#
    Pasa un telefono conectado por cable a modo inalambrico.
    scrcpy 4.1 lo hace solo con --tcpip: busca el aparato por USB, le lee la
    IP, activa el modo TCP/IP y se conecta. Aqui solo se prepara adb para
    que el dispositivo quede disponible para la lista.
#>
function Pasar-AWifi {
    param([string] $IdUsb)

    Escribir-Log "Pasando $IdUsb a Wi-Fi"
    Invocar-Adb @('-s', $IdUsb, 'tcpip', "$($script:PuertoAdb)") | Out-Null
    Start-Sleep -Seconds 2

    $ruta = Invocar-Adb @('-s', $IdUsb, 'shell', 'ip', '-f', 'inet', 'addr', 'show', 'wlan0')
    $ip = ''
    if ($ruta -match 'inet (\d{1,3}(?:\.\d{1,3}){3})') { $ip = $Matches[1] }

    if ([string]::IsNullOrWhiteSpace($ip)) {
        $ruta = Invocar-Adb @('-s', $IdUsb, 'shell', 'ip', 'route')
        $linea = ($ruta -split "`r?`n") | Where-Object { $_ -match 'wlan' } | Select-Object -First 1
        if ($linea) { $ip = (($linea.Trim() -split '\s+')[-1]) }
    }

    if ([string]::IsNullOrWhiteSpace($ip)) {
        Escribir-Log 'No se pudo leer la IP del telefono'
        return ''
    }

    $direccion = "${ip}:$($script:PuertoAdb)"
    $r = Invocar-Adb @('connect', $direccion)
    if ($r -match 'connected to') { return $direccion }
    return ''
}

function Limpiar-Muertos {
    param([array] $Dispositivos)
    foreach ($d in ($Dispositivos | Where-Object { $_.Estado -eq 'offline' -and $_.EsWifi })) {
        Escribir-Log "Desconectando fantasma $($d.Id)"
        Invocar-Adb @('disconnect', $d.Id) | Out-Null
    }
}

# ---------------------------------------------------------------------------
# Dialogo: emparejar por Wi-Fi (Depuracion inalambrica, Android 11+)
# ---------------------------------------------------------------------------

function Mostrar-Emparejamiento {
    $f = Nueva-Ventana 'Emparejar por Wi-Fi' 470 330

    $f.Controls.Add((Nueva-Etiqueta 'En el teléfono:' 20 15 420 -Negrita))
    $f.Controls.Add((Nueva-Etiqueta "Ajustes › Opciones de desarrollador › Depuración inalámbrica ›`nVincular dispositivo con código de vinculación" 20 38 420 40))

    $f.Controls.Add((Nueva-Etiqueta 'Dirección y puerto de vinculación' 20 92 300))
    $txtDir = New-Object System.Windows.Forms.TextBox
    $txtDir.Location = New-Object System.Drawing.Point(20, 113)
    $txtDir.Size     = New-Object System.Drawing.Size(280, 24)
    $f.Controls.Add($txtDir)

    $lblAuto = Nueva-Etiqueta '' 20 141 420 18
    $lblAuto.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 60)
    $f.Controls.Add($lblAuto)

    $f.Controls.Add((Nueva-Etiqueta 'Código de 6 dígitos' 20 168 300))
    $txtCodigo = New-Object System.Windows.Forms.TextBox
    $txtCodigo.Location  = New-Object System.Drawing.Point(20, 189)
    $txtCodigo.Size      = New-Object System.Drawing.Size(120, 24)
    $txtCodigo.MaxLength = 6
    $f.Controls.Add($txtCodigo)

    # Se autocompleta la dirección: mientras el teléfono muestra el código,
    # anuncia el servicio de vinculación por mDNS. Así solo hay que teclear
    # los 6 dígitos, que es lo único que el computador no puede adivinar.
    $btnDetectar = Nuevo-Boton 'Detectar' 310 112 120 26
    $btnDetectar.Add_Click({
        $d = Obtener-ServicioEmparejamiento
        if ($d) {
            $txtDir.Text     = $d
            $lblAuto.Text    = 'Teléfono detectado en la red.'
        } else {
            $lblAuto.ForeColor = [System.Drawing.Color]::FromArgb(160, 60, 0)
            $lblAuto.Text      = 'No se detectó. Escribe la dirección que muestra el teléfono.'
        }
    })
    $f.Controls.Add($btnDetectar)

    $lblEstado = Nueva-Etiqueta '' 20 222 420 18
    $f.Controls.Add($lblEstado)

    $resultado = [pscustomobject]@{ Exito = $false }

    $btnEmparejar = Nuevo-Boton 'Emparejar' 200 250 110
    $btnEmparejar.Add_Click({
        $dir = $txtDir.Text.Trim()
        $cod = $txtCodigo.Text.Trim()
        if ($dir -eq '' -or $cod -eq '') {
            $lblEstado.Text = 'Faltan la dirección o el código.'
            return
        }
        $lblEstado.Text = 'Emparejando…'
        $f.Refresh()
        $r = Invocar-Adb @('pair', $dir, $cod)
        Escribir-Log "adb pair $dir -> $($r.Trim())"
        if ($r -match 'Successfully paired') {
            $lblEstado.Text = 'Emparejado. Buscando el teléfono…'
            $f.Refresh()
            Buscar-PorMdns -SegundosEspera 8 | Out-Null
            $resultado.Exito = $true
            $f.Close()
        } else {
            $lblEstado.ForeColor = [System.Drawing.Color]::FromArgb(180, 0, 0)
            $lblEstado.Text = 'No se pudo emparejar. Revisa el código (caduca rápido).'
        }
    })
    $f.Controls.Add($btnEmparejar)

    $btnCancelar = Nuevo-Boton 'Cancelar' 320 250 110
    $btnCancelar.Add_Click({ $f.Close() })
    $f.Controls.Add($btnCancelar)

    $f.Add_Shown({
        $f.Activate()
        $d = Obtener-ServicioEmparejamiento
        if ($d) { $txtDir.Text = $d; $lblAuto.Text = 'Teléfono detectado en la red.' }
        $txtCodigo.Focus()
    })
    $f.ShowDialog() | Out-Null

    return $resultado.Exito
}

# ---------------------------------------------------------------------------
# Dialogo: no hay dispositivos
# ---------------------------------------------------------------------------

function Mostrar-SinDispositivos {
    param([array] $Detectados)

    $f = Nueva-Ventana 'Mirador' 470 340

    $f.Controls.Add((Nueva-Etiqueta 'No se encontró ningún celular listo' 20 18 420 -Negrita))

    $sinAutorizar = @($Detectados | Where-Object { $_.Estado -eq 'unauthorized' })
    if ($sinAutorizar.Count -gt 0) {
        $texto = "El celular está conectado pero falta autorizarlo.`n`nMira la pantalla del teléfono y toca «Permitir» en el aviso de depuración USB, luego presiona Reintentar."
    } else {
        $texto = "Opciones:`n`n• Si el celular tiene cable, conéctalo y presiona Reintentar.`n• Si solo funciona por Wi-Fi, enciende la Depuración inalámbrica en el teléfono y usa Emparejar.`n• Buscar en la red rastrea el puerto 5555 en toda la Wi-Fi por si cambió la IP."
    }

    $lbl = Nueva-Etiqueta $texto 20 46 420 130
    $f.Controls.Add($lbl)

    $lblEstado = Nueva-Etiqueta '' 20 182 420 18
    $f.Controls.Add($lblEstado)

    $accion = [pscustomobject]@{ Valor = 'cancelar' }

    $btnReintentar = Nuevo-Boton 'Reintentar' 20 250 110
    $btnReintentar.Add_Click({ $accion.Valor = 'reintentar'; $f.Close() })
    $f.Controls.Add($btnReintentar)

    $btnEmparejar = Nuevo-Boton 'Emparejar Wi-Fi' 140 250 130
    $btnEmparejar.Add_Click({ $accion.Valor = 'emparejar'; $f.Close() })
    $f.Controls.Add($btnEmparejar)

    $btnBuscar = Nuevo-Boton 'Buscar en la red' 20 212 130 26
    $btnBuscar.Add_Click({
        $lblEstado.Text = 'Rastreando la red…'
        $f.Refresh()
        if (Buscar-EnLaRed) { $accion.Valor = 'reintentar'; $f.Close() }
        else { $lblEstado.Text = 'No apareció ningún celular escuchando en el puerto 5555.' }
    })
    $f.Controls.Add($btnBuscar)

    $btnCancelar = Nuevo-Boton 'Cancelar' 320 250 110
    $btnCancelar.Add_Click({ $accion.Valor = 'cancelar'; $f.Close() })
    $f.Controls.Add($btnCancelar)

    $f.Add_Shown({ $f.Activate() })
    $f.ShowDialog() | Out-Null

    return $accion.Valor
}

# ---------------------------------------------------------------------------
# Dialogo: elegir dispositivo
# ---------------------------------------------------------------------------

function Mostrar-Selector {
    param([array] $Dispositivos)

    $f = Nueva-Ventana 'Elige el celular' 430 345

    $f.Controls.Add((Nueva-Etiqueta 'Hay varios celulares disponibles' 20 18 380 -Negrita))

    $lista = New-Object System.Windows.Forms.ListBox
    $lista.Location = New-Object System.Drawing.Point(20, 48)
    $lista.Size     = New-Object System.Drawing.Size(380, 195)
    $lista.Font     = New-Object System.Drawing.Font('Segoe UI', 10)

    foreach ($d in $Dispositivos) {
        $titulo = Titulo-De $d
        if (Obtener-VentanaDe $titulo) { $marca = '  ●  ya abierto' } else { $marca = '' }
        $lista.Items.Add(('{0}   ({1}){2}' -f $d.Nombre, $d.Enlace, $marca)) | Out-Null
    }
    $lista.SelectedIndex = 0
    $f.Controls.Add($lista)

    $eleccion = [pscustomobject]@{ Indice = -1 }

    $conectar = {
        if ($lista.SelectedIndex -ge 0) {
            $eleccion.Indice = $lista.SelectedIndex
            $f.Close()
        }
    }

    $lista.Add_DoubleClick($conectar)

    $btnConectar = Nuevo-Boton 'Conectar' 180 258 110
    $btnConectar.Add_Click($conectar)
    $f.Controls.Add($btnConectar)

    $btnCancelar = Nuevo-Boton 'Cancelar' 300 258 110
    $btnCancelar.Add_Click({ $f.Close() })
    $f.Controls.Add($btnCancelar)

    $f.AcceptButton = $btnConectar
    $f.Add_Shown({ $f.Activate(); $lista.Focus() })
    $f.ShowDialog() | Out-Null

    return $eleccion.Indice
}

# ---------------------------------------------------------------------------
# Lanzamiento
# ---------------------------------------------------------------------------

<#
    El titulo de la ventana identifica al aparato fisico, no a la conexion.
    Es lo que permite dos telefonos abiertos a la vez y, al volver a hacer
    clic en el icono, traer al frente el correcto en vez de bloquear el
    segundo (que es lo que hacian las dos versiones anteriores).
#>
function Titulo-De {
    # Sin acentos ni guiones largos a proposito: el titulo viaja como
    # argumento a scrcpy y luego se compara contra MainWindowTitle. Si un
    # caracter se transforma por el camino, la comparacion falla en silencio
    # y se abren ventanas duplicadas del mismo telefono.
    param($Dispositivo)
    return ('{0} - Mirador' -f $Dispositivo.Nombre)
}

function Abrir-Celular {
    param($Dispositivo)

    $titulo = Titulo-De $Dispositivo

    $ventana = Obtener-VentanaDe $titulo
    if ($ventana) {
        Escribir-Log "Ya estaba abierto: $titulo"
        Traer-AlFrente $ventana
        return
    }

    # El titulo va entre comillas a proposito. Start-Process -ArgumentList
    # une los argumentos con espacios y NO los entrecomilla, asi que un
    # titulo como "TECNO KL4 - Mirador" le llega a scrcpy partido en
    # cinco argumentos y muere con "Unexpected additional argument: KL4".
    # El sintoma es cruel: el script registra que lanzo scrcpy, termina bien
    # y no se abre ninguna ventana.
    $argumentos = @('-s', $Dispositivo.Id, '--window-title', ('"{0}"' -f $titulo))

    if ($Dispositivo.EsWifi) {
        # Por Wi-Fi se limita la resolucion, no el bitrate: bajar el bitrate
        # ensucia la imagen en toda la pantalla, mientras que limitar el
        # tamano reduce los datos sin que se note en un telefono.
        $argumentos += @('--max-size', '1280')
    }

    Escribir-Log "scrcpy $($argumentos -join ' ')"
    Start-Process $script:ScrcpyExe -ArgumentList $argumentos -WindowStyle Hidden

    Recordar-Dispositivo $Dispositivo.Serial $Dispositivo.Nombre $Dispositivo.DireccionWifi
}

# ---------------------------------------------------------------------------
# Flujo principal
# ---------------------------------------------------------------------------

if (-not (Asegurar-Scrcpy)) { Escribir-Log 'Sin scrcpy, se termina'; exit 1 }

Invocar-Adb @('start-server') | Out-Null

if ($Emparejar) { Mostrar-Emparejamiento | Out-Null }

$listos = @()

for ($intento = 1; $intento -le 6; $intento++) {

    $crudos = @(Obtener-Dispositivos)
    Limpiar-Muertos $crudos

    $listos = @($crudos | Where-Object { $_.Estado -eq 'device' })

    if ($listos.Count -gt 0) { break }

    # Cascada de recuperacion, de lo barato a lo caro. Cada paso se intenta
    # una sola vez; si ninguno funciona se le pregunta al usuario en vez de
    # rendirse, que es lo que dejaba bloqueado el script anterior.
    $recuperado = $false

    switch ($intento) {
        1 {
            Escribir-Log 'Paso 1: cache'
            $recuperado = Reconectar-DesdeCache
        }
        2 {
            Escribir-Log 'Paso 2: mDNS'
            $recuperado = Buscar-PorMdns -SegundosEspera 4
        }
        3 {
            Escribir-Log 'Paso 3: barrido de la red'
            $recuperado = Buscar-EnLaRed
        }
        default {
            $accion = Mostrar-SinDispositivos $crudos
            Escribir-Log "Usuario eligio: $accion"
            if ($accion -eq 'cancelar') { exit 0 }
            if ($accion -eq 'emparejar') { Mostrar-Emparejamiento | Out-Null }
            $recuperado = $true
        }
    }

    Escribir-Log "Intento $intento recupero algo: $recuperado"
}

if ($listos.Count -eq 0) {
    Mostrar-Mensaje "No se pudo conectar con ningún celular.`n`nEl detalle quedó en:`n$($script:ArchivoLog)" 'Mirador' 'Error'
    Escribir-Log 'Sin dispositivos tras agotar la cascada'
    exit 1
}

$listos  = @(Completar-Datos $listos)
$equipos = @(Unificar-Dispositivos $listos)

Escribir-Log ("Disponibles: " + (($equipos | ForEach-Object { "$($_.Nombre)/$($_.Enlace)" }) -join ', '))

# Un telefono por cable y sin version inalambrica: se ofrece dejarlo listo
# para la proxima vez, que es cuando el cable puede no estar.
foreach ($e in @($equipos | Where-Object { $_.Enlace -eq 'USB' })) {
    $conocido = Leer-Estado | Where-Object { $_.serial -eq $e.Serial } | Select-Object -First 1
    if (-not $conocido -or [string]::IsNullOrWhiteSpace($conocido.direccion)) {
        $r = [System.Windows.Forms.MessageBox]::Show(
            "«$($e.Nombre)» está por cable.`n`n¿Quieres dejarlo habilitado por Wi-Fi para poder verlo sin cable la próxima vez?",
            'Mirador', 'YesNo', 'Question')
        if ($r -eq 'Yes') {
            $direccion = Pasar-AWifi $e.Id
            if ($direccion) {
                $e.DireccionWifi = $direccion
                Escribir-Log "Habilitado por Wi-Fi: $direccion"
            } else {
                Mostrar-Mensaje "No se pudo activar el Wi-Fi en «$($e.Nombre)». Revisa que esté conectado a una red." 'Mirador' 'Warning'
            }
        }
    }
}

if ($equipos.Count -eq 1 -and -not $Elegir) {
    Abrir-Celular $equipos[0]
    exit 0
}

$indice = Mostrar-Selector $equipos
if ($indice -lt 0) { Escribir-Log 'Cancelado en el selector'; exit 0 }

Abrir-Celular $equipos[$indice]
exit 0
