# Pendientes de Mirador — el tablero

> Solo lo que sigue abierto. Al cerrar un ítem se quita de acá y queda en el
> archivo de sesión que lo cerró.

| Prioridad | Total |
| :-------- | ----: |
| 🟠 Alto   |     1 |
| **TOTAL** | **1** |

## 🟠 Alto

### `M-1` · Estudiar si Mirador se puede monetizar

**De dónde sale (2026-09-15).** El profesor de Jonathan vio lo que hace Mirador
—ver y controlar el celular desde el PC— y le dijo que lo monetizara.

**Lo que hay que averiguar, en este orden.** No se escribe código hasta tener
las dos primeras respuestas:

1. **¿Ya existe un SaaS que haga esto?** Es lo primero, y puede cerrar el tema.
   Candidatos evidentes a mirar: scrcpy (que es lo que Mirador envuelve, y es
   libre), Vysor, AirDroid, scrcpy-gui y los envoltorios que ya se venden.
   ⚠️ Mirador **es un asistente de scrcpy**, no un competidor de scrcpy: lo que
   se vendería es la comodidad, no la tecnología.
2. **¿Se puede cobrar por encima de algo libre, y con qué licencia?** scrcpy es
   Apache-2.0 y Mirador es MIT — hay que leer qué permite cada una antes de
   prometer nada.
3. **El problema técnico que Jonathan ya identificó:** hoy es un `.ps1`, o sea
   **código abierto y editable**. Sus palabras: _«el código actualmente un ps1
   es editable y el código es accesible para poder copiarse»_. Para cobrar
   habría que empaquetarlo como software, no como script.

**Modelo que propone Jonathan:** pago único, **~$5 USD lifetime**.

**Contexto que no hay que perder:** Mirador nació como el **primer repositorio
público** del workspace, con licencia MIT (sesión 235). Monetizarlo obliga a
decidir qué pasa con eso — no es un detalle, es lo primero que va a preguntar
cualquiera.

**Lo que Jonathan decidió el 2026-09-15:** poner el repositorio **en privado**
mientras se estudia, para que nadie clone el código entre tanto. Es reversible
y no cierra ninguna de las opciones.

**Estado — el estudio ya está hecho:** [`estudio-monetizacion.md`](estudio-monetizacion.md)
responde las tres preguntas (sí existe competencia y la franja gratuita está
tomada; sí se puede cobrar, ninguna licencia lo impide; no se puede proteger un
`.ps1`, `PS2EXE` se descompila con `-extract`). Trae una recomendación y tres
caminos.

⛔ **Falta la decisión, y el ítem sigue abierto hasta que exista.** El tablero
registra lo que Jonathan decidió, no lo que se le recomendó: M-1 se cierra
cuando él elija camino, no cuando se entregó el informe.
