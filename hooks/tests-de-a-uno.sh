#!/usr/bin/env bash
# PreToolUse (Bash): si el comando corre una suite de tests y ya hay otra corriendo,
# espera a que termine. Con varios agentes en paralelo la base de datos y la RAM son
# compartidas: el código se paraleliza, los tests no.
#
# Patrones vigilados (ampliables con KIT_TESTS_PATRON, regex extendida):
patron="${KIT_TESTS_PATRON:-(^|[;&|[:space:]])((uv run |poetry run )?python[0-9.]* -m pytest|pytest|manage\.py test|npm (run )?test|pnpm (run )?test|cargo test|go test)\b}"
espera_max="${KIT_TESTS_ESPERA:-540}"   # segundos; el hook tiene timeout 600

set -uo pipefail
cmd=$(jq -r '.tool_input.command // ""')
grep -qE "$patron" <<<"$cmd" || exit 0

# Ancla en el binario: un `pgrep -f "pytest"` suelto se encuentra a sí mismo y a
# cualquier agente cuyo prompt mencione pytest, y espera para siempre.
otra_suite() {
  pgrep -f '^[^ ]*python[0-9.]* (-[^ ]+ )*-m pytest( |$)' >/dev/null && return 0
  pgrep -f '^[^ ]*python[0-9.]* ([^ ]*/)?manage\.py test( |$)' >/dev/null && return 0
  pgrep -f '^[^ ]*/pytest( |$)|^pytest( |$)' >/dev/null && return 0
  pgrep -f '^[^ ]*cargo test( |$)|^[^ ]*go test( |$)' >/dev/null && return 0
  pgrep -f '^[^ ]*node [^ ]*/(npm|pnpm)(-cli\.js|\.cjs)? (run )?test( |$)' >/dev/null && return 0
  return 1
}

t=0
while otra_suite && (( t < espera_max )); do sleep 5; t=$((t + 5)); done
if (( t >= espera_max )); then
  echo "tests-de-a-uno: sigue corriendo otra suite después de ${espera_max}s; se lanza igual" >&2
fi
exit 0
