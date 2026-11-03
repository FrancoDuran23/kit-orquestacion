# Orca + slices

## Cómo se hace normalmente en Orca

1. Un `orca.yaml` en el repo con el setup de cada worktree:
   ```yaml
   scripts:
     setup: |
       uv sync
       cp "$ORCA_ROOT_PATH/.env" .
   setupAgentStartupPolicy: wait-for-setup
   ```
2. `orca orchestration worker-start --spec "<tarea>" --agent cursor`
3. Orca crea el worktree, corre el setup y lanza el agente.
4. El agente termina y avisa `worker_done --outcome succeeded`. **Orca le cree** y la tarea queda cerrada.

El hueco está en el paso 4: nadie comprueba lo que dice el agente.

## Lo que suma slices

| | Orca solo | Orca + slices |
|---|---|---|
| Crea el worktree | Orca | slices (necesita la rama para verificar y mergear) |
| Setup del worktree | `orca.yaml` | `PREPARAR` en `slices.conf` |
| Lanza y supervisa al agente | Orca | Orca |
| El worker pregunta en medio del trabajo | `ask` / `reply` | igual |
| ¿Terminó bien? | lo dice el agente | lo prueban los tests + Jev |
| Si no cerró | a mano | se relanza con el motivo y el veredicto del juez |
| Merge | a mano | solo con recibo verde |

En una frase, para el workshop:

> Orca es el capataz que reparte y vigila. Lo que no hace es inspeccionar la obra: si el obrero dice "terminé", le cree. Sumamos un inspector (slices + Jev) que vuelve a medir antes de aceptar. Para eso el inspector prepara él mismo el terreno: por eso el setup está en slices y no en `orca.yaml`.

## El loop

```text
./slices auto
  lanza los slices cuyas dependencias ya entraron
  espera el worker_done de Orca
    → verifica: re-corre CHECKS + Jev compara tests contra el SPEC
    → CIERRA:    mergea a la rama del ticket y lanza lo que se desbloqueó
    → NO CIERRA: relanza con el motivo (hasta MAX_INTENTOS); después escala
    → el worker pregunta / hay conflicto de merge: frena y avisa
  termina cuando entraron todos → review en loop, QA, push y MR (personas)
```

## Modos

| `MODO` | Qué hace solo | Cuándo |
|---|---|---|
| `auto` | todo hasta mergear a la rama del ticket | cuidar cuota o velocidad |
| `semi` | todo, pero frena antes de cada merge para revisar el diff | cuidar calidad |
| `manual` | nada: `lanzar`, `verificar`, `mergear` a mano | aprender, depurar |

Push y MR nunca son automáticos.

## Problemas conocidos

- **`agent_readiness: timeout` al lanzar.** El agente quedó frenado en el diálogo "¿confiás en esta carpeta?". La persona abre el agente una vez en la raíz del repo y acepta; los worktrees de `.slices/` heredan la confianza.
- **`release_unknown` al liberar un worker.** Orca cerró la terminal pero no pudo confirmar que el proceso terminó. Verificá que no quede el proceso y seguí.
- **En Orca, `grok` es el CLI de xAI**, que requiere su propia suscripción. Grok vía Cursor es `AGENTE_ORCA="cursor"` con `MODELO="cursor-grok-4.6-high"`.
