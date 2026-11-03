#!/usr/bin/env bash
# Regla: niega commits, PRs o MRs con atribución de IA (Claude, Cursor, Codex…).
# Contrato de las reglas: recibe el comando de shell en $1 e imprime una línea:
#   allow  |  ask<TAB>motivo  |  deny<TAB>motivo
cmd="${1-}"
if grep -qiE 'co-authored-by:[[:space:]]*(claude|cursor|codex)|generated with \[?claude code|cursoragent@cursor\.com|noreply@anthropic\.com' <<<"$cmd"; then
  printf 'deny\tAtribución de IA prohibida en commits, PRs y MRs. Sacá esa línea y volvé a intentar.\n'
else
  echo allow
fi
