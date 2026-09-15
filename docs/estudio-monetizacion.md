# M-1 · ¿Se puede monetizar Mirador?

> Estudio, no decisión. Responde las tres preguntas del tablero en orden y
> cierra con una recomendación. Lo que se decida queda en `docs/pendientes.md`.
>
> Fecha: 2026-09-15

---

## 1. ¿Ya existe alguien que haga esto?

Sí, y el mercado está partido en dos mitades. Esto es lo que hay:

**Los que cobran**

- **Vysor** — no es un envoltorio de scrcpy, tiene su propia tecnología. Capa
  gratuita limitada (solo USB, resolución baja), y **Vysor Pro a $2,50/mes,
  $10/año o $40 pago único**, que desbloquea inalámbrico, pantalla completa y
  arrastrar archivos. Además tiene plan Enterprise desde $2 por usuario/mes.
- **AirDroid Personal** — $29,99/año ($3,99 si es mensual). AirDroid Cast cobra
  aparte: $2,49/mes para transmitir y $3,49/mes para además controlar.

**Los que no cobran** — y son envoltorios de scrcpy, exactamente lo mismo que
hace Mirador:

- **QtScrcpy** — C++/Qt, multiplataforma, **30.771 estrellas en GitHub**. Es el
  más popular con enorme diferencia y maneja varios equipos a la vez, graba
  pantalla, arrastra archivos.
- **Escrcpy** — Electron, interfaz gráfica completa, gratis.
- **scrcpygui.com** — sin anuncios, sin suscripción, código abierto.
- **guiscrcpy** — Python; el repositorio está **archivado desde diciembre 2023**.
- Y una cola larga de lanzadores sueltos en GitHub.

**Lo que esto significa.** La franja de «comodidad sobre scrcpy» —que es
justo donde vive Mirador— **ya está cubierta, gratis, por proyectos con años
de trabajo encima**. Y la franja de pago la ocupa Vysor, que no compite en
comodidad sino en que resuelve cosas que scrcpy no hace.

Dicho eso, hay un hueco real y vale nombrarlo: **todo lo anterior está en
inglés y apunta a desarrolladores y equipos de QA**. Nadie está atendiendo al
hispanohablante no técnico que solo quiere doble clic y ver su celular. Ese es
el único terreno donde Mirador llega primero.

---

## 2. ¿Se puede cobrar por encima de algo libre?

**Sí. Ninguna licencia lo impide.** Esta pregunta se cierra en verde.

- **scrcpy es Apache-2.0**, que permite uso comercial explícitamente. Las
  obligaciones al distribuir su binario son cuatro y son baratas: incluir el
  texto de la licencia, conservar los avisos de copyright, incluir el archivo
  `NOTICE` si lo hay, y declarar de forma visible si modificaste sus archivos.
  Mirador no modifica scrcpy, así que el último punto ni aplica.
- **Mirador es MIT**, que también permite venderlo.

⚠️ **Pero hay un detalle que sí importa, y es el que te afecta hoy.** Una
licencia MIT ya entregada **no se puede revocar**. Haber puesto el repositorio
en privado corta la distribución hacia adelante, pero quien alcanzó a clonarlo
mientras estuvo público conserva para siempre el derecho MIT sobre esa copia:
usarla, modificarla y **venderla**. En la práctica el riesgo es mínimo —
estuvo público unas cinco horas, tiene 0 forks y 1 estrella— pero conviene
saberlo antes de construir un plan sobre la idea de «ya lo recuperé».

---

## 3. El problema del `.ps1`: ¿se puede proteger?

**No de verdad.** Esta es la pregunta que peor se ve de las tres.

El camino obvio para empaquetar un `.ps1` es **PS2EXE**, y no sirve como
protección: el propio proyecto trae el parámetro `-extract`, que saca el script
original del `.exe` y lo guarda en un archivo. Su documentación advierte
literalmente que nunca guardes contraseñas adentro, porque cualquiera lo
descompila con esa bandera.

Proteger en serio significaría reescribir Mirador en un lenguaje compilado
(C#, Go, Rust). Y aun así: Mirador son **921 líneas que orquestan `adb` y
`scrcpy`**. Cualquiera con ganas rehace esa lógica mirando qué comandos lanza,
sin necesidad de leer una sola línea tuya. Lo que hace valioso a Mirador no es
un secreto técnico — es que está hecho y funciona.

---

## 4. Las cuentas de $5 pago único

El precio que propusiste tiene un problema de aritmética antes que de mercado.

- Gumroad se queda el **10%** → te entran **$4,50** por venta.
- Vysor cobra $40 de por vida y **tiene capa gratuita**. Competirle por precio
  desde $5 no es una ventaja: refuerza la idea de que es un juguete.
- Microsoft Store hoy **no cobra registro a desarrolladores individuales**, no
  se queda con nada si cobras por fuera, aloja el binario y **lo firma gratis**
  — eso último resuelve la alerta de SmartScreen de Windows, que es el primer
  muro real de cualquier `.exe` desconocido.

El número: para que esto sean $100 al mes necesitas **22 ventas mensuales
sostenidas** de un producto sin marca, sin tráfico y contra cuatro alternativas
gratuitas. Y cada venta trae derecho a soporte: «no me conecta», «cambió la
IP», «Windows me lo bloqueó». A $4,50 la unidad, dos correos de soporte ya
comieron la ganancia.

---

## Recomendación

**No lo vendas como producto de pago único. Úsalo como carta de presentación.**

El razonamiento en una línea: el valor de Mirador no está en los $4,50, está en
que es la prueba pública de que sabes hacer software terminado — con ícono,
instalador, README, versionado y licencia. Eso alimenta a Jariash Group LLC y a
`servicios.jariash.com`, donde un solo cliente vale cientos de veces lo que
veintidós ventas de $5.

Tres caminos, de mayor a menor sentido para tu situación de hoy:

1. **Carta de presentación (recomendado).** Vuelve público, MIT, con un README
   que lleve a tus servicios. Costo cero, riesgo cero, y convierte las cinco
   horas de exposición de hoy en algo que juega a tu favor en vez de
   preocuparte. Lo que se «protege» deja de ser el código y pasa a ser tu
   nombre encima de él.

2. **Gratis con versión de paga, en español, para no técnicos.** Es el único
   hueco real del mapa. Pero exige empaquetado firmado, sitio, cobro, soporte y
   una función de pago que hoy no existe. Semanas de trabajo, contra un público
   con poca disposición a pagar. **No ahora**: DupliKnet está publicado en Play
   y VendoVox sin terminar — los dos tienen más camino recorrido y más upside.

3. **Cerrado y de pago a $5.** Es el que menos recomiendo: no puedes proteger el
   código, no puedes revocar el MIT ya entregado, compites con QtScrcpy gratis y
   con Vysor arriba, y el margen no cubre el soporte.

**Lo que sí haría ya, cueste lo que cueste (nada):** dejarlo privado unos días
no rompe nada y es reversible con un clic. La decisión de visibilidad depende
del camino que elijas, no al revés.

---

## Fuentes

- [Vysor Pro — precios](https://vysor.org/vysor-pro/) · [Vysor en Capterra](https://www.capterra.com/p/235009/Vysor/)
- [AirDroid Personal — precios](https://www.airdroid.com/pricing/airdroid-personal/) · [AirDroid Cast — precios](https://www.airdroid.com/pricing/airdroid-cast/)
- [QtScrcpy y alternativas comparadas (2026)](https://sakuradevjp.github.io/ChargeCast-notes/blog/scrcpy-gui-alternatives/) · [Scrcpy GUI](https://scrcpygui.com/)
- [Apache License 2.0 — texto oficial](https://www.apache.org/licenses/LICENSE-2.0) · [Qué exige al redistribuir binarios](https://fossa.com/blog/open-source-licenses-101-apache-license-2-0/)
- [PS2EXE — README con el parámetro `-extract`](https://github.com/MScholtes/PS2EXE/blob/master/README.md)
- [Microsoft Store — registro gratuito para desarrolladores individuales](https://blogs.windows.com/windowsdeveloper/2025/09/10/free-developer-registration-for-individual-developers-on-microsoft-store/) · [Gumroad — comisión y modelo](https://www.builtbyfoundry.io/blog/gumroad-review-2026-is-it-still-worth-it)
