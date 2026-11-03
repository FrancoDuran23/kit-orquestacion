#!/usr/bin/env bash
# install.sh — instala el kit de orquestación.
#
#   ./install.sh                      # global: skills, hooks y MCP para tu usuario
#   ./install.sh --proyecto <dir>     # dentro de un repo: viaja con el repo para todo el equipo
#
# Opciones:
#   --sin-terceros     no instala las skills de fuentes.txt ni las de Orca
#   --sin-mcp          no configura el MCP de Playwright
#   --dry-run          muestra lo que haría, sin tocar nada
#
# Variables:
#   KIT_AGENTES="claude-code cursor"  agentes destino de las skills (los de `npx skills`)
#
# Nunca pisa lo que ya existe: los settings y los .mcp.json se fusionan (con copia
# en ~/.cache/kit-orquestacion/bak), y un hook git commit-msg ajeno se respeta.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROYECTO="" TERCEROS=1 MCP=1 DRY=""
AGENTES="${KIT_AGENTES:-claude-code cursor}"
PROPIAS=(iniciar-orquestacion orquestar-slices code-review-en-loop qa-con-video)
HOOKS_BASH=(sin-coautor.sh gate-irreversible.sh tests-de-a-uno.sh)
MCP_PLAYWRIGHT='{"command":"npx","args":["-y","@playwright/mcp@latest"]}'

while (( $# )); do
  case "$1" in
    --proyecto) PROYECTO="$(cd "${2:?falta el directorio}" && pwd)"; shift ;;
    --sin-terceros) TERCEROS="" ;;
    --sin-mcp) MCP="" ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n 2,17p "$0"; exit 0 ;;
    *) echo "opción desconocida: $1" >&2; exit 2 ;;
  esac
  shift
done

paso() { printf '\n\033[1m── %s\033[0m\n' "$*"; }
run() { if [[ -n "$DRY" ]]; then echo "[dry-run] $*"; else "$@"; fi; }
necesita() { command -v "$1" >/dev/null || { echo "falta '$1': instalalo y volvé a correr" >&2; exit 2; }; }
necesita git; necesita jq
[[ -z "$TERCEROS" ]] || necesita npx

# Fusiona JSON en un archivo existente (o lo crea), con copia en ~/.cache/kit-orquestacion/bak.
fusionar_json() {  # <archivo> <programa jq> [args jq…]
  local f="$1" prog="$2"; shift 2
  [[ -n "$DRY" ]] && { echo "[dry-run] fusionar en $f"; return; }
  mkdir -p "$(dirname "$f")"
  if [[ -s "$f" ]]; then  # copia de seguridad fuera del repo, para no ensuciarlo
    local bak="${XDG_CACHE_HOME:-$HOME/.cache}/kit-orquestacion/bak/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$bak"; cp "$f" "$bak/$(tr '/' '_' <<<"${f#/}")"
  else echo '{}' > "$f"; fi
  local tmp; tmp="$(mktemp)"
  jq "$@" "$prog" "$f" > "$tmp" && mv "$tmp" "$f"
}

# Agrega cada hook a PreToolUse/Bash si ese comando no está ya.
registrar_hooks() {  # <settings.json> <prefijo de ruta>
  local f="$1" pre="$2" nuevos="[]" h timeout
  for h in "${HOOKS_BASH[@]}"; do
    timeout=10; [[ "$h" == tests-de-a-uno.sh ]] && timeout=600
    nuevos=$(jq -c --arg c "$pre/$h" --argjson t "$timeout" '. + [{type:"command",command:$c,timeout:$t}]' <<<"$nuevos")
  done
  fusionar_json "$f" '
    .hooks //= {} | .hooks.PreToolUse //= [] |
    reduce $nuevos[] as $h (.;
      if ([.hooks.PreToolUse[].hooks[]?.command] | index($h.command)) then .
      else .hooks.PreToolUse += [{matcher:"Bash", hooks:[$h]}] end)' --argjson nuevos "$nuevos"
}

agregar_mcp() {  # <archivo .mcp.json / mcp.json>
  fusionar_json "$1" '.mcpServers //= {} | .mcpServers.playwright //= $s' --argjson s "$MCP_PLAYWRIGHT"
}

# Skills de un repo, con "*" y exclusiones resueltas sobre un clon liviano.
skills_de() {  # <repo> <lista|*> <excluir>
  local repo="$1" lista="$2" excl="${3:-}"
  if [[ "$lista" != "*" ]]; then tr ',' '\n' <<<"$lista"; return; fi
  local tmp; tmp="$(mktemp -d)"
  git clone -q --depth 1 "https://github.com/$repo.git" "$tmp/r"
  find "$tmp/r" -name SKILL.md -not -path '*/.*/*' -not -path '*/node_modules/*' -not -path '*/tests/*' \
    -exec awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f&&/^name:/{sub(/^name:[ \t]*/,"");print}' {} \; \
    | tr -d '"'"'" | sort -u \
    | grep -vxF -f <(tr ',' '\n' <<<"$excl" | sed '/^$/d') || true
  rm -rf "$tmp"
}

instalar_terceros() {
  local alcance=(-g); [[ -n "$PROYECTO" ]] && alcance=()
  local ag=(); for a in $AGENTES; do ag+=(-a "$a"); done
  local repo lista excl
  while read -r repo lista excl; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    local sk=(); while read -r s; do [[ -n "$s" ]] && sk+=(-s "$s"); done < <(skills_de "$repo" "$lista" "$excl")
    echo "· $repo: $(( ${#sk[@]} / 2 )) skills"
    (cd "${PROYECTO:-$HOME}" && run npx --yes skills add "$repo" "${sk[@]}" "${alcance[@]}" "${ag[@]}" -y)
  done < "$KIT/fuentes.txt"

  echo "· Orca"
  if command -v orca >/dev/null; then
    local local_=(); [[ -n "$PROYECTO" ]] && local_=(--local)
    (cd "${PROYECTO:-$HOME}" && run orca skills install --all "${local_[@]}")
  else
    (cd "${PROYECTO:-$HOME}" && run npx --yes skills add stablyai/orca -s '*' "${alcance[@]}" "${ag[@]}" -y)
  fi
}

copiar() {  # <origen> <destino>
  if [[ -e "$2" ]]; then echo "  ya existe, no se pisa: $2"; return; fi
  run mkdir -p "$(dirname "$2")"; run cp -r "$1" "$2"; echo "  + $2"
}

# ── global ──────────────────────────────────────────────────────────────────
if [[ -z "$PROYECTO" ]]; then
  [[ -n "$TERCEROS" ]] && { paso "Skills de terceros (globales)"; instalar_terceros; }

  paso "Skills propias → ~/.claude/skills (symlink: se actualizan con git pull)"
  for s in "${PROPIAS[@]}"; do
    if [[ -e "$HOME/.claude/skills/$s" ]]; then echo "  ya existe: ~/.claude/skills/$s"
    else run mkdir -p "$HOME/.claude/skills"; run ln -s "$KIT/skills/$s" "$HOME/.claude/skills/$s"; echo "  + $s"; fi
  done

  paso "Hooks de Claude Code → ~/.claude/settings.json"
  registrar_hooks "$HOME/.claude/settings.json" "$KIT/hooks"
  run chmod +x "$KIT/hooks/"*.sh "$KIT/hooks/git-commit-msg" "$KIT/bin/slices" "$KIT/bin/juez-jev"

  if [[ -n "$MCP" ]]; then
    paso "MCP de Playwright (Claude Code y Cursor)"
    if command -v claude >/dev/null && ! claude mcp get playwright >/dev/null 2>&1; then
      run claude mcp add -s user playwright -- npx -y @playwright/mcp@latest
    else echo "  Claude Code: ya estaba o no hay CLI"; fi
    agregar_mcp "$HOME/.cursor/mcp.json"
  fi

  paso "Listo"
  cat <<EOF
  · slices y juez-jev:  ln -s $KIT/bin/slices $KIT/bin/juez-jev ~/.local/bin/   (o copialos a cada repo)
  · para configurar un repo de punta a punta, pedile al agente: "iniciar orquestación"
  · en un repo, para que viaje con el equipo:  $KIT/install.sh --proyecto <repo>
EOF
  exit 0
fi

# ── proyecto ────────────────────────────────────────────────────────────────
git -C "$PROYECTO" rev-parse --git-dir >/dev/null 2>&1 || { echo "$PROYECTO no es un repo git" >&2; exit 2; }

[[ -n "$TERCEROS" ]] && { paso "Skills de terceros (en el proyecto, quedan en skills-lock.json)"; instalar_terceros; }

paso "Skills propias → .claude/skills"
for s in "${PROPIAS[@]}"; do copiar "$KIT/skills/$s" "$PROYECTO/.claude/skills/$s"; done

paso "Hooks de Claude Code → .claude/hooks + .claude/settings.json"
for h in "${HOOKS_BASH[@]}"; do copiar "$KIT/hooks/$h" "$PROYECTO/.claude/hooks/$h"; done
registrar_hooks "$PROYECTO/.claude/settings.json" '"$CLAUDE_PROJECT_DIR"/.claude/hooks'

paso "Hook git commit-msg (lo comparten todos los worktrees)"
gitdir="$(git -C "$PROYECTO" rev-parse --path-format=absolute --git-common-dir)"
copiar "$KIT/hooks/git-commit-msg" "$gitdir/hooks/commit-msg"
run chmod +x "$gitdir/hooks/commit-msg"

if [[ -n "$MCP" ]]; then
  paso "MCP de Playwright → .mcp.json y .cursor/mcp.json"
  agregar_mcp "$PROYECTO/.mcp.json"
  agregar_mcp "$PROYECTO/.cursor/mcp.json"
fi

paso "Orquestación: slices + Orca"
copiar "$KIT/bin/slices" "$PROYECTO/slices"
copiar "$KIT/bin/juez-jev" "$PROYECTO/juez-jev"
copiar "$KIT/plantillas/orca.yaml" "$PROYECTO/orca.yaml"
copiar "$KIT/plantillas/worktreeinclude" "$PROYECTO/.worktreeinclude"

paso "Listo"
cat <<EOF
  Siguiente, en $PROYECTO:
  1. ./slices init              (crea slices.conf y AGENTS.md; revisá CHECKS, LANZADOR y JUEZ)
  2. Editá orca.yaml → scripts.setup con lo que necesita cada worktree
  3. git add .claude .mcp.json .cursor orca.yaml .worktreeinclude slices juez-jev skills-lock.json && git commit
     (el hook commit-msg vive en .git/hooks: cada persona corre este install una vez)
EOF
