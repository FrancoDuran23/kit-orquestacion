---
name: configurar-orquestacion
description: "Configura un repo para orquestar agentes de punta a punta: mira el repo, pregunta qué suscripciones tiene la persona y para qué quiere cada una, recomienda quién planifica, quién ejecuta y quién juzga, corre el setup de las skills de mattpocock (tracker, labels, glosario) y deja Orca, el kit, slices y Jev funcionando con un slice de prueba. Correr una vez por repo."
disable-model-invocation: true
---

# Configurar orquestación

Configurar Orca a mano es engorroso. Esta skill lo hace conversando: **mira, pregunta, recomienda, muestra el borrador, escribe y verifica.**

## Reglas

- **El repo se mira; las cuentas se preguntan.** Del repo leé lo que haga falta (remote, `CLAUDE.md`, tests, config previa). De las suscripciones y cuentas, no leas credenciales, tokens ni archivos de configuración de cuentas: preguntá.
- **Una sección, una respuesta.** Cada pregunta va con la opción recomendada primero, para que se acepte con un "sí". Si al mirar el repo una sección ya quedó resuelta, salteala y decí por qué.
- **Borrador antes de escribir.** Todo lo que se escribe en el repo se muestra primero y se puede editar.
- **Cada paso se verifica** con un comando que demuestre que quedó bien. Si falla, se arregla antes de seguir.
- **Los logins y la confianza de carpetas los hace la persona** (en Claude Code con `! <comando>`; en otros clientes, en su terminal). Nunca los aceptes vos mandando teclas.
- **Nada irreversible sin OK:** push, crear repos o labels remotos, gastar en APIs pagas.

## 1. Mirar

Sin preguntar nada todavía:

- `git remote -v`: GitHub, GitLab u otro.
- `CLAUDE.md` / `AGENTS.md`: ¿existen? ¿ya tienen un bloque `## Agent skills` o `## Orquestación`?
- `docs/agents/`: ¿ya se corrió este setup o el de mattpocock antes?
- Cómo se corren los tests (`pyproject.toml`, `package.json`, `Cargo.toml`, `Makefile`, CI) y si usan base de datos.
- Qué hay instalado: `orca`, `slices`, `juez-jev`, `engram`, `orca.yaml`, la config de MCP de cada cliente, y si están las skills de mattpocock (`setup-matt-pocock-skills`, `to-tickets`, `triage`) y las del kit. Las skills pueden estar en `~/.agents/skills`, `~/.claude/skills`, `.cursor/skills`, `.agents/skills` u otra carpeta del cliente.
- `orca status` y `orca repo list`: ¿Orca corre? ¿el repo ya está registrado?

Resumí en pocas líneas qué hay y qué falta.

## 2. Preguntar

En este orden, de a una sección (saltá las que ya estén resueltas). Usá la forma de preguntar con opciones que tenga tu cliente; si no tiene, numerá las opciones en el texto.

**0. Clientes.** ¿Con qué agentes trabajás? (selección múltiple: Claude Code, Cursor, Codex, Gemini CLI, OpenCode). Define en qué formato se instalan los hooks, el MCP y las skills (`install.sh --agentes ...`).

**A. Suscripciones** (selección múltiple). Recomendado: lo que tenga.
- Claude: Pro / Max 5x / Max 20x / Team / API
- ChatGPT: Plus / Pro (incluye Codex CLI)
- Cursor: Pro / Ultra (`cursor-agent`, con Grok, Composer, GPT y Claude)
- Gemini · Grok / SuperGrok
- TypeSafe (Jev, el juez)

**B. Qué cuidar.** Recomendado: no quedarme sin cuota. Otras opciones: calidad, velocidad.

**C. Plan de roles.** Armalo con la tabla de abajo y presentalo como recomendación: "¿Lo dejamos así?".

Principio: **el modelo más capaz piensa poco y decide mucho; el que tiene más cuota escribe mucho.**

| Rol | Gasta | Conviene |
|---|---|---|
| Coordinador (planifica y verifica, en Orca) | pocos tokens, alto valor | el modelo más capaz |
| Workers (ejecutan) | la mayoría de los tokens | la suscripción con más cuota |
| Juez | muy pocos | **distinto del ejecutor**: Jev si hay TypeSafe; si no, otro modelo |
| Lo fácil (leer, buscar) | medio | el modelo chico |

| Tiene | Coordinador | Workers | Juez | Reserva |
|---|---|---|---|---|
| Claude Max + Cursor | Opus | Grok vía Cursor (`AGENTE_ORCA=cursor`, `MODELO=cursor-grok-4.6-high`) | Jev o Sonnet | Composer → Sonnet |
| Claude Max + ChatGPT | Opus | Codex | Jev o Sonnet | Sonnet |
| Solo Claude Max | Opus | Sonnet | Jev o Haiku | bajar el paralelismo |
| Solo Claude Pro | Sonnet | Sonnet, de a 1 o 2 | Jev o Haiku | no orquestar lo chico |
| ChatGPT + Cursor | GPT alto en Codex | Grok o Composer | Jev | Codex |
| Solo Cursor | modelo alto en Cursor | Composer / Grok | Jev | otro modelo de Cursor |

Si tiene varias cuentas del mismo proveedor: `orca account add --agent claude|codex`, y Orca las rota.

**D. Modo.** ¿Hasta dónde avanza solo `./slices auto`? Recomendado: `semi` si priorizó calidad, `auto` si priorizó cuota o velocidad.
- `auto`: lanza por dependencias, verifica (tests + Jev), relanza con el motivo y mergea a la rama del ticket solo. Frena en preguntas del worker, conflictos y `MAX_INTENTOS` rechazos.
- `semi`: igual, pero frena antes de cada merge para revisar el diff.
- `manual`: cada paso a mano (`lanzar`, `verificar`, `mergear`).
Push y MR nunca son automáticos.

**E. Memoria (opcional).** ¿Querés que los agentes recuerden decisiones y contexto entre sesiones con [Engram](https://github.com/Gentleman-Programming/engram)? Recomendado: sí, si trabaja en el mismo repo por semanas. `install.sh --con-engram` baja la última versión estable y corre `engram setup <cliente>` para cada cliente elegido.

**F. Checks.** Mostrá los comandos de tests detectados: "¿Son estos?". Si los tests usan base de datos, preguntá cómo se crea una base por worktree.

## 3. Setup de mattpocock (tracker, labels, glosario)

Las skills de planificación (`to-tickets`, `to-spec`, `triage`) necesitan saber dónde viven los issues. Ese setup es de mattpocock, y esta skill lo corre como un paso más:

1. Buscá su `SKILL.md` en las carpetas de skills (`~/.agents/skills/`, `~/.claude/skills/`, `.agents/skills/`, `.claude/skills/`, `.cursor/skills/`).
2. **Leelo y seguí su proceso tal cual** (explorar, secciones A/B/C, borrador, escribir `docs/agents/*.md` y su bloque `## Agent skills`). Está marcado como de uso manual, así que no lo invoques como skill: seguirlo a mano es la forma de llamarlo.
3. Lo que ya averiguaste en el paso 1 no se vuelve a preguntar (por ejemplo, un remote de GitLab ya define el tracker: proponé GitLab directamente).
4. Si no está instalado: ofrecé `npx skills add mattpocock/skills -s setup-matt-pocock-skills -s to-tickets -s triage -s to-spec` o el `install.sh` del kit. Si no lo quiere, salteá este paso.

## 4. Borrador

Mostrá todo junto, para editar antes de escribir:

- `slices.conf` con el plan:
  ```bash
  LANZADOR="orca"
  AGENTE_ORCA="cursor"      # workers: cursor (cursor-agent) | claude | codex | grok (CLI de xAI, otra suscripción)
  MODELO="cursor-grok-4.6-high"  # Grok vía Cursor; vacío = el default del agente
  JUEZ="jev"                # o "claude"
  MODO="auto"               # auto | semi | manual
  CHECKS=( "tests::<comando real>" )
  ```
- `orca.yaml → scripts.setup`: dependencias, `.env` y la base por worktree. `.worktreeinclude` con el `.env`.
- `docs/agents/orquestacion.md`: los roles, modelos, reserva, juez y checks elegidos; la tabla "Qué skill usar en cada momento" de `orquestar-slices`, recortada a las skills instaladas en este repo; y cómo arrancar (*"con cada pedido, `start`: decide la ruta; si es orquestar, sigue `orquestar-slices`"*).
- Una línea más en el bloque `## Agent skills` (el mismo `AGENTS.md` o `CLAUDE.md` que editó el setup de mattpocock; nunca crees el otro). `AGENTS.md` es el que leen todos los clientes; si solo existe `CLAUDE.md`, proponé que importe `@AGENTS.md`:
  ```markdown
  ### Orquestación

  Orca supervisa workers y `./slices` verifica con Jev antes de mergear. Qué skill usar en cada momento del flujo: see `docs/agents/orquestacion.md`.
  ```

## 5. Configurar y verificar

Un paso a la vez:

1. **Orca corriendo:** `orca status` → `runtimeReachable: true`.
2. **Logins:** solo los CLIs del plan (`claude`, `cursor-agent login`, `codex login`, `gemini`). Los corre la persona; vos verificás con una llamada mínima.
3. **Cuentas en Orca** (opcional): `orca account add --agent ...` → `orca account list`.
4. **Repo en Orca:** `orca repo add --path <repo>` → `orca repo list`.
5. **Kit:** `<kit>/install.sh --agentes <los de la sección 0> [--con-engram]` para el usuario, y `--proyecto <repo>` si la config va a viajar con el repo. Después `./slices init` y los archivos del borrador aprobado. Si el repo es de un cliente o del equipo y la persona no quiere commitear nada, agregá todo a `.git/info/exclude`.
6. **Confianza del repo, una vez:** la persona abre el agente en la raíz del repo y acepta "trust this folder". Los worktrees de `.slices/` la heredan. Sin esto, cada worker queda frenado y `worker-start` falla con `agent_readiness: timeout`.
7. **Jev** (si tiene TypeSafe): la key en `~/.config/kit-orquestacion/jev.key` (permisos 600) o en `JEV_API_KEY`. La pega la persona; no la imprimas.
8. **Ajustes en la app de Orca:** Settings → Repository → setup "Run automatically"; Settings → Agents → agente por defecto = el coordinador.

## 6. Prueba de humo

Un slice de juguete, de punta a punta:

1. `./slices nuevo prueba "Slice de prueba"`, con un SPEC mínimo: una función trivial y 2 tests exigidos.
2. `SLICES_MODO=auto ./slices auto <id>`: aparece el worker en Orca y el loop espera su `worker_done`.
3. El loop verifica solo → `CIERRA`, con Jev cubriendo los 2 tests, y mergea.
4. Deshacé la prueba: `git worktree remove .slices/<id>`, `git branch -D slice-<id>`, el SPEC y `orca orchestration worker-release --dispatch <id>`.

Si algo falla, se arregla acá, no en el primer ticket real.

## 7. Listo

Contale a la persona qué quedó configurado, qué skills leen ahora `docs/agents/` y cómo se sigue: **con cada pedido, `start`** (decide si es solo lectura, directo u orquestar, y si hace falta grill). Para cambiar algo después, se editan `docs/agents/*.md` y `slices.conf`; volver a correr esta skill solo hace falta para empezar de cero.
