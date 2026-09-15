# Changelog

Todo cambio relevante de Mirador queda registrado acá. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el versionado
sigue [SemVer](https://semver.org/lang/es/).

Está escrito para quien usa Mirador, no para quien lee el código.

## [No publicado]

## [1.0.2] — 2026-09-15

### Cambiado

- El lienzo de diseño del ícono pasa a mostrar la pieza final —los tres
  dibujos, los siete tamaños y la paleta— en vez de las cuatro propuestas
  iniciales, que quedan en una segunda página como registro de por qué se
  eligió esa. De paso desaparece del repositorio el nombre provisional con
  que nació el proyecto.

## [1.0.1] — 2026-09-15

### Corregido

- **Los acentos del instalador salían rotos** («instalaciǬn» en vez de
  «instalación»). Dos causas apiladas: el archivo estaba guardado sin marca
  BOM, así que PowerShell 5.1 lo leía como texto ANSI; y la consola de
  Windows no viene en UTF-8, de modo que los acentos se rompían igual aunque
  el archivo estuviera bien. Ahora el instalador fija la codificación de
  salida al arrancar.

## [1.0.0] — 2026-09-15

Primera versión pública.

### Agregado

- Abre la pantalla del celular en el computador con un doble clic, por Wi-Fi
  o por cable.
- **Encuentra el teléfono aunque le haya cambiado la IP.** Guarda el nombre
  con que se anuncia en la red (mDNS), no la dirección, así que un reinicio
  del router ya no lo pierde.
- **Cascada de recuperación en cuatro pasos** — memoria, descubrimiento en la
  red, rastreo del puerto 5555 y, si todo falla, un diálogo que ofrece
  reintentar en vez de cerrarse.
- **Emparejamiento por Wi-Fi con código de 6 dígitos**, para teléfonos sin
  puerto USB útil. Detecta la dirección solo mientras el teléfono muestra el
  código; solo hay que escribir los dígitos.
- **Varios teléfonos a la vez**, cada uno en su ventana con su nombre. Al
  volver a abrir Mirador trae al frente el que elijas, en vez de abrir una
  ventana repetida.
- **Lista con marca y modelo** en vez de identificadores crípticos, y sin
  mostrar dos veces el mismo aparato cuando está por USB y por Wi-Fi.
- **Avisa qué hacer cuando el teléfono está sin autorizar** — el caso más
  frecuente de todos— en vez de reportar que no hay dispositivos.
- Ofrece dejar habilitado por Wi-Fi un teléfono que llegó por cable, para la
  próxima vez.
- **Instala scrcpy solo** la primera vez, con winget y sin pedir permisos de
  administrador.
- Instalador y desinstalador (`instalar.ps1`), que no tocan scrcpy ni adb.
- Registro de actividad en `%LOCALAPPDATA%\Mirador\mirador.log`.
- Ícono propio con siete tamaños y tres dibujos distintos: el de 16 px no es
  el grande reducido, es un dibujo aparte para que se lea en la barra de
  tareas.
