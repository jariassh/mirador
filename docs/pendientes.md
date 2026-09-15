# Pendientes de Mirador — el tablero

> Solo lo que sigue abierto. Al cerrar un ítem se quita de acá y queda en el
> archivo de sesión que lo cerró.

| Prioridad | Total |
| :-------- | ----: |
| 🟠 Alto   |     3 |
| **TOTAL** | **3** |

**Se atienden en este orden:** `M-2` → `M-3` → `M-4`. Aprobado por Jonathan el
2026-09-15.

---

## 🟠 Alto

### `M-2` · Asistente de preparación del teléfono

**El problema.** Activar _Opciones de desarrollador_ y _Depuración inalámbrica_
es el muro donde se cae el usuario no técnico, y hoy Mirador solo lo explica en
el README, en texto, fuera del programa. Peor: el nombre de cada menú **cambia
por marca** — no se llama igual en Samsung, en Xiaomi y en Motorola.

**Qué se construye.** Un asistente en pantalla que guíe paso a paso con la ruta
y los nombres reales del menú de esa marca.

⚠️ **El detalle que define el diseño:** si la depuración todavía no está
activa, `adb` **no ve el teléfono**, así que no se puede detectar la marca
automáticamente. El asistente tiene que empezar preguntando la marca.

**Por qué esto y no otra cosa:** es el único terreno donde Mirador queda
objetivamente mejor que QtScrcpy y AirDroid, porque el público de ellos ya sabe
hacer esto. Ver [la sesión 239](sessions/2026-09-15-sesion-239-estudio-de-monetizacion-y-decision.md).

### `M-3` · Diagnóstico en un clic

**El problema.** Cuando algo falla, hoy Mirador manda al usuario a abrir
`%LOCALAPPDATA%\Mirador\mirador.log` con el Bloc de notas. Para el público al
que apunta, eso equivale a no decir nada.

**Qué se construye.** Un botón «Revisar mi equipo» que verifique en orden y
responda en español qué falta y qué tocar: ¿está `adb`?, ¿el teléfono autorizó
la depuración?, ¿están el PC y el teléfono en la misma red?, ¿la depuración
sigue activa?

**Beneficio secundario:** menos issues de soporte en el repo.

### `M-4` · La vitrina — que se vea en 30 segundos

**El problema.** Si Mirador es la carta de presentación, lo que decide es lo
que un visitante ve en los primeros 30 segundos, y hoy la instalación arranca
con `powershell -ExecutionPolicy Bypass`, que a un no técnico lo espanta.

**Qué se hace.**

1. Un **GIF de ~20 segundos** en el README: doble clic → el celular en pantalla.
   Necesita un teléfono real conectado para grabarlo.
2. Un **`.zip` en Releases** para descargar sin tocar la terminal.
3. Un pie en el README que lleve a `servicios.jariash.com`.
4. ⛔ **Volver el repositorio a público** y corregir la fila de `mirador/` en el
   `CLAUDE.md` del workspace, que quedó marcada **(PRIVADO)** durante el estudio.

---

## Decidido que NO se hace

Registrado el 2026-09-15 para no volver a discutirlo: **grabación de pantalla,
mapeo de teclas para juegos, arrastrar archivos y cualquier panel de opciones
avanzadas.** Cada perilla nueva acerca a Mirador a QtScrcpy —que lo hace mejor,
gratis y multiplataforma— y lo aleja de lo único que lo hace distinto.
