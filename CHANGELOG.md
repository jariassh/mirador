# Changelog

Todo cambio relevante de Mirador queda registrado acá. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el versionado
sigue [SemVer](https://semver.org/lang/es/).

Está escrito para quien usa Mirador, no para quien lee el código.

## [No publicado]

### Agregado

- **Asistente para preparar el teléfono.** Cuando Mirador no encuentra ningún
  celular, ahora aparece el botón «Preparar mi teléfono (primera vez)». Eliges
  tu marca y te muestra la ruta exacta de **tu** menú para activar las Opciones
  de desarrollador y la depuración — porque no se llama igual en un Samsung que
  en un Xiaomi. Están cubiertas Samsung, Xiaomi/Redmi/POCO, Motorola,
  Huawei/Honor, Oppo/realme, TECNO/Infinix y Google Pixel, más una opción para
  cualquier otra marca.
- Si el celular ya aparece conectado, el asistente **viene con tu marca ya
  elegida**.
- Botón **«No veo esa opción»** en todas las marcas, que muestra la ruta que
  sirve en casi cualquier Android y recuerda que Ajustes tiene buscador.
- **«Revisar mi equipo».** Un botón que revisa todo lo que hace falta para
  conectar y te dice, en español, qué está bien y qué falta tocar: si scrcpy
  está instalado, si tu celular autorizó la depuración, en qué red está cada
  uno y si el teléfono que usabas sigue respondiendo.
- Detecta el caso más difícil de adivinar solo: **que el celular y el
  computador quedaron en redes distintas** —o que tienes una VPN encendida—,
  que se ve como si «simplemente no conectara».

### Cambiado

- Cuando no se logra conectar, Mirador ya no te manda a abrir un archivo de
  registro con el Bloc de notas: **te ofrece revisar el equipo** y te responde
  en pantalla.
- **Las ventanas se ven ordenadas.** Cada una abre con su título arriba y una
  línea que explica de qué se trata, los botones tienen todos el mismo tamaño y
  quedan alineados, y la acción principal está siempre a la derecha, como en
  cualquier programa de Windows.
- Las ventanas ahora llevan **el ícono de Mirador** en vez del de PowerShell.
- El asistente aclara que **el computador ya quedó listo** y que lo que falta es
  solo preparar el teléfono.

### Corregido

- **Si tienes scrcpy pero falta `adb`, Mirador ahora lo detecta al abrir** y te
  ofrece instalarlo. Antes arrancaba como si todo estuviera bien y fallaba más
  adelante con un «no se encontró ningún celular», que manda a revisar el
  teléfono cuando el problema estaba en el computador. (`adb` no viene con
  Windows: llega dentro del mismo paquete de scrcpy.)
- Ya **no aparece una ventana negra de consola** cuando Mirador necesita pedir
  permisos de administrador para instalar scrcpy.

### Instalación

- **Instalador de Windows normal (`MiradorSetup.exe`).** Doble clic, siguiente,
  listo — ya no hace falta escribir nada en la terminal. No pide permisos de
  administrador, crea los accesos directos y aparece en «Agregar o quitar
  programas» para desinstalarlo como cualquier otro programa.
- La instalación manual con `instalar.ps1` sigue funcionando igual, y las dos
  usan la misma carpeta.

## [1.0.5] — 2026-09-15

### Agregado

- Captura en el README con dos teléfonos abiertos al mismo tiempo, cada uno
  en su ventana y con el nombre de su equipo en el título. Es lo que ningún
  párrafo explica bien.

## [1.0.4] — 2026-09-15

### Cambiado

- Sale del repositorio el lienzo con el que se diseñó el ícono. Era proceso
  interno y no le aporta nada a quien descarga la herramienta; los archivos
  del ícono que sí importan —el `.ico` y los `.svg` editables— siguen en
  `recursos/`.

## [1.0.3] — 2026-09-15

### Corregido

- Quedaban rastros del nombre provisional del proyecto en sitios que sí se
  ven: el `<title>` y el `aria-label` de los SVG del ícono —que es lo que
  anuncia un lector de pantalla— y las etiquetas del lienzo de diseño.

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
