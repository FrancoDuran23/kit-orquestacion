#!/usr/bin/env bash
# install.sh — instala el kit de orquestación para los agentes que uses.
#
#   ./install.sh                                   # para tu usuario, en los agentes que tengas instalados
#   ./install.sh --agentes claude-code,cursor      # elegís los agentes
#   ./install.sh --proyecto <repo>                 # dentro de un repo: viaja con el repo
#
# Agentes: claude-code cursor codex gemini-cli antigravity-cli opencode
#
# Opciones:
#   --con-engram     instala Engram (memoria persistente) y lo configura en cada agente
#   --sin-terceros   no instala las skills de skills-lock.json
#   --sin-hooks      no instala las reglas (gates, sin coautor, tests de a uno)
#   --sin-mcp        no configura el MCP de Playwright
#   --dry-run        muestra lo que haría, sin tocar nada
#
# Nunca pisa lo que ya existe: los JSON se fusionan (con copia en
# ~/.cache/kit-orquestacion/bak), las skills con el mismo nombre se respetan y un
# hook git commit-msg ajeno no se reemplaza.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOPORTADOS=(claude-code cursor codex gemini-cli antigravity-cli opencode)
PROYECTO="" AGENTES_ARG="" TERCEROS=1 HOOKS=1 MCP=1 ENGRAM="" DRY=""

while (( $# )); do
  case "$1" in
    --proyecto) PROYECTO="$(cd "${2:?falta el directorio}" && pwd)"; shift ;;
    --agentes) AGENTES_ARG="${2:?falta la lista}"; shift ;;
    --con-engram) ENGRAM=1 ;;
    --sin-terceros) TERCEROS="" ;;
    --sin-hooks) HOOKS="" ;;
    --sin-mcp) MCP="" ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n 2,19p "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "opción desconocida: $1" >&2; exit 2 ;;
  esac
  shift
done

paso() { printf '\n\033[1m── %s\033[0m\n' "$*"; }
run() { if [[ -n "$DRY" ]]; then echo "  [dry-run] $*"; else "$@"; fi; }
nota() { echo "  · $*"; }
necesita() { command -v "$1" >/dev/null || { echo "falta '$1': instalalo y volvé a correr" >&2; exit 2; }; }
necesita git; necesita jq; necesita npx

# ── qué agentes ─────────────────────────────────────────────────────────────
binario_de() {
  case "$1" in
    claude-code) echo claude ;; cursor) echo cursor-agent ;; codex) echo codex ;;
    gemini-cli) echo gemini ;; antigravity-cli) echo agy ;; opencode) echo opencode ;;
  esac
}
AGENTES=()
if [[ -n "$AGENTES_ARG" ]]; then
  IFS=',' read -r -a AGENTES <<<"$AGENTES_ARG"
  for a in "${AGENTES[@]}"; do
    [[ " ${SOPORTADOS[*]} " == *" $a "* ]] || { echo "agente desconocido: $a (soportados: ${SOPORTADOS[*]})" >&2; exit 2; }
  done
else
  for a in "${SOPORTADOS[@]}"; do
    if command -v "$(binario_de "$a")" >/dev/null || { [[ "$a" == cursor ]] && command -v agent >/dev/null; }; then AGENTES+=("$a"); fi
  done
  (( ${#AGENTES[@]} )) || { echo "no encontré ningún agente instalado; usá --agentes" >&2; exit 2; }
fi
tiene() { [[ " ${AGENTES[*]} " == *" $1 "* ]]; }
echo "kit-orquestacion → ${AGENTES[*]}${PROYECTO:+ (proyecto: $PROYECTO)}"

# ── utilidades ──────────────────────────────────────────────────────────────
BAK="${XDG_CACHE_HOME:-$HOME/.cache}/kit-orquestacion/bak/$(date +%Y%m%d-%H%M%S)"
respaldar() { if [[ -s "$1" ]]; then mkdir -p "$BAK"; cp "$1" "$BAK/$(tr '/' '_' <<<"${1#/}")"; fi; }

fusionar_json() {  # <archivo> <programa jq> [args jq…]
  local f="$1" prog="$2"; shift 2
  if [[ -n "$DRY" ]]; then echo "  [dry-run] fusionar en $f"; return; fi
  mkdir -p "$(dirname "$f")"
  if [[ -s "$f" ]]; then respaldar "$f"; else echo '{}' > "$f"; fi
  local tmp; tmp="$(mktemp)"
  jq "$@" "$prog" "$f" > "$tmp" && mv "$tmp" "$f"
  nota "$f"
}

copiar() {  # <origen> <destino>: no pisa
  if [[ -e "$2" ]]; then nota "ya existe, no se pisa: $2"; return; fi
  run mkdir -p "$(dirname "$2")"; run cp -r "$1" "$2"; nota "+ $2"
}

# Archivo de config según el modo: <relativo al proyecto> <absoluto de usuario>
donde() { if [[ -n "$PROYECTO" ]]; then echo "$PROYECTO/$1"; else echo "$2"; fi; }

ALCANCE=(-g); [[ -n "$PROYECTO" ]] && ALCANCE=()
DESTINO="${PROYECTO:-$HOME}"

# ¿ya hay una skill con este nombre? (no se pisa)
skill_existe() {
  local n="$1" d base="${PROYECTO:-$HOME}"
  for d in .agents/skills .claude/skills .cursor/skills .gemini/skills .config/opencode/skills; do
    [[ -e "$base/$d/$n" ]] && return 0
  done
  return 1
}

skills_add() {  # <fuente> <agentes separados por espacio> <skills…>
  local fuente="$1" ags="$2"; shift 2
  (( $# )) || return 0
  [[ -n "${ags// /}" ]] || return 0
  local a=() s=() x
  for x in $ags; do a+=(-a "$x"); done
  for x in "$@"; do s+=(-s "$x"); done
  if [[ -n "$DRY" ]]; then echo "  [dry-run] npx skills add $fuente ${s[*]} ${ALCANCE[*]} ${a[*]}"; return; fi
  (cd "$DESTINO" && NPM_CONFIG_UPDATE_NOTIFIER=false npx --yes skills add "$fuente" "${s[@]}" "${ALCANCE[@]}" "${a[@]}" -y >/dev/null)
  nota "$fuente: $*"
}

# ── 1. skills propias ───────────────────────────────────────────────────────
paso "Skills del kit"
mapfile -t propias < <(ls "$KIT/skills")
skills_add "$KIT" "${AGENTES[*]}" "${propias[@]}"

# ── 2. skills de terceros (skills-lock.json) ────────────────────────────────
if [[ -n "$TERCEROS" ]]; then
  paso "Skills de terceros (skills-lock.json)"
  # code-review solo donde el cliente no trae uno propio (Claude Code tiene /code-review).
  ags_sin_review="${AGENTES[*]/claude-code/}"
  while read -r fuente; do
    [[ "$fuente" == stablyai/orca ]] && command -v orca >/dev/null && continue   # Orca: versión exacta, abajo
    nuevas=(); review=()
    while read -r n; do
      if skill_existe "$n"; then nota "ya existe, no se pisa: $n"; continue; fi
      if [[ "$n" == code-review ]]; then review+=("$n"); else nuevas+=("$n"); fi
    done < <(jq -r --arg f "$fuente" '.skills | to_entries[] | select(.value.source == $f) | .key' "$KIT/skills-lock.json")
    skills_add "$fuente" "${AGENTES[*]}" ${nuevas[@]+"${nuevas[@]}"}
    skills_add "$fuente" "$ags_sin_review" ${review[@]+"${review[@]}"}
  done < <(jq -r '[.skills[].source] | unique[]' "$KIT/skills-lock.json")
  if command -v orca >/dev/null; then
    loc=(); [[ -n "$PROYECTO" ]] && loc=(--local)
    (cd "$DESTINO" && run orca skills install --all --agent "$(IFS=,; echo "${AGENTES[*]}")" ${loc[@]+"${loc[@]}"} >/dev/null)
    nota "Orca: la versión de las skills que corresponde a tu Orca"
  fi
fi

# ── 3. reglas (hooks) ───────────────────────────────────────────────────────
if [[ -n "$HOOKS" ]]; then
  paso "Reglas: gates en lo irreversible, sin coautor de IA, tests de a uno"
  run chmod +x "$KIT"/reglas/*.sh "$KIT"/adaptadores/*/hook.sh "$KIT/git-hooks/commit-msg" "$KIT"/bin/*
  BASEK=".agents/kit"
  if [[ -n "$PROYECTO" ]]; then
    # Las reglas viajan con el repo, así no dependen de dónde clonó cada uno el kit.
    for d in reglas adaptadores; do
      if [[ -n "$DRY" ]]; then echo "  [dry-run] copiar $d → $PROYECTO/$BASEK/$d"
      else mkdir -p "$PROYECTO/$BASEK"; rm -rf "${PROYECTO:?}/$BASEK/$d"; cp -r "$KIT/$d" "$PROYECTO/$BASEK/$d"; fi
    done
    nota "$PROYECTO/$BASEK (reglas + adaptadores)"
  fi
  # Comando del hook para cada agente, según el modo.
  hook_cmd() {
    local a="$1"
    if [[ -z "$PROYECTO" ]]; then echo "$KIT/adaptadores/$a/hook.sh"; return; fi
    case "$a" in
      claude-code)     echo "\"\$CLAUDE_PROJECT_DIR\"/$BASEK/adaptadores/claude-code/hook.sh" ;;
      cursor)          echo "$BASEK/adaptadores/cursor/hook.sh" ;;                       # corre desde la raíz del repo
      codex)           echo "\"\$(git rev-parse --show-toplevel)\"/$BASEK/adaptadores/codex/hook.sh" ;;
      gemini-cli)      echo "\$GEMINI_PROJECT_DIR/$BASEK/adaptadores/gemini-cli/hook.sh" ;;
      antigravity-cli) echo "./$BASEK/adaptadores/antigravity-cli/hook.sh" ;;
    esac
  }

  if tiene claude-code; then
    fusionar_json "$(donde .claude/settings.json "$HOME/.claude/settings.json")" '.hooks //= {} | .hooks.PreToolUse //= [] |
      if ([.hooks.PreToolUse[].hooks[]?.command] | index($c)) then . else
      .hooks.PreToolUse += [{matcher:"Bash", hooks:[{type:"command", command:$c, timeout:600}]}] end' --arg c "$(hook_cmd claude-code)"
  fi
  if tiene cursor; then
    fusionar_json "$(donde .cursor/hooks.json "$HOME/.cursor/hooks.json")" '.version //= 1 | .hooks //= {} | .hooks.preToolUse //= [] |
      if ([.hooks.preToolUse[].command] | index($c)) then . else
      .hooks.preToolUse += [{command:$c, matcher:"Shell", timeout:600}] end' --arg c "$(hook_cmd cursor)"
  fi
  if tiene codex; then
    fusionar_json "$(donde .codex/hooks.json "$HOME/.codex/hooks.json")" '.hooks //= {} | .hooks.PreToolUse //= [] |
      if ([.hooks.PreToolUse[].hooks[]?.command] | index($c)) then . else
      .hooks.PreToolUse += [{matcher:"^Bash$", hooks:[{type:"command", command:$c, timeout:600}]}] end' --arg c "$(hook_cmd codex)"
    nota "Codex pide aprobar cada hook nuevo: abrí codex y corré /hooks"
  fi
  if tiene gemini-cli; then
    fusionar_json "$(donde .gemini/settings.json "$HOME/.gemini/settings.json")" '.hooks //= {} | .hooks.BeforeTool //= [] |
      (if ([.hooks.BeforeTool[].hooks[]?.command] | index($c)) then . else
      .hooks.BeforeTool += [{matcher:"run_shell_command", hooks:[{name:"kit-orquestacion", type:"command", command:$c, timeout:600000}]}] end)
      | .context //= {} | .context.fileName = (((.context.fileName // ["GEMINI.md"]) | if type == "string" then [.] else . end) + ["AGENTS.md"] | unique)' \
      --arg c "$(hook_cmd gemini-cli)"
  fi
  if tiene antigravity-cli; then
    fusionar_json "$(donde .agents/hooks.json "$HOME/.gemini/config/hooks.json")" \
      '."kit-orquestacion" = {PreToolUse:[{matcher:"run_command", hooks:[{command:$c, timeout:600}]}]}' --arg c "$(hook_cmd antigravity-cli)"
  fi
  if tiene opencode; then
    f="$(donde .opencode/plugins/kit-orquestacion.js "$HOME/.config/opencode/plugins/kit-orquestacion.js")"
    k="$KIT"; [[ -n "$PROYECTO" ]] && k="./$BASEK"
    if [[ -n "$DRY" ]]; then echo "  [dry-run] plugin → $f"
    else mkdir -p "$(dirname "$f")"; sed "s#__KIT__#$k#" "$KIT/adaptadores/opencode/kit-orquestacion.js" > "$f"; nota "$f"; fi
  fi
fi

# ── 4. MCP (mcp/servidores.json) ────────────────────────────────────────────
if [[ -n "$MCP" ]]; then
  paso "MCP: $(jq -r '.mcpServers | keys | join(", ")' "$KIT/mcp/servidores.json")"
  S=$(jq -c '.mcpServers' "$KIT/mcp/servidores.json")
  if tiene claude-code; then
    if [[ -n "$PROYECTO" ]]; then
      fusionar_json "$PROYECTO/.mcp.json" '.mcpServers = ((.mcpServers // {}) * $s)' --argjson s "$S"
    elif command -v claude >/dev/null; then
      while read -r n; do
        if claude mcp get "$n" >/dev/null 2>&1; then nota "Claude Code: $n ya estaba"; continue; fi
        run claude mcp add-json -s user "$n" "$(jq -c --arg n "$n" '.[$n]' <<<"$S")" >/dev/null; nota "Claude Code: $n"
      done < <(jq -r 'keys[]' <<<"$S")
    fi
  fi
  if tiene cursor; then
    fusionar_json "$(donde .cursor/mcp.json "$HOME/.cursor/mcp.json")" \
      '.mcpServers = ((.mcpServers // {}) * ($s | map_values({type:"stdio"} + .)))' --argjson s "$S"
  fi
  if tiene gemini-cli; then
    fusionar_json "$(donde .gemini/settings.json "$HOME/.gemini/settings.json")" '.mcpServers = ((.mcpServers // {}) * $s)' --argjson s "$S"
  fi
  if tiene antigravity-cli; then
    fusionar_json "$(donde .agents/mcp_config.json "$HOME/.gemini/config/mcp_config.json")" '.mcpServers = ((.mcpServers // {}) * $s)' --argjson s "$S"
  fi
  if tiene opencode; then
    fusionar_json "$(donde opencode.json "$HOME/.config/opencode/opencode.json")" \
      '."$schema" //= "https://opencode.ai/config.json" | .mcp = ((.mcp // {}) * ($s | map_values({type:"local", command:([.command] + (.args // [])), enabled:true})))' --argjson s "$S"
  fi
  if tiene codex; then
    f="$(donde .codex/config.toml "$HOME/.codex/config.toml")"
    while read -r n; do
      if grep -qs "^\[mcp_servers\.$n\]" "$f"; then nota "Codex: $n ya estaba"; continue; fi
      bloque=$(jq -r --arg n "$n" '.[$n] | "\n[mcp_servers.\($n)]\ncommand = \(.command | @json)\nargs = \(.args // [] | @json)"' <<<"$S")
      if [[ -n "$DRY" ]]; then echo "  [dry-run] agregar [mcp_servers.$n] a $f"
      else mkdir -p "$(dirname "$f")"; respaldar "$f"; printf '%s\n' "$bloque" >> "$f"; nota "$f: $n"; fi
    done < <(jq -r 'keys[]' <<<"$S")
  fi
fi

# ── 5. orquestador: slices + juez-jev ───────────────────────────────────────
paso "Orquestador: slices + juez-jev"
if [[ -n "$PROYECTO" ]]; then
  copiar "$KIT/bin/slices" "$PROYECTO/slices"
  copiar "$KIT/bin/juez-jev" "$PROYECTO/juez-jev"
  gitdir="$(git -C "$PROYECTO" rev-parse --path-format=absolute --git-common-dir)"
  copiar "$KIT/git-hooks/commit-msg" "$gitdir/hooks/commit-msg"
  run chmod +x "$gitdir/hooks/commit-msg"
  if ! grep -qs 'kit-orquestacion' "$PROYECTO/AGENTS.md"; then
    if [[ -n "$DRY" ]]; then echo "  [dry-run] agregar las reglas de slices a AGENTS.md"
    else printf '\n' >> "$PROYECTO/AGENTS.md"; cat "$KIT/templates/AGENTS.md" >> "$PROYECTO/AGENTS.md"; nota "AGENTS.md: reglas de slices"; fi
  fi
else
  run mkdir -p "$HOME/.local/bin"
  for b in slices juez-jev; do
    if [[ -e "$HOME/.local/bin/$b" ]]; then nota "ya existe: ~/.local/bin/$b"
    else run ln -s "$KIT/bin/$b" "$HOME/.local/bin/$b"; nota "~/.local/bin/$b"; fi
  done
  nota "el hook de git (sin coautor) se instala por repo: ./install.sh --proyecto <repo>"
fi

# ── 6. Engram (opcional) ────────────────────────────────────────────────────
if [[ -n "$ENGRAM" ]]; then
  paso "Engram: memoria persistente"
  if ! command -v engram >/dev/null; then
    if command -v brew >/dev/null; then run brew install gentleman-programming/tap/engram
    else
      os=$(uname -s | tr '[:upper:]' '[:lower:]'); arch=$(uname -m)
      [[ "$arch" == x86_64 ]] && arch=amd64; [[ "$arch" == aarch64 ]] && arch=arm64
      tag=$(curl -fsSL https://api.github.com/repos/Gentleman-Programming/engram/releases/latest | jq -r .tag_name)
      v="${tag#v}"; tgz="engram_${v}_${os}_${arch}.tar.gz"
      url="https://github.com/Gentleman-Programming/engram/releases/download/$tag"
      if [[ -n "$DRY" ]]; then echo "  [dry-run] bajar $tgz ($tag), verificar el checksum e instalar en ~/.local/bin"
      else
        t=$(mktemp -d)
        curl -fsSL -o "$t/$tgz" "$url/$tgz"; curl -fsSL -o "$t/checksums.txt" "$url/checksums.txt"
        (cd "$t" && grep " $tgz\$" checksums.txt | sha256sum -c --quiet) || { echo "checksum de engram inválido" >&2; exit 2; }
        tar -xzf "$t/$tgz" -C "$t"; mkdir -p "$HOME/.local/bin"; install -m 755 "$t/engram" "$HOME/.local/bin/engram"; rm -rf "$t"
        nota "engram $tag en ~/.local/bin"
      fi
    fi
  else
    nota "engram ya estaba: $(engram version 2>/dev/null | head -1)"
  fi
  for a in "${AGENTES[@]}"; do run engram setup "$a" >/dev/null && nota "engram setup $a"; done
fi

paso "Listo"
if [[ -n "$PROYECTO" ]]; then
  cat <<EOF
  Siguiente, en $PROYECTO:
  1. ./slices init   (slices.conf: revisá CHECKS, LANZADOR, AGENTE_ORCA, JUEZ y MODO)
  2. Commitealo si la config viaja con el repo; si no, agregalo a .git/info/exclude.
  3. Abrí tu agente una vez en la raíz del repo y aceptá la confianza de la carpeta.
EOF
else
  cat <<EOF
  · Para configurar un repo de punta a punta: abrí tu agente ahí y usá la skill iniciar-orquestacion.
  · Reiniciá los agentes para que tomen hooks, MCP y skills nuevos.
EOF
fi
