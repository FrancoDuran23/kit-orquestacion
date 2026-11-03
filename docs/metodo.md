# El método

## En una frase

No le pedís todo a una sola IA. Armás un equipo donde cada uno hace una sola cosa, y nadie se corrige a sí mismo.

## La analogía: una obra

| Rol | En la obra | En el kit |
|---|---|---|
| Arquitecto | lee el pedido, lo parte y dibuja el plano de cada parte; no pone ladrillos | el modelo más capaz (coordinador) |
| Albañiles | cada uno construye su parte, en su terreno, en paralelo | workers con un modelo rápido y con cuota |
| Inspector | mira el resultado y dice "cierra" o "no cierra"; no arregla | checks deterministas + un juez (Jev) |
| Capataz | reparte, vigila, cambia de albañil si uno se cae | Orca + `slices` |
| Dueño | revisa al final, no aprueba cada ladrillo | la persona |

## Qué es un slice

Una tarea chica que se le da a un solo agente. El ticket es la pizza; el slice, una porción.

Ticket "agregar teletrabajo":

| Slice | Qué hace | Depende de |
|---|---|---|
| 001 | campo en la base | nada |
| 002 | el sistema cuenta esas marcas | 001 |
| 003 | la pantalla para marcar | 001 |
| 004 | el reporte que las muestra | 002 |

002 y 003 corren en paralelo. Esa tabla de dependencias es el **DAG**.

Cada slice tiene:

- **un SPEC**: qué hacer, qué archivos puede tocar y qué tests tiene que pasar;
- **su copia del repo** (un worktree), para que dos agentes no se pisen;
- **un recibo**: los tests corridos por fuera y el veredicto del juez.

Un pedazo chico se verifica fácil; si un agente se equivoca, se rehace un slice y no el ticket entero.

## Las 6 reglas

1. **Partir antes de hacer.** Lo independiente corre en paralelo.
2. **Cada pedazo tiene un contrato (SPEC).** Sin eso, el agente improvisa.
3. **No creerle al que hizo el trabajo.** Que diga "listo" no alcanza: los tests se re-corren por fuera y un juez compara los tests contra el SPEC.
4. **El que piensa no ejecuta y el que ejecuta no decide.** El caro planifica, el rápido codifica, el chico lee y busca, el código orquesta.
5. **Review en loop** hasta que una vuelta salga limpia, hecho por un modelo distinto del autor.
6. **Frenar solo en lo irreversible.** Push, merge remoto, publicar y borrar datos pasan por una persona; lo demás avanza solo.

## Lo que se aprende a los golpes

- **No todo se paraleliza.** El código sí; los tests no, si comparten base de datos y RAM. La regla `tests-de-a-uno` los pone en fila.
- **Cada error se vuelve una regla escrita** (en un script, en `AGENTS.md` o en una regla de hooks). Si algo se corrige a mano dos veces, se automatiza.
- **Si la tarea es chica, no orquestes.** Un agente bien guiado le gana a cinco mal coordinados.

## Para probarlo sin nada instalado

Con un ticket real: pedile a una IA que lo parta en 3 pedazos con sus tests, dale cada pedazo a otra sesión, y corré vos los tests antes de aceptar cada uno. Ese es el método; el kit lo automatiza.
