#!/usr/bin/env bash
# Adaptador Antigravity CLI (agy), evento PreToolUse con matcher run_command.
# Entrada: {"toolCall":{"args":{"CommandLine":"..."}}} · Salida: {"decision":"allow"|"deny"|"ask","reason":"..."}
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cmd=$(jq -r '.toolCall.args.CommandLine // .tool_input.command // ""')
IFS=$'\t' read -r d m < <("$KIT/reglas/evaluar.sh" "$cmd")
if [[ "$d" == allow ]]; then echo '{"decision":"allow"}'; exit 0; fi
jq -n --arg d "$d" --arg m "$m" '{decision:$d,reason:$m}'
