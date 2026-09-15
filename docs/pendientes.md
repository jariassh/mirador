# Pendientes de Mirador — el tablero

> Solo lo que sigue abierto. Al cerrar un ítem se quita de acá y queda en el
> archivo de sesión que lo cerró.

| Prioridad | Total |
| :-------- | ----: |
| 🟠 Alto   |     2 |
| **TOTAL** | **2** |

**Se atienden en este orden:** `M-3` → `M-4`. Aprobado por Jonathan el
2026-09-15. `M-2` ya está cerrado.

---

## 🟠 Alto

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
2. Un **instalador con Inno Setup** — gratuito y estándar. Elimina el
   `powershell -ExecutionPolicy Bypass` y agrega la entrada en «Agregar o quitar
   programas». ⛔ **PS2EXE quedó descartado:** sus `.exe` disparan falsos
   positivos de antivirus, y un aviso de amenaza es el peor primer contacto
   posible para una carta de presentación. Camino posterior para quitar también
   el aviso de SmartScreen, sin pagar certificado: publicar en la Microsoft
   Store, que firma gratis.
3. Un pie en el README que lleve a `servicios.jariash.com`.
4. Sumar a «Qué hace por ti» del README el asistente de preparación de `M-2`.
   No se hizo al cerrar `M-2` a propósito: el README no se toca en cada merge
   —es el generador de conflictos número uno—, y `M-4` ya lo va a editar.
5. ⛔ **Volver el repositorio a público** y corregir la fila de `mirador/` en el
   `CLAUDE.md` del workspace, que quedó marcada **(PRIVADO)** durante el estudio.

---

## Decidido que NO se hace

Registrado el 2026-09-15 para no volver a discutirlo: **grabación de pantalla,
mapeo de teclas para juegos, arrastrar archivos y cualquier panel de opciones
avanzadas.** Cada perilla nueva acerca a Mirador a QtScrcpy —que lo hace mejor,
gratis y multiplataforma— y lo aleja de lo único que lo hace distinto.
