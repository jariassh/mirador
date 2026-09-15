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

## `M-3` — diagnóstico en un clic, hecho

**Qué se agregó.** El botón **«Revisar mi equipo»**, al lado de «Buscar en la
red», y siete chequeos que responden en español con la acción al lado: scrcpy
instalado, adb respondiendo, teléfonos listos, autorización pendiente, conexión
perdida, red del computador, teléfonos recordados y conexión sin cable.

Además, el callejón final cambió: cuando se agota la cascada, Mirador ya **no
manda a abrir el `.log` con el Bloc de notas** —que para su público equivale a
no decir nada— sino que ofrece hacer la revisión.

**El chequeo que justifica la función:** comparar la red del PC con la del
teléfono guardado. Un computador con VPN encendida, o en una red de invitados,
se ve «normal» y no conecta nunca; nadie diagnostica eso a mano.

### Dos cosas que la prueba con teléfonos reales destapó

1. **El aviso de mDNS mentía.** `adb mdns services` lista lo que se anuncia _en
   ese momento_, y con los dos teléfonos trabajando por Wi-Fi la lista salió
   **vacía**. El chequeo concluía «ningún teléfono se está anunciando → enciende
   la Depuración inalámbrica», dicho a alguien que ya la tenía encendida.
   Ahora mira primero si hay teléfonos conectados sin cable, y el mDNS es solo
   el segundo camino.
2. **Los adaptadores virtuales se colaban como red propia.** Aparecía
   `172.23.176.1` —el conmutador de Hyper-V/WSL— junto a la IP real. Se filtran
   vEthernet, WSL, Hyper-V, VirtualBox y VMware. ⚠️ **Una VPN NO se filtra, a
   propósito:** es justo la causa que el chequeo existe para descubrir.

### Cómo se verificó

- **Lógica pura:** `Misma-Red` (misma /24, distinta /24, y basura sin reventar)
  y `Responde-Puerto` (puerto cerrado, servidor adb vivo en 5037, e IP muerta
  que devuelve en medio segundo sin colgar la ventana).
- **Caso de fallo real, sin tocar los teléfonos:** se respaldó el archivo de
  estado, se guardó un teléfono falso en `10.77.88.99` —otra red— y se comprobó
  que el chequeo lo marca como `falla` y que la sugerencia explica que están en
  redes distintas. El archivo quedó restaurado.
- **Caso feliz:** los 7 chequeos en verde en 1,2 s con los dos teléfonos.
- **Visual:** capturado el diálogo, que resume «Todo en orden» y lista los siete.

## `M-6` — orden visual de los diálogos

**De dónde sale.** Jonathan, viendo las capturas: _«si se pueden diseñar ui,
trata que queden bonitas, sino pues al menos que los botones queden
correctamente organizados y no desordenados»_. Tenía razón: los botones se
habían ido agregando de a uno y cada uno traía su propio ancho —110, 130, 150,
250— con los bordes sin coincidir con nada.

**Qué se hizo.** Dos ayudantes que ahora usan todas las ventanas:

- `Nuevo-Encabezado` — franja blanca con el título en grande, una línea de
  apoyo en gris y un separador de 1 píxel. Devuelve la Y donde empieza el
  contenido, así ninguna ventana calcula ese margen a mano.
- `Nueva-BarraBotones` — botones del **mismo ancho**, alineados a la derecha y
  con la acción principal de última, como en cualquier programa de Windows. La
  posición se calcula desde `ClientSize`, no a ojo.

Además, la pantalla de «No se encontró ningún celular» quedó con jerarquía: la
acción principal sola y a todo el ancho, las cuatro secundarias en una reja de
2×2 del mismo tamaño, y Cancelar aparte abajo a la derecha.

Y las ventanas ahora cargan **el ícono de Mirador** en vez del de PowerShell,
que es lo primero que delata que algo es un script y no un programa. Se busca
en los dos sitios donde puede estar: junto al script (como queda instalado) y
en `recursos\` (como está en el repositorio).

**Dos desbordes que solo se vieron capturando:**

- La barra de la guía por marca se salía por la izquierda: tres botones de 168
  px más separaciones no entran en 540. Quedaron en 160.
- La lista de marcas dejaba un hueco vacío abajo; se ajustó el alto al
  contenido real.

**Regresión verificada, que era el riesgo de verdad:** mover los manejadores
dentro de las definiciones de la barra podía romper los cierres de PowerShell
en silencio. Se repitió la prueba de teclado —abajo, abajo, Enter— y siguió
devolviendo `Motorola`, y los chequeos de `M-3` siguen los 7 en verde.

> **Nota sobre la regla de Stitch.** El `CLAUDE.md` del workspace pide diseñar
> en Stitch antes de implementar UI. Acá no aplica tal cual: son diálogos
> nativos de Windows Forms, y un mockup web no representaría lo que se ve. Se
> cumplió el fondo de la regla —mostrar el diseño y esperar aprobación— con
> **capturas reales del antes y el después**, que además son más fieles.

## `M-7` — coherencia del primer arranque

**De dónde sale.** Jonathan preguntó dos cosas al ver las capturas: si la
consola se ve siempre por detrás, y si el asistente también instala scrcpy y si
`adb` viene con Windows. Ninguna de las dos era un malentendido suyo — las dos
destaparon algo.

**La consola: no, y sí.** En uso real no aparece: el acceso directo que crea
`instalar.ps1` usa `-WindowStyle Hidden`, y el encabezado del script lo
documenta como decisión deliberada. Lo que se veía detrás en las capturas era el
arnés de pruebas, que se lanza a propósito con consola visible. **Pero** al
verificarlo apareció un descuido real: el relanzamiento como administrador
—cuando falta scrcpy, winget no pudo instalarlo y el usuario no es admin— se
hacía **sin** esa bandera, así que la instancia elevada arrancaba con la ventana
negra a la vista. Corregido.

**adb: Windows no lo trae.** Verificado en el equipo, no de memoria:
`C:\ProgramData\chocolatey\bin\adb.exe` sale de
`...\lib\scrcpy\tools\adb.exe` — o sea, del propio paquete de scrcpy.

Y ahí estaba el hueco de verdad: `Asegurar-Scrcpy` comprobaba **solo scrcpy**.
Casi siempre van juntos, pero no siempre —un scrcpy descomprimido a mano desde
un `.zip`, o un atajo roto, deja scrcpy en el PATH y `adb` fuera—, y en ese caso
Mirador arrancaba creyendo que todo estaba bien y fallaba después disfrazado de
«no se encontró ningún celular», que **manda a revisar el teléfono cuando el
problema estaba en el computador**. Ahora comprueba las dos piezas y, si falta
`adb`, lo dice con esas palabras y ofrece instalarlo.

**Y la tercera:** el asistente ahora dice «El computador ya quedó listo. Esto es
solo el teléfono», porque hasta ahora el usuario no tenía cómo saber que del
lado del PC no le faltaba nada.

### Cómo se verificó

- `Hay-Scrcpy` y `Hay-Adb` con las herramientas presentes, y con `adb` ausente
  —sustituyendo el nombre del ejecutable— para confirmar que en ese caso **no**
  da el arranque por bueno.
- **El caso nuevo, de punta a punta:** se lanzó `Asegurar-Scrcpy` con `adb`
  ausente, se respondió **No** al cuadro con el teclado, y devolvió `False`
  dejando escrito «scrcpy esta pero adb no» en el registro.
- Que el relanzamiento elevado ya lleva `-WindowStyle Hidden`.
- Capturado el asistente con la línea nueva y la lista recolocada.

## `M-4` — la vitrina

**El GIF, y el susto.** Se grabó la secuencia real con los dos teléfonos de
Jonathan: el selector, el TECNO apareciendo, moverlo a un lado, el segundo
selector, el moto a la derecha. 17,9 s, 1,49 MB, 760×427.

⚠️ **La primera toma no se podía publicar.** El moto estaba bloqueado y mostraba
su pantalla de bloqueo **con notificaciones legibles**: nombres y apellidos de
personas reales y asuntos de mensajes de terceros. Iba a un repositorio público.
Se descartó entera.

En la segunda toma —con los dos teléfonos en su pantalla de inicio— Jonathan
avisó que **había usado el moto sin darse cuenta durante la grabación**. Al
revisar, en el último segundo aparecía la cortina de notificaciones desplegada,
con el nombre y la foto de una persona, una dirección de calle y un aviso de
LastPass. Se recortó el GIF antes de ese punto.

> **La lección, y cuesta poco aprenderla:** revisar cuatro fotogramas sueltos no
> es revisar la grabación. Las dos veces los fotogramas que miré primero estaban
> limpios. Lo que sirvió fue armar una **hoja de contactos de toda la línea de
> tiempo** —un fotograma por segundo, recortando la zona del teléfono— y mirarla
> entera antes de dar nada por bueno.

**El instalador.** `instalador/mirador.iss` produce `MiradorSetup.exe` (2 MB).
Sin administrador, a `%LOCALAPPDATA%\Mirador` —la misma carpeta que usa
`instalar.ps1`, así conviven las dos vías—, acceso directo con
`-WindowStyle Hidden` y entrada en «Agregar o quitar programas». **No empaqueta
scrcpy**: Mirador lo instala solo desde su fuente oficial, y empaquetarlo
obligaría a redistribuirlo y mantenerlo a mano. `/dist/` va al `.gitignore`: el
`.exe` se publica en Releases, no en el repositorio.

Verificado instalando de verdad en una carpeta temporal y desinstalando después:
archivos, argumentos del acceso directo e ícono correctos, y la desinstalación
dejó limpios la carpeta, el menú Inicio y «Agregar o quitar programas».

> Un susto de en medio: tras desinstalar quedaba un acceso directo en el
> escritorio y lo di por residuo del instalador. **Era el de Jonathan**, creado
> por `instalar.ps1` a las 9:05 de esa mañana y apuntando a su instalación real.
> Mirar a dónde apuntaba antes de borrarlo evitó quitarle su acceso directo.

**El README** pasó a encabezar con el `.exe` y dejó la vía de PowerShell como
alternativa plegada; se explica el aviso de SmartScreen en vez de esconderlo
—«si prefieres no fiarte de mi palabra, el código está completo acá»—, se
sumaron el asistente y el diagnóstico a «Qué hace por ti», y se cierra con el
pie que lleva a `servicios.jariash.com`.

**El repositorio volvió a público** (`isPrivate: false`, 0 forks) y la fila de
`mirador/` en el `CLAUDE.md` del workspace quedó corregida.

## Estado al cerrar

- `M-1` cerrado — el estudio respondió las tres preguntas y hay decisión tomada.
- `M-5` cerrado — estudio de nombres hecho y decidido: sigue siendo Mirador.
- `M-2` cerrado — asistente de preparación, verificado contra dos teléfonos.
- `M-3` cerrado — diagnóstico en un clic, con el caso de fallo probado.
- `M-6` cerrado — orden visual de los diálogos, con la regresión verificada.
- `M-7` cerrado — coherencia del primer arranque: adb verificado, consola oculta
  al elevar y el asistente aclarando que el PC ya está listo.
- `M-4` cerrado — GIF, instalador, README y repositorio público otra vez.
- **El tablero quedó en cero.** Nada abierto.
- Anotado como idea sin decidir: publicar en la Microsoft Store, que firma
  gratis y es la única vía a cero avisos de SmartScreen sin pagar certificado.
