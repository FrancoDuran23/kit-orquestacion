#!/usr/bin/env bash
# Regla: si el comando corre una suite de tests y ya hay otra corriendo, espera.
# Con varios agentes en paralelo la base de datos y la RAM son compartidas:
# el código se paraleliza, los tests no.
# Contrato: comando en $1 → imprime allow (después de esperar, si hizo falta).
#
# KIT_TESTS_PATRON amplía qué cuenta como tests (regex extendida).
# KIT_TESTS_ESPERA: segundos máximos de espera (el adaptador debe dar más de timeout).
cmd="${1-}"
patron="${KIT_TESTS_PATRON:-(^|[;&|[:space:]])((uv run |poetry run )?python[0-9.]* -m pytest|pytest|manage\.py test|npm (run )?test|pnpm (run )?test|cargo test|go test)\b}"
espera_max="${KIT_TESTS_ESPERA:-540}"

if grep -qE "$patron" <<<"$cmd"; then
  # Ancla en el binario: un `pgrep -f "pytest"` suelto se encuentra a sí mismo y
  # a cualquier agente cuyo prompt mencione pytest, y espera para siempre.
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
  (( t >= espera_max )) && echo "tests-de-a-uno: sigue otra suite después de ${espera_max}s; se lanza igual" >&2
fi
echo allow
