# Guion del workshop

Para gente que nunca orquestó agentes. Una hora, cuatro bloques.

## 1. El problema (10 min)

- Una sola IA con un ticket grande se pierde, mezcla cosas y dice "listo" sin estar listo.
- Pregunta al público: ¿quién confió alguna vez en un "ya está" de una IA y no estaba?
- Idea central: **no le pedís todo a una sola IA; armás un equipo donde nadie se corrige a sí mismo.**

Material: la analogía de la obra y la tabla de roles de [metodo.md](metodo.md).

## 2. Slices (15 min)

- Qué es un slice: la pizza y las porciones.
- Demo en vivo: un ticket real partido en 3 o 4 slices, con la tabla de dependencias (el DAG).
- Mostrar un SPEC: alcance de archivos, tests exigidos, fuera de alcance.
- `./slices dag`: las olas en pantalla. Preguntar al público qué slice movería de ola y por qué.
- Mensaje: un pedazo chico se verifica fácil; uno grande, no.

## 3. Orquestar con Orca (20 min)

- Cómo se hace normalmente en Orca, y el hueco: Orca le cree al agente. Ver [orca-y-slices.md](orca-y-slices.md).
- Lo que suma slices: el inspector (tests por fuera + Jev).
- Demo en vivo:
  1. `./slices auto` con dos slices, uno depende del otro.
  2. Mirar en Orca cómo aparecen los workers.
  3. Un slice al que le falta un test: Jev lo rechaza y nombra el test que falta.
  4. El reintento recibe el motivo, lo arregla, cierra y se mergea solo.
- Los modos: `auto`, `semi`, `manual`.

## 4. Llevárselo (15 min)

- Instalar el kit (README) y correr `/configurar-orquestacion` en un repo propio: pregunta qué suscripciones tienen y recomienda quién planifica, quién ejecuta y quién juzga.
- La regla de oro: **el modelo más capaz piensa poco y decide mucho; el que tiene más cuota escribe mucho.**
- Cierre: lo que se aprende a los golpes (tests de a uno, cada error se vuelve regla, no orquestar lo chico).

## Antes del workshop

- Repo de demo registrado en Orca y con la confianza del agente aceptada.
- Dos SPECs listos, uno con un test exigido que el agente "olvide" (para mostrar el rechazo).
- Key de Jev cargada, o `JUEZ="claude"` como alternativa.
- Un plan B grabado en video por si falla la red.
