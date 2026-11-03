<!-- kit-orquestacion: copiá este bloque al AGENTS.md del repo (o dejá que lo haga ./slices init) -->

## Cómo se trabaja en este repo (slices)

- El trabajo grande se parte en slices. Cada uno tiene un SPEC en `specs/<id>.spec.md` con su alcance de archivos y los tests exigidos.
- Si sos el worker de un slice: trabajá solo en el directorio donde estás parado (es el worktree del slice) y solo en los archivos del "Alcance de archivos". Si hace falta tocar otro, decilo en el recibo: no lo hagas en silencio.
- Un slice está hecho cuando pasan los chequeos de `slices.conf` y están los tests que exige el SPEC. Los chequeos se vuelven a correr por fuera y un juez compara los tests contra el SPEC.
- Terminá con un recibo (`===RECIBO===` … `===FIN===`): qué hiciste, qué archivos tocaste, qué corriste y con qué resultado, y qué NO quedó (gaps). Si no tenés certeza, no digas "listo".
- No hagas `git commit`, `git push` ni cambies de rama: de eso se ocupa `./slices`.
- Lo irreversible (push, merge remoto, publicar en issues, borrar datos) siempre lo confirma una persona.
