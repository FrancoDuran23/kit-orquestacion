---
name: iniciar-orquestacion
description: Usar cuando alguien quiere empezar a orquestar agentes en un repo, configurar Orca desde cero, o pregunta "qué suscripción uso para qué" o "cómo armo el flujo". Entrevista a la persona sobre sus suscripciones y su trabajo, le recomienda quién planifica, quién ejecuta y quién juzga para aprovechar la cuota, y la guía paso a paso hasta dejar Orca, el kit y el primer slice funcionando. También responde a "start orchestration" o "iniciar orquestación".
---

# Iniciar orquestación

Configurar Orca a mano es engorroso. Esta skill lo hace conversando: **pregunta, recomienda, guía y verifica**. No adivina.

## Reglas

- **Se pregunta, no se detecta.** No leas archivos de credenciales, tokens ni configuraciones de cuentas para averiguar qué tiene la persona. Lo que no sepas, lo preguntás.
- **En rondas cortas.** Usá la herramienta de preguntas (AskUserQuestion o equivalente) con opciones y una marcada como "(Recomendado)". No más de 4 preguntas por ronda.
- **Un paso a la vez.** Cada paso de configuración termina con un comando que demuestra que quedó bien. Si falla, se arregla antes de seguir.
- **Los logins los hace la persona.** Cuando haga falta iniciar sesión, pedile que lo corra ella (en Claude Code: `! <comando>`).
- **Nada irreversible sin OK:** push, crear repos remotos o gastar en APIs pagas.

## Ronda 1: qué tiene

1. **¿Qué suscripciones o accesos tenés?** (selección múltiple)
   - Claude: Pro / Max 5x / Max 20x / Team / API key
   - ChatGPT: Plus / Pro (incluye Codex CLI)
   - Cursor: Pro / Ultra (incluye `cursor-agent`, con Grok, Composer, GPT y Claude)
   - Gemini (Gemini CLI)
   - Grok / SuperGrok (Grok CLI)
   - TypeSafe (Jev, el juez)
2. **¿Qué querés cuidar más?** Calidad / velocidad / no quedarme sin cuota (Recomendado: no quedarme sin cuota).
3. **¿Qué tipo de trabajo?** Backend con tests / frontend y UI / mixto / scripts e infra.
4. **¿En qué repo?** La ruta.

## Ronda 2: recomendar el plan

Principio: **el modelo más capaz piensa poco y decide mucho; el que más cuota tiene escribe mucho.** Planificar y verificar gasta pocos tokens; implementar gasta muchos.

| Rol | Gasta | Qué conviene |
|---|---|---|
| Planifica y verifica (coordinador en Orca) | pocos tokens, alto valor | el modelo más capaz que tenga |
| Ejecuta (workers) | la mayoría de los tokens | la suscripción con más cuota, o la que esté "sobrando" |
| Juzga | muy pocos | **distinto del ejecutor**: Jev si tiene TypeSafe; si no, otro modelo |
| Lo fácil (leer, buscar, resumir) | medio | el modelo chico (Haiku, Flash, mini) |

Combinaciones típicas (adaptá a lo que respondió):

| Tiene | Coordinador | Workers | Juez | Reserva si se acaba la cuota |
|---|---|---|---|---|
| Claude Max + Cursor | Opus | Grok vía Cursor (`AGENTE_ORCA=grok` o `cursor`) | Jev o Sonnet | Composer → Sonnet |
| Claude Max + ChatGPT | Opus | Codex | Jev o Sonnet | Sonnet |
| Solo Claude Max | Opus | Sonnet | Jev o Haiku | bajar el paralelismo |
| Solo Claude Pro | Sonnet | Sonnet, de a 1 o 2 | Jev o Haiku | no orquestar tareas chicas |
| ChatGPT + Cursor | GPT de mayor nivel en Codex | Grok o Composer vía Cursor | Jev | Codex |
| Solo Cursor | modelo alto en Cursor | Composer / Grok | Jev | otro modelo de Cursor |

Si tiene varias cuentas del mismo proveedor, Orca puede rotarlas: `orca account add --agent claude|codex`.

Mostrale el plan en una tabla corta y preguntá: **¿Lo dejamos así o cambiás algo?** Ajustá y seguí.

## Ronda 3: configurar, paso a paso

Cada paso: qué se hace, el comando, y cómo se verifica.

1. **Orca corriendo.** `orca status` → `runtimeReachable: true`. Si no está instalado: https://github.com/stablyai/orca.
2. **CLIs con sesión iniciada**, solo los del plan. La persona corre el login (`! claude`, `! cursor-agent login`, `! codex login`, `! gemini`) y vos verificás con una llamada mínima del CLI.
3. **Cuentas en Orca** (opcional, para rotar cuota): `orca account add --agent claude` o `--agent codex`. Se verifica con `orca account list`.
4. **Repo en Orca.** `orca repo add --path <repo>`. Se verifica con `orca repo list`.
5. **Kit en el repo.** `<kit>/install.sh --proyecto <repo>`: skills, hooks, MCP de Playwright, `slices`, `juez-jev`, `orca.yaml`.
6. **`./slices init`** y después editar `slices.conf` con el plan:
   ```bash
   LANZADOR="orca"
   AGENTE_ORCA="grok"        # el de los workers
   MODELO=""                 # o el id exacto del modelo
   JUEZ="jev"                # o "claude"
   CHECKS=( "tests::<comando de tests del repo>" )
   ```
   Mostrale los `CHECKS` detectados y confirmá que son los comandos reales del repo.
7. **`orca.yaml`.** En `scripts.setup` va lo que necesita cada worktree nuevo: dependencias, `.env` y una base de pruebas propia si los tests usan base de datos. `.worktreeinclude` lleva el `.env`.
8. **Jev** (si tiene TypeSafe). Guardá la key en `~/.config/kit-orquestacion/jev.key` con permisos 600, o en `JEV_API_KEY`. La pega la persona; vos no la imprimas.
9. **Ajustes de Orca** (en la app): Settings → Repository → setup "Run automatically"; Settings → Agents → agente por defecto = el coordinador.

## Ronda 4: prueba de humo

Un slice de juguete de punta a punta, en una rama descartable:

1. `./slices nuevo prueba "Slice de prueba"`, con un SPEC mínimo: una función trivial y su test.
2. `./slices lanzar 001-prueba`: aparece el worker en Orca.
3. Al llegar el `worker_done`: `./slices verificar 001-prueba` → recibo con `"cerrado": true`.
4. Borrá la prueba: `git worktree remove`, la rama y el SPEC.

Si algo falla, se arregla acá, no en el primer ticket real.

## Cierre

Dejá en el repo un `ORQUESTACION.md` corto con el plan elegido (roles, modelos, reserva, juez, checks) y cómo se arranca: "pedile al coordinador en Orca que use `orquestar-slices` con el ticket". Mostráselo a la persona antes de commitearlo.
