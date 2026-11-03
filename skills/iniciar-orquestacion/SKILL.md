---
name: iniciar-orquestacion
description: "Configura un repo para orquestar agentes de punta a punta: mira el repo, pregunta qué suscripciones tiene la persona y para qué quiere cada una, recomienda quién planifica, quién ejecuta y quién juzga, corre el setup de las skills de mattpocock (tracker, labels, glosario) y deja Orca, el kit, slices y Jev funcionando con un slice de prueba. Correr una vez por repo."
disable-model-invocation: true
---

# Iniciar orquestación

Configurar Orca a mano es engorroso. Esta skill lo hace conversando: **mira, pregunta, recomienda, muestra el borrador, escribe y verifica.**

## Reglas

- **El repo se mira; las cuentas se preguntan.** Del repo leé lo que haga falta (remote, `CLAUDE.md`, tests, config previa). De las suscripciones y cuentas, no leas credenciales, tokens ni archivos de configuración de cuentas: preguntá.
- **Una sección, una respuesta.** Cada pregunta va con la opción recomendada primero, para que se acepte con un "sí". Si al mirar el repo una sección ya quedó resuelta, salteala y decí por qué.
- **Borrador antes de escribir.** Todo lo que se escribe en el repo se muestra primero y se puede editar.
- **Cada paso se verifica** con un comando que demuestre que quedó bien. Si falla, se arregla antes de seguir.
- **Los logins y la confianza de carpetas los hace la persona** (en Claude Code: `! <comando>`). Nunca los aceptes vos mandando teclas.
- **Nada irreversible sin OK:** push, crear repos o labels remotos, gastar en APIs pagas.

## 1. Mirar

Sin preguntar nada todavía:

- `git remote -v`: GitHub, GitLab u otro.
- `CLAUDE.md` / `AGENTS.md`: ¿existen? ¿ya tienen un bloque `## Agent skills` o `## Orquestación`?
- `docs/agents/`: ¿ya se corrió este setup o el de mattpocock antes?
- Cómo se corren los tests (`pyproject.toml`, `package.json`, `Cargo.toml`, `Makefile`, CI) y si usan base de datos.
- Qué hay instalado: `orca`, `slices`, `juez-jev`, `.mcp.json`, `orca.yaml`, y si están las skills de mattpocock (`setup-matt-pocock-skills`, `to-tickets`, `triage`) y las del kit.
- `orca status` y `orca repo list`: ¿Orca corre? ¿el repo ya está registrado?

Resumí en pocas líneas qué hay y qué falta.

## 2. Preguntar

En este orden, de a una sección (saltá las que ya estén resueltas):

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
| Claude Max + Cursor | Opus | Grok vía Cursor | Jev o Sonnet | Composer → Sonnet |
| Claude Max + ChatGPT | Opus | Codex | Jev o Sonnet | Sonnet |
| Solo Claude Max | Opus | Sonnet | Jev o Haiku | bajar el paralelismo |
| Solo Claude Pro | Sonnet | Sonnet, de a 1 o 2 | Jev o Haiku | no orquestar lo chico |
| ChatGPT + Cursor | GPT alto en Codex | Grok o Composer | Jev | Codex |
| Solo Cursor | modelo alto en Cursor | Composer / Grok | Jev | otro modelo de Cursor |

Si tiene varias cuentas del mismo proveedor: `orca account add --agent claude|codex`, y Orca las rota.

**D. Checks.** Mostrá los comandos de tests detectados: "¿Son estos?". Si los tests usan base de datos, preguntá cómo se crea una base por worktree.

## 3. Setup de mattpocock (tracker, labels, glosario)

Las skills de planificación (`to-tickets`, `to-spec`, `triage`) necesitan saber dónde viven los issues. Ese setup es de mattpocock, y esta skill lo corre como un paso más:

1. Buscá su `SKILL.md`: `.claude/skills/setup-matt-pocock-skills/`, `~/.claude/skills/setup-matt-pocock-skills/` o `~/.agents/skills/setup-matt-pocock-skills/`.
2. **Leelo y seguí su proceso tal cual** (explorar, secciones A/B/C, borrador, escribir `docs/agents/*.md` y su bloque `## Agent skills`). No lo invoques con la herramienta Skill: es de uso manual y no se puede. Seguirlo a mano es la forma de llamarlo.
3. Lo que ya averiguaste en el paso 1 no se vuelve a preguntar (por ejemplo, un remote de GitLab ya define el tracker: proponé GitLab directamente).
4. Si no está instalado: ofrecé `npx skills add mattpocock/skills -s setup-matt-pocock-skills -s to-tickets -s triage -s to-spec` o el `install.sh` del kit. Si no lo quiere, salteá este paso.

## 4. Borrador

Mostrá todo junto, para editar antes de escribir:

- `slices.conf` con el plan:
  ```bash
  LANZADOR="orca"
  AGENTE_ORCA="grok"        # workers
  MODELO=""                 # o el id exacto
  JUEZ="jev"                # o "claude"
  CHECKS=( "tests::<comando real>" )
  ```
- `orca.yaml → scripts.setup`: dependencias, `.env` y la base por worktree. `.worktreeinclude` con el `.env`.
- `docs/agents/orquestacion.md`: los roles, modelos, reserva, juez y checks elegidos; la tabla "Qué skill usar en cada momento" de `orquestar-slices`, recortada a las skills instaladas en este repo; y cómo arrancar (*"pedile al coordinador en Orca que use `orquestar-slices` con el ticket; para partir trabajo grande, `to-tickets` y después cada ticket es un `./slices nuevo`"*).
- Una línea más en el bloque `## Agent skills` (el mismo `CLAUDE.md` o `AGENTS.md` que editó el setup de mattpocock; nunca crees el otro):
  ```markdown
  ### Orquestación

  Orca supervisa workers y `./slices` verifica con Jev antes de mergear. Qué skill usar en cada momento del flujo: see `docs/agents/orquestacion.md`.
  ```

## 5. Configurar y verificar

Un paso a la vez:

1. **Orca corriendo:** `orca status` → `runtimeReachable: true`.
2. **Logins:** solo los CLIs del plan. La persona corre `! claude`, `! cursor-agent login`, `! codex login`; vos verificás con una llamada mínima.
3. **Cuentas en Orca** (opcional): `orca account add --agent ...` → `orca account list`.
4. **Repo en Orca:** `orca repo add --path <repo>` → `orca repo list`.
5. **Kit en el repo:** `<kit>/install.sh --proyecto <repo>`, y después `./slices init`. Escribí los archivos del borrador aprobado.
6. **Confianza del repo, una vez:** la persona abre el agente en la raíz del repo y acepta "trust this folder". Los worktrees de `.slices/` la heredan. Sin esto, cada worker queda frenado y `worker-start` falla con `agent_readiness: timeout`.
7. **Jev** (si tiene TypeSafe): la key en `~/.config/kit-orquestacion/jev.key` (permisos 600) o en `JEV_API_KEY`. La pega la persona; no la imprimas.
8. **Ajustes en la app de Orca:** Settings → Repository → setup "Run automatically"; Settings → Agents → agente por defecto = el coordinador.

## 6. Prueba de humo

Un slice de juguete, de punta a punta:

1. `./slices nuevo prueba "Slice de prueba"`, con un SPEC mínimo: una función trivial y 2 tests exigidos.
2. `./slices lanzar <id>`: aparece el worker en Orca.
3. Al llegar el `worker_done`: `./slices verificar <id>` → `CIERRA`, con Jev cubriendo los 2 tests.
4. Deshacé la prueba: `git worktree remove .slices/<id>`, `git branch -D slice-<id>`, el SPEC y `orca orchestration worker-release --dispatch <id>`.

Si algo falla, se arregla acá, no en el primer ticket real.

## 7. Listo

Contale a la persona qué quedó configurado, qué skills leen ahora `docs/agents/` y cómo se arranca un ticket. Para cambiar algo después, se editan `docs/agents/*.md` y `slices.conf`; volver a correr esta skill solo hace falta para empezar de cero.
