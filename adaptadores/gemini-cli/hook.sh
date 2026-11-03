#!/usr/bin/env bash
# Adaptador Gemini CLI, evento BeforeTool con matcher run_shell_command.
# Entrada: {"tool_input":{"command":"..."}} · Salida: {"decision":"deny","reason":"..."} o nada.
# "ask" no está documentado en Gemini CLI: lo irreversible se niega.
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cmd=$(jq -r '.tool_input.command // ""')
IFS=$'\t' read -r d m < <("$KIT/reglas/evaluar.sh" "$cmd")
[[ "$d" == allow ]] && exit 0
[[ "$d" == ask ]] && m="$m (pedile a la persona que lo corra)"
jq -n --arg m "$m" '{decision:"deny",reason:$m}'
