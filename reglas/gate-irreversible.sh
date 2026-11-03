#!/usr/bin/env bash
# Regla: lo reversible pasa solo; lo irreversible le pregunta a una persona.
# Contrato: comando en $1 → imprime allow | ask<TAB>motivo | deny<TAB>motivo
cmd="${1-}"
s='(^|[;&|[:space:]])'   # inicio de comando
m=""
if   grep -qE "${s}git[[:space:]]+push\b" <<<"$cmd"; then m="git push publica en el remoto"
elif grep -qE "${s}(gh[[:space:]]+pr|glab[[:space:]]+mr)[[:space:]]+merge\b" <<<"$cmd"; then m="mergea en el remoto"
elif grep -qE "${s}git[[:space:]]+reset[[:space:]]+--hard\b" <<<"$cmd"; then m="git reset --hard descarta trabajo"
elif grep -qE "${s}git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f" <<<"$cmd"; then m="git clean borra archivos sin trackear"
elif grep -qE "${s}git[[:space:]]+branch[[:space:]]+-D\b" <<<"$cmd"; then m="borra una rama sin mergear"
elif grep -qE "${s}rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f?[[:space:]]+(/|~|\\\$HOME)([[:space:]]|$)" <<<"$cmd"; then m="rm -r sobre / o el home"
elif grep -qiE '\b(drop[[:space:]]+(database|schema|table)|truncate[[:space:]]+table)\b' <<<"$cmd"; then m="borra datos de una base"
elif grep -qE "${s}(gh|glab)[[:space:]]+(issue|pr|mr)[[:space:]]+(comment|note|create)\b" <<<"$cmd"; then m="publica algo visible para el equipo"
fi
if [[ -n "$m" ]]; then printf 'ask\tGate: %s. Confirmá antes de seguir.\n' "$m"; else echo allow; fi
