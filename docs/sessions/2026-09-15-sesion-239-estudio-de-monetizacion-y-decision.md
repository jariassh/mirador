# Sesión 239 — El estudio de monetización y la decisión

**Fecha:** 2026-09-15 · **Proyecto:** `mirador/` · **Rama:** `M-1-estudiar-monetizacion`

## Qué se hizo

Se respondió `M-1` completo — el ítem que preguntaba si Mirador se puede
monetizar — y Jonathan tomó la decisión. El informe quedó en
[`estudio-monetizacion.md`](../estudio-monetizacion.md); acá solo el resumen y
lo que se decidió.

## Lo que encontró el estudio

**1. Sí existe competencia, y está fuerte.** El mercado está partido:

- **Cobran:** Vysor ($2,50/mes · $10/año · $40 pago único, con capa gratuita
  limitada a USB) y AirDroid Personal ($29,99/año).
- **No cobran, y son envoltorios de scrcpy igual que Mirador:** QtScrcpy
  (30.771 estrellas, C++/Qt, multiplataforma), Escrcpy, scrcpygui.com y una
  cola larga de lanzadores.

La franja de «comodidad sobre scrcpy» ya está cubierta gratis por proyectos con
años de trabajo encima.

**2. Sí se puede cobrar por encima de algo libre.** scrcpy es Apache-2.0 y
permite uso comercial; basta incluir el texto de la licencia y los avisos de
copyright. Mirador es MIT y también permite venderse. Ninguna traba legal.

⚠️ Pero una licencia MIT **ya entregada no se revoca**: quien clonó el repo
mientras estuvo público conserva para siempre el derecho de usarlo, modificarlo
y venderlo. Exposición real medida: ~5 horas públicas, **0 forks, 1 estrella**.

**3. No se puede proteger el `.ps1`.** `PS2EXE` —el camino obvio— trae el
parámetro `-extract`, que saca el script original del `.exe`; su propia
documentación advierte que nunca guardes contraseñas adentro por eso. Proteger
en serio exigiría reescribirlo en un lenguaje compilado, y aun así son 921
líneas que orquestan `adb` y `scrcpy`: cualquiera rehace esa lógica mirando qué
comandos lanza.

**Las cuentas del modelo de $5:** Gumroad se queda el 10% → entran $4,50 por
venta. Para hacer $100 al mes hacen falta 22 ventas mensuales sostenidas, sin
marca ni tráfico, contra cuatro alternativas gratuitas — y cada venta trae
derecho a soporte.

## La decisión de Jonathan

> **Mirador queda gratis, como carta de presentación.**

El valor no está en los $4,50 por venta, está en ser la prueba pública de que
entrega software terminado —ícono, instalador, README, versionado, licencia—, y
eso alimenta a Jariash Group LLC y a `servicios.jariash.com`, donde un cliente
vale mucho más que 22 ventas de $5.

Jonathan había llegado por su cuenta a la misma conclusión revisando QtScrcpy y
AirDroid: _«estuve pensando eso, en dejarlo gratis como mi carta de
presentación»_.

**El repositorio quedó en privado** durante el estudio, por decisión suya, para
que nadie clonara el código mientras se decidía. Con el camino elegido, vuelve
a público.

## Y entonces, ¿se puede mejorar teniendo a QtScrcpy al lado?

Sí, pero **no compitiéndoles de frente**. Agregarle grabación, mapeo de teclas
o transferencia de archivos lo convierte en un clon peor de QtScrcpy, escrito
en PowerShell.

La pregunta que sirve no es «¿qué les falta a ellos?» sino **«¿a quién no están
atendiendo?»**. Todos apuntan al desarrollador y al equipo de QA, en inglés,
con paneles de perillas (bitrate, códec, resolución, recorte). Mirador es el
único que apunta al que no sabe ni quiere saber qué es un bitrate — y ese
usuario **se cae antes de llegar a Mirador**, en las Opciones de desarrollador
del teléfono.

De ahí salen los tres pendientes nuevos: `M-2`, `M-3` y `M-4`.

⛔ **Lo que se decidió NO hacer:** grabación de pantalla, mapeo de teclas para
juegos, arrastrar archivos y cualquier panel de opciones avanzadas. Cada
perilla acerca a Mirador a QtScrcpy y lo aleja de lo único que lo hace
distinto.

## Adenda — empaquetado: PS2EXE descartado, Inno Setup en su lugar

Jonathan preguntó si Mirador debía salir como `.exe` con PS2EXE, a modo de
instalador de Windows. **Se descartó PS2EXE**, y por una razón distinta a la del
estudio de monetización: allá no servía porque no protege el código; acá, con el
criterio nuevo —que se vea terminado— tampoco sirve, porque está documentado que
sus `.exe` **disparan falsos positivos de antivirus**, incluido Defender. Para
una carta de presentación, un aviso de amenaza es el peor primer contacto
posible. Y no aporta nada: `instalar.ps1` ya crea accesos directos y desinstala
sin pedir administrador.

**Lo que sí se hará, dentro de `M-4`:** un instalador con **Inno Setup**, que es
gratuito, estándar, elimina el `powershell -ExecutionPolicy Bypass` de la
instalación y agrega la entrada en «Agregar o quitar programas». Sin firma sale
el aviso de SmartScreen, que deja continuar y es el diálogo que cualquiera
reconoce de software independiente — no es lo mismo que una alerta de virus.

**Anotado como camino posterior, no bloqueante:** la Microsoft Store ya no cobra
registro a desarrolladores individuales, aloja el binario y **lo firma gratis**.
Es la única vía a cero advertencias sin pagar un certificado de ~$200 al año.

## Adenda — estudio de nombres: se queda «Mirador»

Jonathan pidió evaluar si había un nombre mejor. El estudio está en
[`estudio-nombres.md`](../estudio-nombres.md), con colisiones verificadas por
`gh search repos` y por DNS. Cayeron **Vistazo** (choca con la revista
ecuatoriana homónima, de 1957, con apps propias), **Atalaya** (en el mundo
hispano «La Atalaya» es la revista de los Testigos de Jehová), **Retrovisor**
(ya existe en GitHub, también capa de visualización) y **Balcón** (lleva tilde).

Quedó **Catalejo** como único retador —espacio casi vacío y `catalejo.com`
aparentemente libre—, pero con un lunar de fondo: un catalejo sirve para mirar
de lejos algo **ajeno**, y esto espeja **tu propio** teléfono.

> **Decisión de Jonathan:** se queda **Mirador**. Su única colisión de peso es
> un visor de manuscritos digitalizados IIIF en GitHub (615 ★) — otro mundo,
> otro público, y el repo vive namespaceado en `jariassh/mirador`. A cambio, no
> carga connotación de vigilancia, que es el riesgo de marca serio de esta
> categoría.

## `M-2` — el asistente de preparación del teléfono, hecho

**Qué se agregó.** En la pantalla de «No se encontró ningún celular» apareció el
botón **«Preparar mi teléfono (primera vez)»**, como acción principal y separada
del resto: los otros tres botones daban por hecho que el teléfono ya estaba
preparado, que es justo lo que le falta a quien llega ahí la primera vez.

El asistente son dos diálogos: elegir la marca y ver la ruta exacta de **ese**
menú. Las guías viven en una tabla `$script:GuiasPorMarca` — agregar una marca
nueva es agregar una fila, no tocar el diálogo.

**El huevo y la gallina.** Si la depuración no está activa, `adb` no ve el
teléfono y no hay forma de detectar la marca: por eso el asistente **pregunta**.
Cuando el teléfono sí aparece, `Marca-Sugerida` lee `ro.product.manufacturer` y
deja la marca preseleccionada.

### El hallazgo: la ruta de TECNO estaba mal

Las rutas se verificaron contra la documentación de cada fabricante, pero de
**TECNO/Infinix solo hay videos**, así que esa fila se escribió con la ruta
genérica —«Acerca del teléfono › Información de software»—. Como Jonathan tenía
el TECNO KL4 conectado por depuración inalámbrica, se leyó **el menú real del
aparato** con `adb`, y resultó estar mal en dos cosas:

- En HiOS 14, «Acerca del teléfono» **se llama «Mi teléfono»**.
- **No existe** el submenú «Información de software»: «Número de compilación»
  está en la misma pantalla, junto a «Versión de HiOS».

La ruta del paso 2 —`Ajustes › Sistema › Opciones de desarrollador`— sí resultó
correcta, confirmada también en pantalla. La fila quedó corregida con lo
verificado, y el comentario del código dice de dónde salió cada dato.

> **La lección, y por eso el botón «No veo esa opción» está en TODAS las
> marcas:** una ruta escrita de memoria se ve igual de convincente que una
> verificada. El menú real cambia entre versiones del mismo fabricante, y
> quedarse sin salida es peor que una ruta imperfecta.

### Cómo se verificó

- **Sintaxis:** `Parser::ParseFile` sin errores, y el archivo conserva el **BOM
  UTF-8** que el propio script documenta como obligatorio (sin él, PowerShell
  5.1 lee las tildes como `Ã³`). El primer intento de parche falló justamente
  por eso: el script del parche salió sin BOM y se corrompió a sí mismo.
- **Visual:** capturados los cuatro diálogos, incluidos los dos casos extremos
  —TECNO, el más alto, y Oppo/realme, el más largo— para confirmar que ningún
  texto se corta ni se monta con los botones.
- **Interacción real:** el diálogo de marca se manejó con teclado (abajo, abajo,
  Enter) y devolvió `Motorola`, que es lo que verifica que los manejadores y el
  botón por defecto funcionan.
- **Lógica pura:** `Marca-Sugerida`, 9 de 9 casos.
- **Contra aparatos reales:** el TECNO KL4 sugirió «TECNO / Infinix» y el
  moto g(60)s sugirió «Motorola». El teléfono quedó como estaba: pantalla
  apagada, en el inicio y sin archivos temporales.

## Estado al cerrar

- `M-1` cerrado — el estudio respondió las tres preguntas y hay decisión tomada.
- `M-5` cerrado — estudio de nombres hecho y decidido: sigue siendo Mirador.
- `M-2` cerrado — asistente de preparación, verificado contra dos teléfonos.
- Abiertos: `M-3` (diagnóstico en un clic) y `M-4` (la vitrina: GIF, instalador
  Inno Setup, README y volver a público), en ese orden.
- El `CLAUDE.md` del workspace decía **(PÚBLICO)**; quedó corregido a privado
  mientras dure el estudio. **Al ejecutar `M-4` hay que volver a cambiarlo.**
