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
    $ico = Obtener-Icono
    if ($ico) { $f.Icon = $ico }
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

<#
    El icono de la aplicacion. Sin esto las ventanas salen con el icono de
    PowerShell, que es lo primero que delata que esto es un script y no un
    programa. Se busca en los dos sitios donde puede estar: junto al script
    (como queda instalado) y en recursos\ (como esta en el repositorio).
#>
$script:IconoApp = $null
function Obtener-Icono {
    if ($script:IconoApp) { return $script:IconoApp }
    foreach ($ruta in @(
        (Join-Path $PSScriptRoot 'mirador.ico'),
        (Join-Path $PSScriptRoot 'recursos\mirador.ico')
    )) {
        if (Test-Path $ruta) {
            try { $script:IconoApp = New-Object System.Drawing.Icon($ruta); return $script:IconoApp }
            catch { Escribir-Log "No se pudo cargar el icono: $($_.Exception.Message)" }
        }
    }
    return $null
}

<#
    Encabezado de ventana: franja blanca con el titulo grande y una linea de
    apoyo en gris. Da jerarquia sin pedirle al usuario que lea todo el cuerpo
    para entender de que se trata la ventana.

    Devuelve la Y donde puede empezar el contenido.
#>
function Nuevo-Encabezado {
    param(
        [System.Windows.Forms.Form] $Ventana,
        [string] $Titulo,
        [string] $Subtitulo = ''
    )

    $alto = if ($Subtitulo) { 66 } else { 50 }

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location  = New-Object System.Drawing.Point(0, 0)
    $panel.Size      = New-Object System.Drawing.Size($Ventana.ClientSize.Width, $alto)
    $panel.BackColor = [System.Drawing.Color]::White
    $Ventana.Controls.Add($panel)

    $lblT = New-Object System.Windows.Forms.Label
    $lblT.Text      = $Titulo
    $lblT.Location  = New-Object System.Drawing.Point(20, 14)
    $lblT.Size      = New-Object System.Drawing.Size(($Ventana.ClientSize.Width - 40), 24)
    $lblT.Font      = New-Object System.Drawing.Font('Segoe UI Semibold', 12)
    $lblT.ForeColor = [System.Drawing.Color]::FromArgb(23, 23, 23)
    $panel.Controls.Add($lblT)

    if ($Subtitulo) {
        $lblS = New-Object System.Windows.Forms.Label
        $lblS.Text      = $Subtitulo
        $lblS.Location  = New-Object System.Drawing.Point(20, 40)
        $lblS.Size      = New-Object System.Drawing.Size(($Ventana.ClientSize.Width - 40), 18)
        $lblS.ForeColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
        $panel.Controls.Add($lblS)
    }

    # La linea de separacion se dibuja como un panel de 1 pixel: es lo mas
    # barato que se ve bien en los dos temas de Windows.
    $linea = New-Object System.Windows.Forms.Panel
    $linea.Location  = New-Object System.Drawing.Point(0, ($alto - 1))
    $linea.Size      = New-Object System.Drawing.Size($Ventana.ClientSize.Width, 1)
    $linea.BackColor = [System.Drawing.Color]::FromArgb(222, 222, 222)
    $Ventana.Controls.Add($linea)
    $linea.BringToFront()

    return ($alto + 14)
}

<#
    Barra de botones alineada a la DERECHA, todos del mismo ancho.

    Es la regla que ordena las ventanas: antes cada boton tenia su ancho y su
    posicion propia -110, 130, 150, 250- y los bordes no coincidian con nada.
    Windows pone las acciones abajo a la derecha y la principal de ultima; con
    esto todas las ventanas de Mirador se ven iguales sin tener que calcular
    coordenadas a mano en cada una.

    $Definiciones: arreglo de hashtables @{ Texto = '...'; Accion = { ... } }.
    Devuelve los botones creados, en el mismo orden.
#>
function Nueva-BarraBotones {
    param(
        [System.Windows.Forms.Form] $Ventana,
        [array] $Definiciones,
        [int] $Y,
        [int] $Ancho = 150,
        [int] $Alto = 32,
        [int] $Separacion = 10,
        [int] $Margen = 20
    )

    $n     = $Definiciones.Count
    $total = ($n * $Ancho) + (($n - 1) * $Separacion)
    $x     = $Ventana.ClientSize.Width - $Margen - $total

    $creados = @()
    foreach ($d in $Definiciones) {
        $b = Nuevo-Boton $d.Texto $x $Y $Ancho $Alto
        if ($d.Accion) { $b.Add_Click($d.Accion) }
        $Ventana.Controls.Add($b)
        $creados += $b
        $x += $Ancho + $Separacion
    }
    return $creados
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

function Hay-Scrcpy { return [bool] (Get-Command $script:ScrcpyExe -ErrorAction SilentlyContinue) }
function Hay-Adb    { return [bool] (Get-Command $script:AdbExe    -ErrorAction SilentlyContinue) }

<#
    Deja el COMPUTADOR listo: scrcpy y adb.

    adb no viene con Windows — lo trae el paquete de scrcpy, en su misma
    carpeta. Por eso casi siempre aparecen juntos... pero no siempre: un
    scrcpy descomprimido a mano desde un .zip, o un atajo roto, deja scrcpy
    en el PATH y adb fuera.

    Comprobar solo scrcpy hacia que Mirador arrancara creyendo que todo
    estaba bien y fallara mas adelante disfrazado de "no se encontro ningun
    celular", que manda al usuario a revisar el telefono cuando el problema
    estaba en el computador.
#>
function Asegurar-Scrcpy {
    if ((Hay-Scrcpy) -and (Hay-Adb)) { return $true }

    if ((Hay-Scrcpy) -and -not (Hay-Adb)) {
        Escribir-Log 'scrcpy esta pero adb no'
        $r = [System.Windows.Forms.MessageBox]::Show(
            "Tienes scrcpy, pero falta «adb», que es la pieza que habla con el teléfono.`n`nWindows no lo trae: viene dentro del mismo paquete de scrcpy.`n`n¿Quieres que lo instale ahora?",
            'Mirador', 'YesNo', 'Warning')
        if ($r -ne 'Yes') {
            Escribir-Log 'El usuario no quiso instalar adb'
            return $false
        }
    } else {
        Escribir-Log 'scrcpy no esta instalado'
    }

    # winget primero: instala sin pedir permisos de administrador.
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Mostrar-Mensaje "scrcpy no está instalado. Se va a instalar una sola vez; puede tardar un par de minutos."
        Escribir-Log 'Instalando con winget'
        & winget install --id Genymobile.scrcpy --exact --silent `
            --accept-source-agreements --accept-package-agreements | Out-Null
        Refrescar-Path
        if ((Hay-Scrcpy) -and (Hay-Adb)) {
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
        # -WindowStyle Hidden tambien aca: sin el, la instancia elevada
        # arrancaba con la consola negra a la vista, que es justo lo que el
        # resto del programa evita.
        Start-Process powershell -Verb RunAs -ArgumentList `
            "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
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

    if (-not ((Hay-Scrcpy) -and (Hay-Adb))) {
        $falta = if (Hay-Scrcpy) { 'adb' } else { 'scrcpy' }
        Mostrar-Mensaje "No se pudo dejar listo «$falta».`n`nInstálalo a mano con este comando y vuelve a abrir Mirador:`n`nwinget install Genymobile.scrcpy" 'Mirador' 'Error'
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
    $f = Nueva-Ventana 'Emparejar por Wi-Fi' 500 424

    $y = Nuevo-Encabezado $f 'Emparejar por Wi-Fi' 'Se hace una sola vez con cada teléfono'

    $f.Controls.Add((Nueva-Etiqueta 'En el teléfono:' 20 $y 444 -Negrita))
    $f.Controls.Add((Nueva-Etiqueta "Ajustes › Opciones de desarrollador › Depuración inalámbrica ›`nVincular dispositivo con código de vinculación" 20 ($y + 23) 444 40))

    $f.Controls.Add((Nueva-Etiqueta 'Dirección y puerto de vinculación' 20 ($y + 77) 300))
    $txtDir = New-Object System.Windows.Forms.TextBox
    $txtDir.Location = New-Object System.Drawing.Point(20, ($y + 98))
    $txtDir.Size     = New-Object System.Drawing.Size(280, 24)
    $f.Controls.Add($txtDir)

    $lblAuto = Nueva-Etiqueta '' 20 ($y + 126) 444 18
    $lblAuto.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 60)
    $f.Controls.Add($lblAuto)

    $f.Controls.Add((Nueva-Etiqueta 'Código de 6 dígitos' 20 ($y + 153) 300))
    $txtCodigo = New-Object System.Windows.Forms.TextBox
    $txtCodigo.Location  = New-Object System.Drawing.Point(20, ($y + 174))
    $txtCodigo.Size      = New-Object System.Drawing.Size(120, 24)
    $txtCodigo.MaxLength = 6
    $f.Controls.Add($txtCodigo)

    # Se autocompleta la dirección: mientras el teléfono muestra el código,
    # anuncia el servicio de vinculación por mDNS. Así solo hay que teclear
    # los 6 dígitos, que es lo único que el computador no puede adivinar.
    $btnDetectar = Nuevo-Boton 'Detectar' 310 ($y + 97) 120 26
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

    $lblEstado = Nueva-Etiqueta '' 20 ($y + 207) 444 18
    $f.Controls.Add($lblEstado)

    $resultado = [pscustomobject]@{ Exito = $false }

    $btnEmparejar = Nuevo-Boton 'Emparejar' 344 ($y + 239) 140 32
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

    $btnCancelar = Nuevo-Boton 'Cancelar' 194 ($y + 239) 140 32
    $btnCancelar.Add_Click({ $f.Close() })
    $f.Controls.Add($btnCancelar)
    $f.CancelButton = $btnCancelar
    $f.AcceptButton = $btnEmparejar

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
# Guias de preparacion del telefono, por marca
# ---------------------------------------------------------------------------

<#
    Rutas de menu verificadas contra la documentacion de cada fabricante el
    2026-09-15.

    El nombre del menu CAMBIA por marca, y ese es el punto entero de esta
    tabla: en Xiaomi los siete toques van sobre "Version de MIUI" y no sobre
    "Numero de compilacion", y las Opciones de desarrollador viven bajo
    "Ajustes adicionales", no al final de Ajustes.

    Cada marca es una fila. Agregar una marca nueva es agregar una fila, no
    tocar el dialogo.

    La fila de TECNO/Infinix NO sale de documentacion: de esa marca solo hay
    videos. Se verifico sobre un TECNO KL4 con HiOS 14 real, leyendo el menu
    con adb, y ahi aparecio que "Acerca del telefono" se llama "Mi telefono"
    y que no existe el submenu "Informacion de software" que si tienen otras
    marcas. La ruta que estaba escrita de memoria era incorrecta.

    Para el resto de casos esta el boton "No veo esa opcion", que aplica a
    TODAS las marcas: el menu real cambia entre versiones del mismo
    fabricante, y quedarse sin salida es peor que una ruta imperfecta.
#>

$script:RutaGenerica = "Ajustes  ›  Acerca del teléfono`n`nToca 7 veces seguidas sobre «Número de compilación».`n`nSi no encuentras el menú, abre Ajustes y usa el buscador (la lupa de arriba): escribe «compilación» para el primer paso, o «desarrollador» para el segundo."

$script:GuiasPorMarca = [ordered]@{
    'Samsung' = @{
        Activar = "Ajustes  ›  Información del teléfono  ›  Información del software`n`nToca 7 veces seguidas sobre «Número de compilación»."
        Depurar = "Ajustes  ›  Opciones de desarrollador`n(queda hasta abajo del todo en Ajustes)`n`nEnciende «Depuración USB»."
    }
    'Xiaomi / Redmi / POCO' = @{
        Activar = "Ajustes  ›  Sobre el teléfono`n`nToca 7 veces seguidas sobre «Versión de MIUI» (o «Versión de HyperOS»).`n`nOjo: en Xiaomi NO se toca «Número de compilación» como en el resto."
        Depurar = "Ajustes  ›  Ajustes adicionales  ›  Opciones de desarrollador`n`nEnciende «Depuración USB»."
    }
    'Motorola' = @{
        Activar = "Ajustes  ›  Acerca del teléfono`n`nToca 7 veces seguidas sobre «Número de compilación».`n`nEn los modelos nuevos está en Ajustes › Sistema › Acerca del teléfono."
        Depurar = "Ajustes  ›  Sistema  ›  Opciones de desarrollador`n`nEnciende «Depuración USB»."
    }
    'Huawei / Honor' = @{
        Activar = "Ajustes  ›  Acerca del teléfono`n`nToca 7 veces seguidas sobre «Número de compilación».`n`nTe va a pedir el PIN o el patrón de desbloqueo antes de activarlo."
        Depurar = "Ajustes  ›  Sistema y actualizaciones  ›  Opciones de desarrollador`n`nEnciende «Depuración USB»."
    }
    'Oppo / realme' = @{
        Activar = "Ajustes  ›  Información del teléfono`n`nToca 7 veces seguidas sobre «Número de compilación» (en algunas versiones está dentro de «Versión»)."
        Depurar = "ColorOS 12 o más nuevo:`nAjustes  ›  Ajustes del sistema  ›  Opciones de desarrollador`n`nColorOS 11 o anterior:`nAjustes  ›  Ajustes adicionales  ›  Opciones de desarrollador`n`nEnciende «Depuración USB»."
    }
    'TECNO / Infinix' = @{
        Activar = "Ajustes  ›  Mi teléfono`n`nEn HiOS y XOS, «Acerca del teléfono» se llama «Mi teléfono».`n`nBaja hasta abajo y toca 7 veces seguidas sobre «Número de compilación», que está al lado de «Versión de HiOS»."
        Depurar = "Ajustes  ›  Sistema  ›  Opciones de desarrollador`n`nEnciende «Depuración USB»."
    }
    'Google Pixel' = @{
        Activar = "Ajustes  ›  Acerca del teléfono`n`nToca 7 veces seguidas sobre «Número de compilación»."
        Depurar = "Ajustes  ›  Sistema  ›  Opciones para desarrolladores`n`nEnciende «Depuración USB»."
    }
    'Otra marca' = @{
        Activar = "Ajustes  ›  Acerca del teléfono`n`nToca 7 veces seguidas sobre «Número de compilación».`n`nCasi todas las marcas lo tienen ahí. Si no aparece, usa el buscador de Ajustes (la lupa) y escribe «compilación»."
        Depurar = "Ajustes  ›  Sistema  ›  Opciones de desarrollador`n`nSi no aparece, usa el buscador de Ajustes (la lupa) y escribe «desarrollador».`n`nEnciende «Depuración USB»."
    }
}

<#
    Traduce lo que reporta el fabricante a una de las filas de la tabla.

    Solo sirve cuando adb YA ve el telefono: si la depuracion todavia no esta
    activa no hay aparato que consultar, que es justamente el caso que este
    asistente viene a resolver. Por eso es una sugerencia y no una deteccion:
    la marca siempre la termina eligiendo el usuario.
#>
function Marca-Sugerida {
    param([string] $Fabricante)

    if ([string]::IsNullOrWhiteSpace($Fabricante)) { return '' }

    switch -Wildcard ($Fabricante.ToLower()) {
        '*samsung*'  { return 'Samsung' }
        '*xiaomi*'   { return 'Xiaomi / Redmi / POCO' }
        '*redmi*'    { return 'Xiaomi / Redmi / POCO' }
        '*poco*'     { return 'Xiaomi / Redmi / POCO' }
        '*motorola*' { return 'Motorola' }
        '*lenovo*'   { return 'Motorola' }
        '*huawei*'   { return 'Huawei / Honor' }
        '*honor*'    { return 'Huawei / Honor' }
        '*oppo*'     { return 'Oppo / realme' }
        '*realme*'   { return 'Oppo / realme' }
        '*oneplus*'  { return 'Oppo / realme' }
        '*tecno*'    { return 'TECNO / Infinix' }
        '*infinix*'  { return 'TECNO / Infinix' }
        '*google*'   { return 'Google Pixel' }
        default      { return '' }
    }
}

# ---------------------------------------------------------------------------
# Dialogo: elegir la marca del telefono
# ---------------------------------------------------------------------------

function Mostrar-ElegirMarca {
    param([string] $Sugerida)

    $f = Nueva-Ventana 'Preparar mi teléfono' 456 382

    $y = Nuevo-Encabezado $f '¿Qué marca es tu teléfono?' 'El menú se llama distinto en cada marca'

    # Sin esta linea el usuario no tiene como saber que del lado del PC no le
    # falta nada: scrcpy y adb ya quedaron instalados antes de llegar aca.
    $f.Controls.Add((Nueva-Etiqueta 'El computador ya quedó listo. Esto es solo el teléfono.' 20 $y 400 18))
    $y = $y + 26

    $lista = New-Object System.Windows.Forms.ListBox
    $lista.Location = New-Object System.Drawing.Point(20, $y)
    $lista.Size     = New-Object System.Drawing.Size(400, 152)
    $lista.BorderStyle = 'FixedSingle'
    foreach ($m in $script:GuiasPorMarca.Keys) { $lista.Items.Add($m) | Out-Null }

    if ($Sugerida -and $lista.Items.Contains($Sugerida)) {
        $lista.SelectedItem = $Sugerida
    } else {
        $lista.SelectedIndex = 0
    }
    $f.Controls.Add($lista)

    $elegido = [pscustomobject]@{ Valor = '' }

    # Doble clic sobre la marca hace lo mismo que Siguiente: es lo que la
    # gente intenta sin pensarlo.
    $lista.Add_DoubleClick({ $elegido.Valor = [string] $lista.SelectedItem; $f.Close() })

    $botones = Nueva-BarraBotones $f @(
        @{ Texto = 'Cancelar';  Accion = { $elegido.Valor = ''; $f.Close() } },
        @{ Texto = 'Siguiente'; Accion = { $elegido.Valor = [string] $lista.SelectedItem; $f.Close() } }
    ) 278 140
    $f.CancelButton = $botones[0]
    $f.AcceptButton = $botones[1]

    $f.Add_Shown({ $f.Activate() })
    $f.ShowDialog() | Out-Null

    return $elegido.Valor
}

# ---------------------------------------------------------------------------
# Dialogo: los dos pasos de la guia
# ---------------------------------------------------------------------------

<#
    Los dos pasos van en UNA sola pantalla a proposito. Son cortos y se hacen
    seguidos, con el telefono en la mano: partirlos en dos ventanas agrega
    clics sin agregar claridad.
#>
function Mostrar-GuiaMarca {
    param([string] $Marca)

    $guia = $script:GuiasPorMarca[$Marca]
    $f    = Nueva-Ventana "Preparar mi teléfono" 556 540

    $y = Nuevo-Encabezado $f "Preparar un $Marca" 'Dos pasos, una sola vez'

    $f.Controls.Add((Nueva-Etiqueta "Paso 1 · Activa las Opciones de desarrollador" 20 $y 500 -Negrita))
    $f.Controls.Add((Nueva-Etiqueta $guia.Activar 20 ($y + 24) 500 112))

    $f.Controls.Add((Nueva-Etiqueta "Paso 2 · Enciende la depuración" 20 ($y + 146) 500 -Negrita))
    $f.Controls.Add((Nueva-Etiqueta $guia.Depurar 20 ($y + 170) 500 115))

    $f.Controls.Add((Nueva-Etiqueta "Para usarlo sin cable, enciende además «Depuración inalámbrica» en esa misma pantalla. Necesita Android 11 o superior." 20 ($y + 299) 500 46))

    $accion = [pscustomobject]@{ Valor = 'cancelar' }

    # "No veo esa opcion" es la salida de emergencia, y aplica a todas las
    # marcas: el menu real cambia entre versiones del mismo fabricante, y
    # quedarse sin salida es peor que una ruta imperfecta.
    $botones = Nueva-BarraBotones $f @(
        @{ Texto = 'No veo esa opción'; Accion = {
            Mostrar-Mensaje "Ruta que sirve en casi todos los Android:`n`n$($script:RutaGenerica)" 'Preparar mi teléfono'
        } },
        @{ Texto = 'Atrás';                   Accion = { $accion.Valor = 'atras';      $f.Close() } },
        @{ Texto = 'Listo, busca mi teléfono'; Accion = { $accion.Valor = 'reintentar'; $f.Close() } }
    ) 448 160
    $f.AcceptButton = $botones[2]

    $f.Add_Shown({ $f.Activate() })
    $f.ShowDialog() | Out-Null

    return $accion.Valor
}

# ---------------------------------------------------------------------------
# Asistente completo de preparacion
# ---------------------------------------------------------------------------

function Mostrar-Preparacion {
    param([array] $Detectados)

    $sugerida = ''
    foreach ($d in @($Detectados)) {
        if ($d.Estado -eq 'device') {
            $sugerida = Marca-Sugerida (Obtener-Propiedad $d.Id 'ro.product.manufacturer')
            if ($sugerida) { break }
        }
    }
    if ($sugerida) { Escribir-Log "Marca sugerida por adb: $sugerida" }

    while ($true) {
        $marca = Mostrar-ElegirMarca $sugerida
        if ([string]::IsNullOrWhiteSpace($marca)) {
            Escribir-Log 'Preparacion cancelada en la eleccion de marca'
            return 'cancelar'
        }

        Escribir-Log "Guia de preparacion mostrada: $marca"
        $r = Mostrar-GuiaMarca $marca
        if ($r -ne 'atras') { return $r }

        $sugerida = $marca
    }
}

# ---------------------------------------------------------------------------
# Diagnostico: revisar el equipo y decir que falta
# ---------------------------------------------------------------------------

<#
    El registro en mirador.log sirve para quien sabe leerlo. Para el resto no
    existe: decirle "abre el .log con el Bloc de notas" equivale a no decir
    nada.

    Esta seccion recorre las mismas condiciones que el log deja escritas, pero
    las responde en espanol y con la accion concreta al lado. Cada chequeo
    devuelve un objeto, no texto, para que la ventana decida como pintarlo y
    para poder contar cuantos fallaron.
#>

function Nuevo-Chequeo {
    param(
        [string] $Titulo,
        [ValidateSet('ok', 'aviso', 'falla')] [string] $Estado,
        [string] $Detalle = '',
        [string] $Sugerencia = ''
    )
    return [pscustomobject]@{
        Titulo     = $Titulo
        Estado     = $Estado
        Detalle    = $Detalle
        Sugerencia = $Sugerencia
    }
}

<#
    Responde si un puerto TCP acepta conexion, sin colgar la ventana.

    Test-NetConnection haria lo mismo, pero su tiempo de espera no se puede
    bajar y tarda varios segundos por direccion muerta, que es justo el caso
    frecuente aqui: el telefono que ya no esta en la red.
#>
function Responde-Puerto {
    param([string] $Direccion, [int] $Puerto, [int] $Milisegundos = 800)

    $cliente = New-Object System.Net.Sockets.TcpClient
    try {
        $intento = $cliente.BeginConnect($Direccion, $Puerto, $null, $null)
        if (-not $intento.AsyncWaitHandle.WaitOne($Milisegundos, $false)) { return $false }
        $cliente.EndConnect($intento)
        return $true
    } catch {
        return $false
    } finally {
        $cliente.Close()
    }
}

function Obtener-IPsLocales {
    try {
        $todas = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' })

        # Los adaptadores virtuales -WSL, Hyper-V, VirtualBox- aparecen como
        # una red mas y confunden: el usuario ve una IP que no es la suya.
        # Una VPN, en cambio, NO se filtra a proposito: es justo la causa que
        # este chequeo existe para descubrir.
        $reales = @($todas | Where-Object {
            $_.InterfaceAlias -notmatch 'vEthernet|WSL|Hyper-V|VirtualBox|VMware|Loopback'
        })
        if ($reales.Count -eq 0) { $reales = $todas }

        return @($reales | Select-Object -ExpandProperty IPAddress)
    } catch {
        Escribir-Log "No se pudieron leer las IPs locales: $($_.Exception.Message)"
        return @()
    }
}

function Misma-Red {
    param([string] $Una, [string] $Otra)
    $a = $Una  -split '\.'
    $b = $Otra -split '\.'
    if ($a.Count -ne 4 -or $b.Count -ne 4) { return $false }
    return ("$($a[0]).$($a[1]).$($a[2])" -eq "$($b[0]).$($b[1]).$($b[2])")
}

function Probar-Requisitos {
    $r = @()

    # --- 1. scrcpy
    $scrcpy = Get-Command $script:ScrcpyExe -ErrorAction SilentlyContinue
    if ($scrcpy) {
        $r += Nuevo-Chequeo 'scrcpy instalado' 'ok' $scrcpy.Source
    } else {
        $r += Nuevo-Chequeo 'scrcpy instalado' 'falla' 'No se encontró scrcpy en el equipo.' `
            'Cierra Mirador y ábrelo otra vez: lo instala solo la primera vez.'
    }

    # --- 2. adb
    $version = (Invocar-Adb @('version')).Trim()
    if ($version) {
        $primera = @($version -split "`r?`n")[0]
        $r += Nuevo-Chequeo 'adb responde' 'ok' $primera
    } else {
        $r += Nuevo-Chequeo 'adb responde' 'falla' 'adb no contestó.' `
            'Viene junto con scrcpy. Cierra Mirador y ábrelo otra vez.'
    }

    # --- 3. telefonos que ve adb
    $dispositivos   = @(Obtener-Dispositivos)
    $listos         = @($dispositivos | Where-Object { $_.Estado -eq 'device' })
    $sinAutorizar   = @($dispositivos | Where-Object { $_.Estado -eq 'unauthorized' })
    $desconectados  = @($dispositivos | Where-Object { $_.Estado -eq 'offline' })

    if ($listos.Count -gt 0) {
        $nombres = ($listos | ForEach-Object { if ($_.Modelo) { $_.Modelo } else { $_.Id } }) -join ', '
        $r += Nuevo-Chequeo 'Teléfonos listos' 'ok' "$($listos.Count): $nombres"
    } elseif ($dispositivos.Count -eq 0) {
        $r += Nuevo-Chequeo 'Teléfonos listos' 'falla' 'adb no ve ningún teléfono.' `
            'Conecta el cable, o usa «Preparar mi teléfono» si es la primera vez con este celular.'
    } else {
        $r += Nuevo-Chequeo 'Teléfonos listos' 'falla' "Ninguno listo, de $($dispositivos.Count) que adb alcanza a ver." `
            'Mira los dos puntos siguientes.'
    }

    if ($sinAutorizar.Count -gt 0) {
        $r += Nuevo-Chequeo 'Autorización del teléfono' 'falla' `
            "$($sinAutorizar.Count) conectado(s) pero sin autorizar." `
            'Mira la pantalla del teléfono: hay un aviso pidiendo permiso. Toca «Permitir» y marca «Siempre».'
    }

    if ($desconectados.Count -gt 0) {
        $r += Nuevo-Chequeo 'Conexión perdida' 'aviso' `
            "$($desconectados.Count) aparece(n) como «offline»." `
            'Desconecta el cable y vuelve a conectarlo. Si es por Wi-Fi, el teléfono pudo reiniciarse.'
    }

    # --- 4. la red del PC
    $ips = @(Obtener-IPsLocales)
    if ($ips.Count -gt 0) {
        $r += Nuevo-Chequeo 'Red del computador' 'ok' ($ips -join ', ')
    } else {
        $r += Nuevo-Chequeo 'Red del computador' 'falla' 'El computador no aparece conectado a ninguna red.' `
            'Conéctalo al Wi-Fi. Sin red solo vas a poder usar el cable.'
    }

    # --- 5. los telefonos recordados
    #
    # Aca esta el diagnostico que nadie hace a mano: comparar la red del PC con
    # la del telefono guardado. Un PC con VPN encendida, o en una red de
    # invitados, ve todo "normal" y no conecta nunca.
    foreach ($c in @(Leer-Estado)) {
        if ([string]::IsNullOrWhiteSpace($c.direccion)) { continue }
        $etiqueta = if ($c.nombre) { $c.nombre } else { $c.serial }

        if ($c.direccion -match '^(\d{1,3}(?:\.\d{1,3}){3}):(\d+)$') {
            $ip     = $Matches[1]
            $puerto = [int] $Matches[2]

            if ($ips.Count -gt 0 -and -not @($ips | Where-Object { Misma-Red $_ $ip }).Count) {
                $r += Nuevo-Chequeo "Teléfono recordado: $etiqueta" 'falla' `
                    "El teléfono quedó en $ip y el computador está en $($ips -join ', ')." `
                    'Están en redes distintas. Conecta los dos al mismo Wi-Fi, y si tienes una VPN encendida en el computador, apágala.'
            } elseif (Responde-Puerto $ip $puerto) {
                $r += Nuevo-Chequeo "Teléfono recordado: $etiqueta" 'ok' "Responde en $($c.direccion)."
            } else {
                $r += Nuevo-Chequeo "Teléfono recordado: $etiqueta" 'aviso' `
                    "No responde en $($c.direccion)." `
                    'Seguramente le cambió la IP o se apagó la depuración. Mirador lo busca solo por su nombre de red; si no aparece, usa «Emparejar Wi-Fi».'
            }
        } else {
            $r += Nuevo-Chequeo "Teléfono recordado: $etiqueta" 'ok' `
                'Guardado por nombre de red, que no cambia aunque cambie la IP.'
        }
    }

    # --- 6. la conexion sin cable
    #
    # "adb mdns services" lista lo que se anuncia EN ESE MOMENTO, y un telefono
    # ya conectado puede no figurar ahi: medido con dos telefonos trabajando por
    # Wi-Fi, la lista salio vacia. Por eso se mira primero si ya hay alguno
    # conectado sin cable. Decirle "enciende la depuracion inalambrica" a quien
    # la tiene encendida es peor que no decir nada.
    $inalambricos = @($dispositivos | Where-Object { $_.EsWifi -and $_.Estado -eq 'device' })
    $mdns         = (Invocar-Adb @('mdns', 'services'))
    $anuncios     = @($mdns -split "`r?`n" | Where-Object { $_ -match '_adb' })

    if ($inalambricos.Count -gt 0) {
        $r += Nuevo-Chequeo 'Conexión sin cable' 'ok' "$($inalambricos.Count) teléfono(s) trabajando por Wi-Fi ahora mismo."
    } elseif ($anuncios.Count -gt 0) {
        $r += Nuevo-Chequeo 'Conexión sin cable' 'ok' "$($anuncios.Count) teléfono(s) anunciándose en la red, listos para conectar."
    } else {
        $r += Nuevo-Chequeo 'Conexión sin cable' 'aviso' `
            'Ningún teléfono se está anunciando en la red.' `
            'Es normal si lo vas a usar por cable. Para usarlo sin cable, enciende «Depuración inalámbrica» en el teléfono.'
    }

    return $r
}

# ---------------------------------------------------------------------------
# Dialogo: el resultado de la revision
# ---------------------------------------------------------------------------

function Formatear-Diagnostico {
    param([array] $Chequeos)

    $lineas = @()
    foreach ($c in $Chequeos) {
        $marca = switch ($c.Estado) { 'ok' { '[ok]' } 'aviso' { '[ !]' } default { '[XX]' } }
        $lineas += "$marca  $($c.Titulo)"
        if ($c.Detalle)    { $lineas += "      $($c.Detalle)" }
        if ($c.Sugerencia) { $lineas += "      -> $($c.Sugerencia)" }
        $lineas += ''
    }
    return ($lineas -join "`r`n")
}

function Mostrar-Diagnostico {
    $f = Nueva-Ventana 'Revisar mi equipo' 580 540

    $y = Nuevo-Encabezado $f 'Revisar mi equipo' 'Qué está listo y qué falta para conectar'

    $lblResumen = Nueva-Etiqueta 'Revisando…' 20 $y 524 20 -Negrita
    $f.Controls.Add($lblResumen)

    $caja = New-Object System.Windows.Forms.TextBox
    $caja.Location   = New-Object System.Drawing.Point(20, ($y + 28))
    $caja.Size       = New-Object System.Drawing.Size(524, 330)
    $caja.Multiline  = $true
    $caja.ReadOnly   = $true
    $caja.ScrollBars = 'Vertical'
    $caja.BackColor  = [System.Drawing.Color]::White
    $caja.Font       = New-Object System.Drawing.Font('Consolas', 9)
    $f.Controls.Add($caja)

    # La revision se hace con la ventana YA visible: algunos chequeos tocan la
    # red y tardan casi un segundo, y arrancar con la ventana en blanco parece
    # que se colgo.
    $revisar = {
        $lblResumen.Text = 'Revisando…'
        $caja.Text       = ''
        $f.Refresh()

        $chequeos = @(Probar-Requisitos)
        $fallas   = @($chequeos | Where-Object { $_.Estado -eq 'falla' }).Count
        $avisos   = @($chequeos | Where-Object { $_.Estado -eq 'aviso' }).Count

        $caja.Text = Formatear-Diagnostico $chequeos
        if ($fallas -gt 0) {
            $lblResumen.Text = "Hay $fallas cosa(s) que impiden conectar. Empieza por la primera marcada [XX]."
        } elseif ($avisos -gt 0) {
            $lblResumen.Text = "Todo lo esencial está bien. Hay $avisos aviso(s) sin importancia."
        } else {
            $lblResumen.Text = 'Todo en orden.'
        }
        Escribir-Log "Diagnostico: $fallas fallas, $avisos avisos"
    }

    $botones = Nueva-BarraBotones $f @(
        @{ Texto = 'Abrir el registro'; Accion = {
            if (Test-Path $script:ArchivoLog) { Start-Process notepad.exe $script:ArchivoLog }
            else { Mostrar-Mensaje 'Todavía no hay registro que abrir.' 'Revisar mi equipo' }
        } },
        @{ Texto = 'Revisar otra vez'; Accion = $revisar },
        @{ Texto = 'Cerrar';           Accion = { $f.Close() } }
    ) 448 150
    $f.CancelButton = $botones[2]
    $f.Add_Shown({ $f.Activate(); & $revisar })
    $f.ShowDialog() | Out-Null
}

# ---------------------------------------------------------------------------
# Dialogo: no hay dispositivos
# ---------------------------------------------------------------------------

function Mostrar-SinDispositivos {
    param([array] $Detectados)
    $f = Nueva-Ventana 'Mirador' 556 476

    $y = Nuevo-Encabezado $f 'No se encontró ningún celular' 'Elige cómo quieres continuar'

    $sinAutorizar = @($Detectados | Where-Object { $_.Estado -eq 'unauthorized' })
    if ($sinAutorizar.Count -gt 0) {
        $texto = "El celular está conectado pero falta autorizarlo.`n`nMira la pantalla del teléfono y toca «Permitir» en el aviso de depuración USB, luego presiona Reintentar."
    } else {
        $texto = "• ¿Primera vez con este celular? Empieza por Preparar mi teléfono: hay que activar la depuración una sola vez.`n• Si el celular tiene cable, conéctalo y presiona Reintentar.`n• Si solo funciona por Wi-Fi, enciende la Depuración inalámbrica en el teléfono y usa Emparejar.`n• Buscar en la red rastrea el puerto 5555 en toda la Wi-Fi por si cambió la IP."
    }

    $lbl = Nueva-Etiqueta $texto 20 $y 500 116
    $f.Controls.Add($lbl)

    $accion = [pscustomobject]@{ Valor = 'cancelar' }

    # La accion principal va sola y a todo el ancho: quien no encuentra su
    # telefono la primera vez casi siempre es porque no lo ha preparado, y las
    # otras cuatro opciones dan ese paso por hecho.
    $btnPreparar = Nuevo-Boton 'Preparar mi teléfono (primera vez)' 20 206 500 40
    $btnPreparar.Add_Click({ $accion.Valor = 'preparar'; $f.Close() })
    $f.Controls.Add($btnPreparar)

    $lblEstado = Nueva-Etiqueta '' 20 254 500 18
    $f.Controls.Add($lblEstado)

    # Las cuatro secundarias, todas del mismo ancho y en reja.
    $btnReintentar = Nuevo-Boton 'Reintentar' 20 280 240 34
    $btnReintentar.Add_Click({ $accion.Valor = 'reintentar'; $f.Close() })
    $f.Controls.Add($btnReintentar)

    $btnEmparejar = Nuevo-Boton 'Emparejar Wi-Fi' 280 280 240 34
    $btnEmparejar.Add_Click({ $accion.Valor = 'emparejar'; $f.Close() })
    $f.Controls.Add($btnEmparejar)

    $btnBuscar = Nuevo-Boton 'Buscar en la red' 20 322 240 34
    $btnBuscar.Add_Click({
        $lblEstado.Text = 'Rastreando la red…'
        $f.Refresh()
        if (Buscar-EnLaRed) { $accion.Valor = 'reintentar'; $f.Close() }
        else { $lblEstado.Text = 'No apareció ningún celular escuchando en el puerto 5555.' }
    })
    $f.Controls.Add($btnBuscar)

    $btnRevisar = Nuevo-Boton 'Revisar mi equipo' 280 322 240 34
    $btnRevisar.Add_Click({ Mostrar-Diagnostico })
    $f.Controls.Add($btnRevisar)

    $botones = Nueva-BarraBotones $f @(
        @{ Texto = 'Cancelar'; Accion = { $accion.Valor = 'cancelar'; $f.Close() } }
    ) 382
    $f.CancelButton = $botones[0]
    $f.Add_Shown({ $f.Activate() })
    $f.ShowDialog() | Out-Null

    return $accion.Valor
}

# ---------------------------------------------------------------------------
# Dialogo: elegir dispositivo
# ---------------------------------------------------------------------------

function Mostrar-Selector {
    param([array] $Dispositivos)

    $f = Nueva-Ventana 'Elige el celular' 456 384

    $y = Nuevo-Encabezado $f 'Elige el celular' 'Hay varios disponibles ahora mismo'

    $lista = New-Object System.Windows.Forms.ListBox
    $lista.Location = New-Object System.Drawing.Point(20, $y)
    $lista.Size     = New-Object System.Drawing.Size(400, 180)
    $lista.BorderStyle = 'FixedSingle'
    $lista.Font     = New-Object System.Drawing.Font('Segoe UI', 10)

    foreach ($d in $Dispositivos) {
        $titulo = Titulo-De $d
        if (Obtener-VentanaDe $titulo) { $marca = '  ●  ya abierto' } else { $marca = '' }
        $lista.Items.Add(('{0}   ({1}){2}' -f $d.Nombre, $d.Enlace, $marca)) | Out-Null
    }
    # La lista se ajusta a cuantos telefonos haya: con dos, una caja de 180
    # px queda medio vacia; con ocho, hace falta toda. Con ella se mueven los
    # botones y el alto de la ventana.
    $altoLista = [Math]::Min(180, [Math]::Max(58, ($lista.Items.Count * 19) + 12))
    $lista.Size = New-Object System.Drawing.Size(400, $altoLista)

    $lista.SelectedIndex = 0
    $f.Controls.Add($lista)

    $yBotones = $y + $altoLista + 26
    $f.ClientSize = New-Object System.Drawing.Size(440, ($yBotones + 32 + 20))

    $eleccion = [pscustomobject]@{ Indice = -1 }

    $conectar = {
        if ($lista.SelectedIndex -ge 0) {
            $eleccion.Indice = $lista.SelectedIndex
            $f.Close()
        }
    }

    $lista.Add_DoubleClick($conectar)

    $botones = Nueva-BarraBotones $f @(
        @{ Texto = 'Cancelar'; Accion = { $f.Close() } },
        @{ Texto = 'Conectar'; Accion = $conectar }
    ) $yBotones 140
    $f.CancelButton = $botones[0]
    $f.AcceptButton = $botones[1]
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
            if ($accion -eq 'preparar') {
                $accion = Mostrar-Preparacion $crudos
                Escribir-Log "Tras la preparacion: $accion"
            }
            if ($accion -eq 'cancelar') { exit 0 }
            if ($accion -eq 'emparejar') { Mostrar-Emparejamiento | Out-Null }
            $recuperado = $true
        }
    }

    Escribir-Log "Intento $intento recupero algo: $recuperado"
}

if ($listos.Count -eq 0) {
    # Mandar a leer un .log era no decir nada. Se ofrece la revision, que
    # responde lo mismo pero en espanol y con la accion al lado.
    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        "No se pudo conectar con ningún celular.`n`n¿Quieres que revise tu equipo y te diga qué falta?",
        'Mirador', 'YesNo', 'Error')
    Escribir-Log 'Sin dispositivos tras agotar la cascada'
    if ($respuesta -eq 'Yes') { Mostrar-Diagnostico }
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
