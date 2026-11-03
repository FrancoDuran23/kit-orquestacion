---
name: start
description: "Punto de entrada para cada pedido de trabajo en un repo ya configurado. Decide la ruta antes de tocar nada: si solo hay que explicar o investigar; si hace falta grill o alcanza con dos o tres preguntas; si se hace directo o se orquesta en slices. Usar cuando la persona pide hacer algo (un ticket, un cambio, una feature, un bug) y todavía no se eligió cómo encararlo."
---

# Start

Cada pedido arranca igual: **mirar, decidir la ruta, decirla en una línea y seguir.** El proceso es proporcional al pedido: ni grill para todo ni slices para todo.

Basado en la filosofía de [Organic Driven Development (ODD)](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/intended-usage.md) de Gentleman Programming, adaptado a este kit (slices, Orca y Jev).

## 1. ¿El pedido autoriza un cambio?

- **"Explicame", "¿por qué…?", "investigá", "¿qué pasa si…?"** → solo lectura. Explorá y respondé; no se toca código ni se crean ramas.
- **"Hacé", "arreglá", "agregá", un ticket** → autoriza un cambio. Seguí.
- **Si no queda claro**, preguntá eso solo, en una línea.

## 2. Explorar antes de preguntar

Leé el código, el ticket (`glab issue view N --comments` / `gh issue view N --comments`), `AGENTS.md`, `docs/agents/` y, si está Engram, lo que haya guardado sobre el tema. Las preguntas que el código responde no se le hacen a la persona.

## 3. ¿Hace falta grill?

Contá las decisiones que **no podés tomar con seguridad** (las que cambian el resultado y no se deducen del código ni del ticket):

| Decisiones abiertas | Qué hacer |
|---|---|
| 0 | Nada que preguntar: seguí directo. |
| 1 a 3, independientes | Preguntalas juntas, con tu recomendación en cada una. No hace falta grill. |
| Muchas, o encadenadas (una depende de otra) | `grilling`: el árbol de decisiones, de a rondas. Si aparecen términos del dominio, `grill-with-docs`. |

Lo que tiene un default razonable no se pregunta: se decide, se dice y se sigue.

## 4. Elegir la ruta

| Ruta | Cuándo | Cómo |
|---|---|---|
| **Directo** | chico y entendido, o grande pero en una sola superficie | Lo hacés vos. Sin archivos de tarea. Test primero si hay uno que se pueda correr. |
| **Directo con plan** | sustancial, pero sin partes que puedan ir en paralelo | Una lista de tareas en el ticket o en Engram; commits de ~400 líneas, lo riesgoso en su propio commit. |
| **Orquestar** | hay un **motivo con nombre** para delegar (abajo) | `orquestar-slices`: partir (`to-tickets`), SPECs, `./slices dag`, `./slices auto`. |

Motivos con nombre para orquestar (alcanza uno):

- **Escritores en paralelo** sobre partes del código que no se tocan entre sí.
- **Verificación independiente** de un cambio de alto riesgo (dinero, permisos, datos, migraciones).
- **Cuota o contexto:** el volumen de código conviene que lo escriba el modelo con más cuota, o el trabajo no entra en una sesión.
- **Exploración** amplia que hay que mapear antes de decidir.

La cantidad de archivos **no** es un motivo. Si no podés nombrar el motivo, la ruta es directo.

Decí la ruta en una línea antes de empezar, con su porqué: *"Ruta: orquestar en 3 slices; motivo: el modelo y la pantalla no se tocan y van en paralelo"*. Si la ruta es orquestar, esperá el OK después de mostrar el DAG; si es directo, seguí.

## 5. Hacer

- **Test primero** cuando hay un test que se pueda correr y un resultado esperado claro: un test en rojo por regla pedida, después en verde. Si se toca algo que ya existía, un test que pruebe que lo de antes sigue andando. Nada más que eso.
- **Si el alcance cambia a mitad de camino**, decilo y actualizá el plan; un hallazgo no amplía la autorización.
- **Si está Engram**, guardá las decisiones y lo descubierto, para retomar en otra sesión.

## 6. Cerrar

`code-review-en-loop` → `qa-con-video` si hay cambios visibles → `pr` para el cuerpo del MR/PR. Push, MR y merge son decisiones separadas de la persona.
