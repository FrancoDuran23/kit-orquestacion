---
name: orquestar-slices
description: Usar cuando un ticket o pedido es lo bastante grande para repartirlo entre varios agentes, cuando el usuario pide orquestar, partir en slices, armar el DAG, lanzar workers (Grok/Cursor, Codex, Claude, Orca) o verificar lo que devolvieron. Define roles, el SPEC de cada slice, la verificación por recibo y el merge con gate. No usar para tareas chicas: un solo agente bien guiado le gana a cinco mal coordinados.
---

# Orquestar por slices

Un modelo planifica, otros ejecutan, un juez verifica y **el código orquesta**. Nadie aprueba su propio trabajo. El estado vive en archivos y en git, no en la memoria de un modelo.

## 0. ¿Vale la pena?

Partí solo si hay **al menos dos pedazos independientes** o si el trabajo no entra en una sesión. Si es un fix de una función, hacelo directo. Para decidir el reparto en casos dudosos, cargá `kero-orchestrate`.

## 1. Roles

| Rol | Por defecto | Hace | No hace |
|---|---|---|---|
| Planifica | el modelo más caro (Opus) | parte en slices, escribe SPECs, ordena el DAG, lee recibos | no pica código de los slices |
| Ejecuta | un modelo rápido por CLI (`cursor-agent` con Grok, `codex`, `claude -p`) | implementa un slice entero en su worktree y deja el recibo | no decide qué slice va ni en qué orden |
| Juzga | checks deterministas + Jev (TypeSafe), o un modelo distinto del ejecutor | dice si el recibo **cierra** o **no cierra** | no escribe ni arregla |
| Orquesta | Orca (workers, mailbox, gates) + `slices` (SPEC, verificación, merge) | lanza, supervisa, verifica, mergea | no improvisa |
| Lo fácil | un modelo chico (Haiku) | leer docs, buscar, resumir | no decide |
| Supervisa | la persona | revisa al final | no aprueba cada paso |

Si el ejecutor se queda sin cuota, se cambia de modelo (cadena de reserva) solo ante un error de cuota. Cualquier otro error se reporta, no se esconde.

## 2. Partir en slices (el DAG)

- Un slice es un cambio que se puede verificar solo: tiene sus tests y no rompe nada si entra sin los demás.
- Cada slice declara **de qué depende**. Lo que no depende de nada corre en paralelo.
- Dos slices que tocan el mismo archivo **no** van en paralelo: o se unen, o se encadenan.

## 3. El SPEC es el contrato

`./slices nuevo <nombre> "<título>"` genera `specs/NNN-nombre.spec.md`. Completalo **antes** de lanzar:

- **Depende de:** ids de otros slices, o "nada".
- **Alcance de archivos:** lo único que el ejecutor puede tocar.
- **Qué tiene que pasar:** comportamiento, con el caso borde dicho.
- **Tests exigidos:** uno por comportamiento, con entrada y salida esperada.
- **Fuera de alcance:** lo que parece parte de esto y no lo es.

Commiteá el SPEC: así el número queda tomado y el hijo ve la versión de la rama base.

## 4. Lanzar: Orca supervisa, slices verifica

Si el repo todavía no está configurado, cargá antes `iniciar-orquestacion`.

Con `LANZADOR="orca"` en `slices.conf` (el default si Orca está instalado):

```bash
./slices lanzar 001-a 002-b            # un worktree y una rama por slice + un worker de Orca en cada uno
./slices estado                        # en Orca / cerró / NO cerró: motivo / mergeado
```

Cada `lanzar` crea el worktree con git y le pide a Orca un worker supervisado (`orca orchestration worker-start --worktree path:<wt> --agent $AGENTE_ORCA`) dentro de un Run del repo. De Orca se usa:

- **La interfaz:** cada slice aparece como worker, con su terminal.
- **`ask` / `reply`:** si el worker tiene una duda bloqueante, pregunta. Contestale vos, que sos el coordinador.
- **Heartbeats y `worker-list`:** para saber si sigue vivo.
- **Gates** (`gate-create`) para lo irreversible.

El loop del coordinador es el de la skill `orchestration` de Orca (`check --wait --types worker_done,escalation,question`), con **una regla agregada: un `worker_done` no se acepta sin recibo verde.**

```text
llega worker_done del slice X
  → ./slices verificar X          (re-corre CHECKS + Jev)
  → CIERRA:    ./slices mergear X  y  orca orchestration worker-release --dispatch <id>
  → NO CIERRA: ./slices lanzar X   (nuevo worker con el motivo y el veredicto del juez)
  → 3 veces NO CIERRA: parar y contárselo a la persona; el problema está en el SPEC
```

Sin Orca (`LANZADOR="local"`): el hijo corre desacoplado (`systemd-run` o `setsid`), `MAX_PARALELO` limita la concurrencia y `verificar` corre solo al terminar.

**El recurso compartido manda.** Código y review se paralelizan; los tests no (una base, poca RAM). El hook `tests-de-a-uno.sh` los pone en fila. Si cada worktree usa su propia base de pruebas, ponela en `orca.yaml → scripts.setup`.

## 5. No creerle al ejecutor

`./slices verificar <id>` corre por fuera de la sesión del worker:

1. Re-ejecuta cada `CHECKS` de `slices.conf`.
2. **0 archivos tocados → no cierra**: que el repo ya pasara los tests antes no prueba nada.
3. **Sin recibo** (`===RECIBO===` en el log o en `recibos/<id>/recibo-agente.md`) **→ no cierra.**
4. Si los checks pasan, juzga **Jev** (`JUEZ="jev"`, script `juez-jev`): una pregunta angosta por cada test exigido del SPEC ("¿hay un test que verifique esto?") y otra sobre si los tests son de relleno. Hace falta cubrir el 80% de los tests exigidos. Un juez que no contesta **no cuenta como aprobación**. Sin TypeSafe: `JUEZ="claude"`, con un modelo distinto del ejecutor.
5. Queda `recibos/<id>/recibo.json` (más `juez.txt` y `chequeos.log`).

Si no cerró, el próximo `lanzar` le pasa al worker el motivo, el veredicto del juez y la cola de los chequeos que fallaron, y sigue sobre lo que ya escribió.

"Listo" sin recibo verde no es listo.

## 6. Mergear e integrar

- `./slices mergear <id>` se niega sin `"cerrado": true`. `--forzar` existe y queda escrito en el commit.
- Después de integrar todos los slices: `code-review-en-loop` sobre el diff completo y `qa-con-video` si hay UI.
- El push y el MR los decide la persona (hook `gate-irreversible.sh`).

## 7. Higiene

- Revisá `git log --format=%B` de cada commit de un ejecutor: algunos CLIs agregan `Co-authored-by`. El hook git `commit-msg` lo saca solo.
- Cada error nuevo se convierte en regla escrita (en un script, en `AGENTS.md` o en un hook). Si se corrige a mano dos veces, se automatiza.
