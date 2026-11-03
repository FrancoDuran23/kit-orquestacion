# kit-orquestacion — guía para agentes que editan este repo

- Es un kit **agnóstico al modelo**. La lógica vive una sola vez y cada cliente tiene un adaptador fino:
  - `skills/`: estándar Agent Skills (`<nombre>/SKILL.md`). No nombres herramientas de un cliente en particular sin dar la alternativa.
  - `reglas/`: la lógica de los hooks. Contrato: reciben el comando en `$1` e imprimen `allow`, `ask<TAB>motivo` o `deny<TAB>motivo`. `evaluar.sh` las corre todas y gana la más estricta.
  - `adaptadores/<cliente>/`: traducen el JSON del cliente a `reglas/evaluar.sh` y de vuelta. Sin lógica propia.
  - `mcp/servidores.json`: los MCP, definidos una vez; `install.sh` los escribe en el formato de cada cliente.
  - `bin/`: `slices` y `juez-jev`. Bash y Python con stdlib, sin dependencias.
  - `skills-lock.json`: skills de terceros, en el formato del CLI `skills`.
- Probá en `.prueba/` (ignorado por git), nunca en un repo real.
- Antes de commitear: `bash -n` sobre los scripts, `claude plugin validate .`, y `bash .prueba/test-reglas.sh` si tocaste reglas.
- Commits sin atribución de IA.
