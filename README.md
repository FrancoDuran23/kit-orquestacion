# kit-orquestacion

Skills, hooks y MCP para trabajar con varios agentes de IA a la vez sin perder el control: uno planifica, otros ejecutan, un juez verifica y **el código orquesta**. Funciona con Claude Code, Cursor (`cursor-agent`) y [Orca](https://github.com/stablyai/orca).

## El método en 6 reglas

1. **Partir antes de hacer.** Un ticket se divide en *slices*: pedazos chicos con dependencias claras (un DAG). Lo independiente corre en paralelo.
2. **Cada pedazo tiene un contrato (SPEC):** qué toca, qué no, qué tests lo prueban.
3. **No creerle al que hizo el trabajo.** Los tests se re-corren por fuera y queda un *recibo*. Sin recibo verde, no cierra.
4. **El que piensa no ejecuta y el que ejecuta no decide.** El modelo caro planifica, el rápido codifica, el chico hace lo fácil, el código orquesta.
5. **Review en loop** hasta que salga limpio.
6. **Frenar solo en lo irreversible.** Lo reversible avanza solo; push, merge y publicar pasan por una persona.

El detalle técnico está en [`skills/orquestar-slices/SKILL.md`](skills/orquestar-slices/SKILL.md).

## Orca + slices: lo mejor de cada uno

| Lo pone Orca | Lo pone slices |
|---|---|
| Workers supervisados, con interfaz | El SPEC como contrato |
| `ask` / `reply`: el worker pregunta en medio del trabajo | Re-correr los tests por fuera (no le cree al worker) |
| Heartbeats: sabe si un worker se colgó | El juez Jev: ¿los tests cubren lo que pedía el SPEC? |
| Gates para lo irreversible | Reintento con el motivo del rechazo |
| Rotación de cuentas (`orca account add`) | Merge solo con recibo verde |

```text
./slices lanzar X      → worktree + worker de Orca
worker_done            → ./slices verificar X   (checks + Jev)
  CIERRA               → ./slices mergear X
  NO CIERRA            → ./slices lanzar X      (el worker recibe el motivo y arregla eso)
```

**Para arrancar en un repo nuevo:** pedile al agente *"iniciar orquestación"*. Te pregunta qué suscripciones tenés, te recomienda quién planifica, quién ejecuta y quién juzga, y te guía hasta dejar Orca configurado y un slice de prueba andando.

## Qué trae

### Skills propias (en este repo)

| Skill | Para qué |
|---|---|
| `iniciar-orquestacion` | Entrevista: qué suscripciones tenés y para qué; recomienda el plan y guía la configuración de Orca paso a paso. |
| `orquestar-slices` | El método: roles, DAG, SPEC, Orca supervisa, slices verifica, Jev juzga, merge con recibo. |
| `code-review-en-loop` | `/code-review` → arreglar → repetir hasta limpio. |
| `qa-con-video` | Videos con Playwright en el issue (para QA) y en el MR/PR (para el revisor). |

### Skills de terceros (se bajan de su repo original, no se copian)

| Fuente | Qué aporta | Licencia |
|---|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | grilling, to-spec, to-tickets, tdd, implement, diagnosing-bugs, handoff, prototype y el resto (menos `code-review`, ver `fuentes.txt`) | MIT |
| [uxKero/kero-stack](https://github.com/uxKero/kero-stack) | kero-method, kero-orchestrate, kero-audit, kero-blind, kero-research, kero-scope, kero-system | MIT |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | impeccable: diseño y crítica de interfaces | Apache-2.0 |
| [vercel-labs/vgpu](https://github.com/vercel-labs/vgpu) | vgpu: WebGPU, shaders, escenas | MIT |
| [stablyai/orca](https://github.com/stablyai/orca) | orca-cli, orchestration, computer-use, orca-linear, orca-per-workspace-env… | MIT |

La lista vive en [`fuentes.txt`](fuentes.txt): agregar o sacar una fuente es una línea.

### Hooks

| Hook | Tipo | Qué hace |
|---|---|---|
| `sin-coautor.sh` | Claude Code `PreToolUse` | Niega commits/PRs/MRs con `Co-authored-by: Claude/Cursor` o "Generated with Claude Code". |
| `gate-irreversible.sh` | Claude Code `PreToolUse` | Pide confirmación antes de `git push`, merges remotos, `reset --hard`, `clean -f`, `branch -D`, `DROP`/`TRUNCATE`, `rm -r` sobre `/` o `~` y comentarios públicos en issues. |
| `tests-de-a-uno.sh` | Claude Code `PreToolUse` | Si ya corre otra suite de tests, espera. Varios agentes comparten la base de datos y la RAM: el código se paraleliza, los tests no. |
| `git-commit-msg` | git `commit-msg` | Saca la atribución de IA de **cualquier** commit, también los que hacen Cursor o Codex por fuera de Claude Code. |

### MCP

- **Playwright** (`@playwright/mcp`), para Claude Code y Cursor: navegar, probar y grabar la app.

### Orquestador

- [`bin/slices`](bin/slices): un solo script bash. Un worktree y una rama por slice, worker de Orca (o un proceso local desacoplado), verificación con recibo, reintento con el motivo y merge solo con recibo verde.
- [`bin/juez-jev`](bin/juez-jev): el juez. Una pregunta a Jev (TypeSafe System One) por cada test exigido del SPEC, más otra sobre si los tests son de relleno. Si Jev no responde, no cierra. La key va en `JEV_API_KEY` o en `~/.config/kit-orquestacion/jev.key`.

## Instalar

Requisitos: `git`, `jq`, `node`/`npx`. Opcionales: `claude`, `cursor-agent`, `orca`.

```bash
git clone https://github.com/FrancoDuran23/kit-orquestacion ~/kit-orquestacion
cd ~/kit-orquestacion

./install.sh --dry-run          # ver qué haría
./install.sh                    # global, para tu usuario
./install.sh --proyecto ~/mi-repo   # dentro de un repo, para que viaje con el equipo
```

- **Global:** skills en `~/.claude/skills` y `~/.cursor/skills` (las propias como symlink: `git pull` las actualiza), hooks en `~/.claude/settings.json` y Playwright en `claude mcp` y `~/.cursor/mcp.json`.
- **Proyecto:** todo dentro del repo (`.claude/`, `.mcp.json`, `.cursor/mcp.json`, `skills-lock.json`, `orca.yaml`, `.worktreeinclude`, `./slices`), más el hook `commit-msg` en `.git/hooks`.
- Nunca pisa nada: los JSON se fusionan y el original queda copiado en `~/.cache/kit-orquestacion/bak/`.
- Opciones: `--sin-terceros`, `--sin-mcp`. Agentes destino: `KIT_AGENTES="claude-code cursor codex" ./install.sh`.

## Cómo se configura en Orca

Orca no tiene un registro propio de skills: usa las del agente que lanza en cada worktree. Por eso alcanza con instalar el kit.

| Pieza | Dónde la lee Orca |
|---|---|
| Skills | `~/.claude/skills` (global) o `<repo>/.claude/skills` (proyecto). `orca skills installed` las lista y `orca skills share` las publica con un link. |
| Hooks | Los de Claude Code (`settings.json`) corren en cada agente que Orca lanza, al lado de los hooks propios de Orca. |
| MCP | `<repo>/.mcp.json`: cada agente lo levanta en su worktree. |
| Setup por worktree | `orca.yaml → scripts.setup` (dependencias, `.env`, base de pruebas por worktree). `.worktreeinclude` copia los archivos ignorados. |
| Orquestación nativa | `orca orchestration task-create / dispatch / worker-start / gate-create`. Es el mismo DAG que `./slices`, con UI. |

Lanzar un slice como worker de Orca:

```bash
orca worktree create --name 001-login --agent claude --setup run \
  --prompt "$(cat specs/001-login.spec.md)"
orca worktree ps        # estado de todos
```

## Día a día

```bash
./slices init                               # una vez por repo
./slices nuevo login "Login con clave"      # completar el SPEC y commitearlo
./slices lanzar 001-login 002-pagos         # en paralelo
./slices estado
./slices mergear 001-login                  # solo si el recibo cerró
# integrado todo → /code-review en loop → qa-con-video → MR (lo manda una persona)
```

## Licencia

MIT para lo propio. Las skills de terceros conservan la licencia de su repo: no se redistribuyen, se bajan del original.
