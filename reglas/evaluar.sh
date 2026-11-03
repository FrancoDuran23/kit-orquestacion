#!/usr/bin/env bash
# Corre todas las reglas sobre un comando de shell y devuelve la decisión más estricta.
#
#   reglas/evaluar.sh "<comando>"   →   allow  |  ask<TAB>motivo  |  deny<TAB>motivo
#
# Es agnóstico al cliente: cada adaptador (adaptadores/<cliente>/) lee el comando del
# JSON que manda su cliente, llama a esto y traduce la respuesta a su formato.
# Para agregar una regla: un script más en reglas/ con el mismo contrato.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1-}"
decision="allow" motivo=""
for r in "$DIR"/*.sh; do
  [[ "$(basename "$r")" == evaluar.sh ]] && continue
  IFS=$'\t' read -r d m < <(bash "$r" "$cmd")
  case "$d" in
    deny) decision="deny"; motivo="$m"; break ;;
    ask)  [[ "$decision" == allow ]] && { decision="ask"; motivo="$m"; } ;;
  esac
done
if [[ "$decision" == allow ]]; then echo allow; else printf '%s\t%s\n' "$decision" "$motivo"; fi
