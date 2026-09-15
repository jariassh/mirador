# Mirador — tu celular en tu pantalla

Asistente de **scrcpy** para Windows: abre la pantalla de un Android en el
computador, por cable o por Wi-Fi, sin pelear con la terminal.

> Este archivo es **referencia estable**, no un diario. El detalle de cada
> sesión va en `docs/sessions/`, los pendientes en `docs/pendientes.md` y lo que
> cambió para quien usa la app en `CHANGELOG.md`.

## Identidad

| Campo      | Detalle                                                                     |
| :--------- | :-------------------------------------------------------------------------- |
| Repo       | `jariassh/mirador` — **PÚBLICO**, el único del workspace                    |
| Licencia   | MIT · scrcpy es Apache-2.0 y **no se redistribuye**, se instala y se invoca |
| Modelo     | **Gratis, como carta de presentación** — decidido el 2026-09-15             |
| Plataforma | Solo Windows 10/11 con PowerShell 5.1                                       |
| Versión    | Ver `CHANGELOG.md`; cada release lleva `git tag` y su `.exe` en Releases    |

**Por qué gratis y no de pago:** el mercado de envoltorios de scrcpy ya está
cubierto gratis (QtScrcpy, 30k estrellas) y la franja de pago la ocupa Vysor.
El valor de Mirador no son $5 por venta, es ser la prueba pública de software
terminado que alimenta `servicios.jariash.com`. El estudio completo, con
precios y licencias, está en [`docs/estudio-monetizacion.md`](docs/estudio-monetizacion.md);
el de nombres, en [`docs/estudio-nombres.md`](docs/estudio-nombres.md).

## Estructura

```
mirador.ps1        todo el asistente (un solo archivo)
instalar.ps1       instalador y desinstalador por línea de comandos
instalador/        guion de Inno Setup -> dist/MiradorSetup.exe (dist/ no va a git)
recursos/          ícono (.ico y .svg) y capturas, incluido el GIF del README
```

El estado del usuario vive en `%LOCALAPPDATA%\Mirador`: `dispositivos.json`
(teléfonos recordados) y `mirador.log`. **Es la misma carpeta que usa el
instalador `.exe`**, a propósito, para que las dos vías de instalación convivan.

## ⛔ REGLAS CRÍTICAS — INAPELABLES

**1. `mirador.ps1` va en UTF-8 CON BOM.** Sin BOM, PowerShell 5.1 lo lee como
ANSI y las tildes salen como `Ã³` en todos los diálogos. Al parchearlo con un
script, ese script **también** tiene que estar en UTF-8 con BOM, o se corrompe a
sí mismo antes de tocar nada. Escribir siempre con
`[System.IO.File]::WriteAllText($ruta, $texto, (New-Object System.Text.UTF8Encoding($true)))`.

⚠️ Los saltos de línea cambian solos: `git checkout` los normaliza a CRLF por
`autocrlf`, y una edición propia los deja en LF. Todo parche debe detectar cuál
tiene el archivo en ese momento, no asumir.

**2. Mirador NO usa consola.** Todo lo que pregunta lo pregunta en ventanas de
Windows. Cada lanzamiento de PowerShell —el acceso directo, el instalador y el
relanzamiento como administrador— lleva `-WindowStyle Hidden`. Sin excepción:
una ventana negra delata que esto es un script y no un programa.

**3. Ninguna ventana se maqueta a mano.** Se usan `Nuevo-Encabezado` (título,
línea de apoyo y separador) y `Nueva-BarraBotones` (botones del mismo ancho,
alineados a la derecha, la acción principal de última). Botones con anchos y
posiciones sueltas es exactamente lo que había antes y se veía armado a pedazos.

**4. Las rutas de menú por marca se VERIFICAN, nunca se escriben de memoria.**
Viven en la tabla `$script:GuiasPorMarca` — una fila por marca. Una ruta
inventada se ve igual de convincente que una verificada y hace más daño que no
tener asistente. La de TECNO/Infinix se corrigió leyendo el menú real del
aparato con `adb`: en HiOS, «Acerca del teléfono» se llama **«Mi teléfono»**.
Por eso el botón **«No veo esa opción»** está en TODAS las marcas.

**5. No se empaqueta scrcpy.** Mirador lo instala desde su fuente oficial con
winget, sin administrador, y de ahí sale también `adb` — que Windows no trae.
Empaquetarlo obligaría a redistribuirlo y a mantenerlo al día a mano.

## ⛔ Decidido que NO se construye

**Grabación de pantalla, mapeo de teclas para juegos, arrastrar archivos y
cualquier panel de opciones avanzadas.** Cada perilla nueva acerca a Mirador a
QtScrcpy —que lo hace mejor, gratis y multiplataforma— y lo aleja de lo único
que lo hace distinto: ser el único que apunta al hispanohablante **no técnico**,
que se cae antes de llegar a Mirador, en las Opciones de desarrollador.

## Publicar una versión

⛔ **Un `tag` marca una versión PUBLICADA, no cada merge.** Si no hay nada que
alguien pueda descargar, no lleva etiqueta. El 2026-09-15 se etiquetaron seis
versiones en la primera media hora —retoques del ícono y del README, sin
artefacto ninguno— y hubo que retirar cinco: parecía un proyecto con más
historial del que tenía, que es lo contrario de lo que busca una carta de
presentación.

⛔ **El número lo decide lo que el usuario percibe, no el tamaño del cambio.**
MAYOR solo cuando obliga a reaprender o rompe algo; funcionalidad nueva que se
suma sin quitar nada es MENOR, por mucha que sea. Quemar el 2.0.0 en una
versión que solo agrega deja sin número el día que haya un cambio de fondo.

1. Cerrar `## [No publicado]` en `CHANGELOG.md` con el número y la fecha.
2. Subir la versión en `instalador/mirador.iss` (`#define Version`).
3. Merge de `develop` a `main` + `git tag -a vX.Y.Z`.
4. Compilar: `& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" instalador\mirador.iss`
5. `gh release create vX.Y.Z dist\MiradorSetup.exe` con las notas y el SHA-256.

⚠️ El `.exe` **no está firmado**, así que Windows muestra SmartScreen. El README
lo explica de frente en vez de esconderlo. La vía a cero avisos sin pagar un
certificado de ~$200/año es la Microsoft Store, que firma gratis — anotado como
idea, sin decidir.

## Historial

| #   | Fecha      | Qué pasó                                                                                                                                                              |
| --- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 235 | 2026-09-15 | Nace Mirador, primer repo público del workspace                                                                                                                       |
| 238 | 2026-09-15 | Nace el tablero con `M-1`: estudiar si se puede monetizar                                                                                                             |
| 239 | 2026-09-15 | [Gratis como carta de presentación; asistente por marca, diagnóstico, instalador y v1.1.0](docs/sessions/2026-09-15-sesion-239-estudio-de-monetizacion-y-decision.md) |
