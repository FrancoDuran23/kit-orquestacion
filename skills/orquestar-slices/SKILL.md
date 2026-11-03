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
| Juzga | checks deterministas + un juez (Jev de TypeSafe, o Sonnet) | dice si el recibo **cierra** o **no cierra** | no escribe ni arregla |
| Orquesta | `bin/slices` u `orca orchestration` | lanza, limita concurrencia, verifica, mergea | no improvisa |
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

## 4. Lanzar

```bash
./slices init                          # una vez por repo: slices.conf, AGENTS.md, specs/
./slices lanzar 001-a 002-b 003-c      # un worktree y una rama por slice, en paralelo
./slices estado                        # corriendo / cerró / NO cerró: motivo / cortado a medias
```

- Cada hijo corre desacoplado de la terminal (`systemd-run --user` o `setsid nohup`).
- `MAX_PARALELO` en `slices.conf` limita cuántos corren a la vez.
- **El recurso compartido manda.** Código y review se paralelizan; los tests no (una base, poca RAM). El hook `tests-de-a-uno.sh` los encola solo. Si cada worktree usa su propia base de pruebas, ponela en `PREPARAR` (ej.: `.env` con sufijo por worktree).

### Con Orca

Lo mismo con las primitivas nativas (cargá la skill `orchestration` para los comandos exactos):

- Cada slice es una **task** con sus dependencias: `orca orchestration task-create`.
- Se lanza con `orca orchestration dispatch` o `worker-start`, en un worktree propio (`orca worktree create --agent <id> --prompt "<SPEC>"`).
- Lo irreversible pasa por un gate: `orca orchestration gate-create`.
- `orca worktree ps` muestra el estado de todos.

## 5. No creerle al ejecutor

`./slices verificar <id>` corre después del agente y por fuera de su sesión:

1. Re-ejecuta cada `CHECKS` de `slices.conf`.
2. **0 archivos tocados → no cierra**: que el repo ya pasara los tests antes no prueba nada.
3. **Sin bloque `===RECIBO===` → no cierra.**
4. Si los checks pasan, el juez compara el diff contra el SPEC: ¿los tests cubren lo pedido, o son triviales? Un juez que no contesta **no cuenta como aprobación**.
5. Queda `recibos/<id>/recibo.json` con chequeos, archivos tocados, veredicto y motivo.

"Listo" sin recibo verde no es listo.

## 6. Mergear e integrar

- `./slices mergear <id>` se niega sin `"cerrado": true`. `--forzar` existe y queda escrito en el commit.
- Después de integrar todos los slices: `code-review-en-loop` sobre el diff completo y `qa-con-video` si hay UI.
- El push y el MR los decide la persona (hook `gate-irreversible.sh`).

## 7. Higiene

- Revisá `git log --format=%B` de cada commit de un ejecutor: algunos CLIs agregan `Co-authored-by`. El hook git `commit-msg` lo saca solo.
- Cada error nuevo se convierte en regla escrita (en un script, en `AGENTS.md` o en un hook). Si se corrige a mano dos veces, se automatiza.
