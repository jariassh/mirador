# M-5 · Estudio de nombres

> Candidatos con colisión verificada, no lluvia de ideas. Cierra con una
> recomendación; la decisión de marca es de Jonathan.
>
> Fecha: 2026-09-15

---

## Los criterios, antes de los nombres

El nombre no tiene que posicionar en Google — el tráfico llega desde el
portafolio y desde `servicios.jariash.com`, no desde una búsqueda. Tiene que
cumplir otras cinco cosas:

1. **En español y pronunciable** por el público al que apunta.
2. **Sin tildes ni ñ.** Va a terminar en `%LOCALAPPDATA%\<nombre>`, en el nombre
   del repo y en el del acceso directo. Una tilde ahí es un problema técnico,
   no estético.
3. **Evocar mirar**, sin tener que explicarlo.
4. **Sin colisión cercana** — sobre todo con otro software del mismo rubro.
5. ⚠️ **Sin olor a espionaje.** Es una herramienta que muestra **tu propio**
   teléfono. Un nombre que sugiera vigilar a otro arranca con la peor
   asociación posible, en una categoría que ya carga esa fama.

---

## Los candidatos, con lo que se encontró

| Nombre         | GitHub (lo más parecido)                       | Otras colisiones                                                           | Veredicto               |
| :------------- | :--------------------------------------------- | :------------------------------------------------------------------------- | :---------------------- |
| **Mirador**    | `mirador` — visor de imágenes IIIF, 615 ★      | Marcas MIRADOR de Mirador Financial (2015) y Mirador Software Group (2024) | **Viable** — el actual  |
| **Catalejo**   | `Catalejo` — librería Java, 2 ★                | `catalejo.net` (empresa de TI en Chile), app Android «Catalejo / Spyglass» | **Viable** — el retador |
| **Vistazo**    | `vistazo` — repo vacío, 1 ★                    | **Revista Vistazo**, Ecuador, desde 1957, con apps en iOS y Android        | ❌ Descartado           |
| **Atalaya**    | `Atalaya` — monitor de antenas celulares, 55 ★ | **«La Atalaya»**, la revista de los Testigos de Jehová                     | ❌ Descartado           |
| **Retrovisor** | `RetroVisor` — capa de shaders en macOS, 56 ★  | —                                                                          | ❌ Descartado           |
| **Balcón**     | `balcony` — herramienta de AWS, 148 ★          | Lleva tilde                                                                | ❌ Descartado           |

**Dominios `.com`** (verificado por resolución DNS, que es indicio y no registro
formal): `catalejo.com` **no resuelve — posiblemente libre**. `mirador.com`,
`vistazo.com` y `atalaya.com` están ocupados. No es determinante —Mirador vive
bajo `jariash.com`—, pero es un punto a favor de Catalejo si algún día quiere
casa propia.

### Por qué cayó cada descartado

- **Vistazo** era el más simpático y el más natural en español («échale un
  vistazo a tu celular»), y lo mata una sola cosa: **Revista Vistazo** es una
  publicación ecuatoriana con más de 60 años y aplicaciones propias en las dos
  tiendas. Chocar de frente con una marca establecida **en el mismo idioma y el
  mismo mercado** es justo lo que no se debe hacer.
- **Atalaya** suena elegante y significa exactamente lo correcto — torre desde
  donde se vigila. Pero en todo el mundo hispanohablante **«La Atalaya» es la
  revista de los Testigos de Jehová**, y esa asociación llega antes que la
  herramienta. Además ya hay un `Atalaya` en GitHub que monitorea antenas
  celulares: rubro vecino.
- **Retrovisor** tenía la mejor metáfora de uso —mirar de reojo el teléfono
  mientras trabajas en el PC— pero ya existe `RetroVisor` en GitHub, también
  una capa de visualización. Y son cinco sílabas.
- **Balcón** lleva tilde, y sin ella («balcon») queda a un carácter de `balcony`,
  una herramienta de AWS con 148 estrellas.

---

## Los dos que quedan, frente a frente

**Mirador** — un lugar desde el cual miras. La metáfora encaja con lo que
realmente pasa: una ventana fija en tu escritorio a la que te asomas. Tono
cálido, cero olor a espionaje. **Su lunar:** en GitHub, `mirador` es un visor de
imágenes IIIF con 615 estrellas — de todos los candidatos, es **la colisión más
cercana en rubro**, porque también es un visor. Y hay dos marcas MIRADOR
registradas para software en Estados Unidos, aunque en el rubro financiero: otro
mercado, otro público, y esto es una herramienta gratuita con licencia MIT. El
riesgo legal real es prácticamente nulo.

**Catalejo** — el espacio está casi vacío: dos estrellas en GitHub, una empresa
chilena de TI en otro rubro, y el `.com` aparentemente libre. Es más distintivo
y más memorable, y tiene un ícono evidente. **Su lunar, y no es menor:** un
catalejo es un instrumento para **mirar lejos algo ajeno**. Para una herramienta
que espeja **tu propio** teléfono, roza el criterio 5 — y hay una app Android
llamada justamente «Catalejo / Spyglass» para observar a la distancia, que
refuerza esa lectura.

---

## Recomendación

**Quédate con Mirador.** La colisión que tiene es con un visor de manuscritos
digitalizados para bibliotecas: otro mundo, otro público, y tu repositorio vive
namespaceado en `jariassh/mirador`. A cambio, el nombre no tiene ni una gota de
connotación de vigilancia, que es el único riesgo de marca serio de esta
categoría — y eso no se arregla con una buena descripción.

**Si aun así quieres cambiar, el único candidato que sobrevive es Catalejo**, y
hay que asumir a cambio el matiz de «mirar lejos algo ajeno».

⚠️ **Y si se cambia, es ahora.** El repositorio está privado, con 0 forks y un
día de vida. Después de `M-2`, `M-3` y `M-4` el cambio toca el instalador, la
carpeta `%LOCALAPPDATA%\Mirador`, el ícono, los accesos directos, el README, el
CHANGELOG y el nombre del repo — tres veces el trabajo por el mismo resultado.

---

## Fuentes

- Colisiones en GitHub verificadas con `gh search repos` el 2026-09-15.
- Dominios verificados por resolución DNS el 2026-09-15 — indicio, no registro formal.
- [Marca MIRADOR SOFTWARE GROUP (Justia)](https://trademarks.justia.com/984/04/mirador-software-98404907.html) · [Marcas de Mirador Financial, Inc.](https://trademark.justia.com/owners/mirador-financial-inc-3146597)
- [Revista Vistazo en App Store](https://apps.apple.com/us/app/vistazo/id1573539467) · [Editorial Vistazo en Google Play](https://play.google.com/store/apps/details?id=com.newspaperdirect.vistazoandroid)
- [CATALEJO.NET — empresa de TI](https://www.catalejo.net/software.htm)
