# kit-orquestacion

Orquestar agentes de código sin perder el control: uno planifica, otros ejecutan, un juez verifica y **nadie se corrige a sí mismo**. Agnóstico al modelo: funciona con Claude Code, Cursor, Codex, Gemini CLI, Antigravity CLI y OpenCode, y se integra con [Orca](https://github.com/stablyai/orca).

## Instalar

```bash
git clone https://github.com/FrancoDuran23/kit-orquestacion ~/kit-orquestacion
cd ~/kit-orquestacion
./install.sh --dry-run                       # ver qué haría
./install.sh                                 # en los agentes que tengas instalados
./install.sh --agentes claude-code,cursor    # o elegilos
./install.sh --proyecto ~/mi-repo            # dentro de un repo, para que viaje con el equipo
./install.sh --con-engram                    # + memoria persistente (Engram)
```

Requisitos: `git`, `jq` y `node`/`npx`. Opcionales: `orca`, y una key de [TypeSafe](https://typesafe.ai) para el juez Jev.

**Solo Claude Code**, como plugin:

```
/plugin install kit-orquestacion --marketplace FrancoDuran23/kit-orquestacion
```

**Una vez por repo:** la skill **`configurar-orquestacion`** (en Claude Code: `/configurar-orquestacion`). Mira el repo, te pregunta qué suscripciones y agentes tenés, recomienda quién planifica, quién ejecuta y quién juzga, y deja todo andando con un slice de prueba.

**Con cada pedido:** la skill **`start`** (en Claude Code: `/start`). Inspirada en [ODD](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/intended-usage.md): explora antes de preguntar, hace grill solo si hay decisiones encadenadas que no puede tomar sola y elige la ruta (solo lectura, directo u orquestar). Si orquesta: `to-tickets` → `./slices dag` para revisar el grafo con vos → `./slices auto` → review, QA y MR.

## Cómo funciona

```text
ticket → partir en slices (SPEC + tests exigidos + dependencias)
./slices dag      ver las olas (qué corre en paralelo) y corregir antes de lanzar
./slices auto
  lanza cada slice como worker de Orca, en su worktree, cuando sus dependencias ya entraron
  worker_done → re-corre los tests por fuera + Jev compara los tests contra el SPEC
    CIERRA    → merge a la rama del ticket
    NO CIERRA → se relanza con el motivo; a los N intentos, lo ve una persona
review en loop → QA → push y MR (siempre una persona)
```

- [docs/metodo.md](docs/metodo.md): el método, para quien nunca orquestó.
- [docs/orca-y-slices.md](docs/orca-y-slices.md): qué pone Orca, qué pone slices, el loop y los modos.
- [docs/workshop.md](docs/workshop.md): guion de una hora para enseñarlo.

## Qué trae

| Pieza | Dónde | Qué es |
|---|---|---|
| Skills | [`skills/`](skills) | `configurar-orquestacion` (una vez por repo), `start` (cada pedido), `orquestar-slices` (con el mapa de qué skill usar en cada momento), `code-review-en-loop`, `qa-con-video`. Estándar Agent Skills. |
| Skills de terceros | [`skills-lock.json`](skills-lock.json) | [mattpocock](https://github.com/mattpocock/skills), [kero-stack](https://github.com/uxKero/kero-stack), [impeccable](https://github.com/pbakaus/impeccable), [vgpu](https://github.com/vercel-labs/vgpu) y [Orca](https://github.com/stablyai/orca). Se bajan de su repo original, no se copian. |
| Reglas | [`reglas/`](reglas) | Gates en lo irreversible (push, merge remoto, borrar datos, publicar), sin atribución de IA en commits, tests de a uno. Una sola lógica para todos los clientes. |
| Adaptadores | [`adaptadores/`](adaptadores) | Traducen las reglas al formato de hooks de cada cliente. |
| MCP | [`mcp/servidores.json`](mcp/servidores.json) | Playwright, definido una vez y escrito en el formato de cada cliente. |
| Orquestador | [`bin/slices`](bin/slices) | SPEC → worktree → worker (Orca o local) → verificación → reintento con el motivo → merge con recibo verde. `auto`, `semi` o `manual`. |
| Juez | [`bin/juez-jev`](bin/juez-jev) | Jev (TypeSafe) responde una pregunta por cada test exigido del SPEC, más otra sobre si los tests son de relleno. Si no responde, no cierra. |
| Hook de git | [`git-hooks/commit-msg`](git-hooks/commit-msg) | Saca la atribución de IA de cualquier commit, lo haga quien lo haga. |
| Plantillas | [`templates/`](templates) | `slices.conf` comentado, bloque de `AGENTS.md`, `orca.yaml`. |

### Qué hace cada cliente con las reglas

| Cliente | Hook | "Preguntar" |
|---|---|---|
| Claude Code | `PreToolUse` / Bash | ✅ pregunta |
| Antigravity CLI | `PreToolUse` / run_command | ✅ pregunta |
| Cursor | `preToolUse` / Shell | ❌ se niega con el motivo (lo corre una persona) |
| Codex | `PreToolUse` / Bash (aprobar con `/hooks`) | ❌ se niega con el motivo |
| Gemini CLI | `BeforeTool` / run_shell_command | ❌ se niega con el motivo |
| OpenCode | plugin `tool.execute.before` | ❌ se niega con el motivo |

## Licencia

MIT. Las skills de terceros mantienen la licencia de su repo.
