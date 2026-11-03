#!/usr/bin/env bash
# Adaptador Cursor (IDE y CLI), evento preToolUse con matcher "Shell".
# Entrada: {"tool_input":{"command":"..."}} · Salida: {"permission":"allow"|"deny",...}
# Cursor siempre necesita JSON (vacío o inválido = bloquea). En preToolUse no aplica "ask":
# lo irreversible se niega con el motivo, para que lo corra una persona.
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cmd=$(jq -r '.tool_input.command // .command // ""')
IFS=$'\t' read -r d m < <("$KIT/reglas/evaluar.sh" "$cmd")
if [[ "$d" == allow ]]; then echo '{"permission":"allow"}'; exit 0; fi
[[ "$d" == ask ]] && m="$m (en Cursor no se puede preguntar acá: pedile a la persona que lo corra)"
jq -n --arg m "$m" '{permission:"deny",user_message:$m,agent_message:$m}'
