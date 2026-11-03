---
name: code-review-en-loop
description: Usar antes de dar por terminado un ticket, un MR/PR o la integración de varios slices. Revisa el diff, arregla lo que encuentra y repite hasta que una vuelta entera salga limpia. Funciona con cualquier agente; usa el review que haya disponible. No reemplaza los tests; los complementa.
---

# Code review en loop

Un review solo es una foto: el arreglo de un hallazgo suele traer otro. Se repite hasta que no quede nada.

## Qué review usar

En este orden, el primero que esté disponible:

1. **El review nativo del cliente**, si trae uno (por ejemplo `/code-review` en Claude Code).
2. **La skill `code-review` de mattpocock** (`npx skills add mattpocock/skills -s code-review`): revisa contra los estándares del repo y contra el SPEC o ticket que originó el cambio.
3. **El checklist de respaldo** de abajo.

> **Aviso:** si tu cliente no trae review propio y no instalaste el de mattpocock, el respaldo sirve para empezar, pero conviene armar un review propio del equipo: una skill `code-review` con sus estándares, sus errores frecuentes y lo que el equipo siempre pide en los MRs. Es la pieza que más mejora con el tiempo.

### Checklist de respaldo

Leé el diff completo contra la rama base y respondé cada punto con evidencia (archivo y línea):

- **Correctitud:** ¿hace lo que pide el SPEC o ticket? ¿Casos borde, nulos, vacíos, fechas, permisos?
- **Tests:** ¿cada comportamiento nuevo tiene su test? ¿Algún test prueba poco o nada?
- **Regresiones:** ¿cambió algo que otros usan (firmas, contratos, migraciones, mensajes)?
- **Seguridad:** inputs sin validar, secretos, consultas armadas a mano, permisos saltados.
- **Estándares del repo:** lo que dicen `AGENTS.md`, `CLAUDE.md`, los linters y el estilo del código vecino.
- **Simplicidad:** código muerto, duplicado o una abstracción que no hace falta.

## Ciclo

1. Verificá que el diff esté completo (todos los slices integrados) y que los tests pasen.
2. Corré el review sobre la rama contra su base.
3. Por cada hallazgo:
   - **Real:** arreglalo, con su test si el bug lo amerita.
   - **Falso positivo:** anotá en una línea por qué no aplica. No lo "arregles" solo para callar al reviewer.
4. Volvé a correr los tests.
5. Volvé al paso 2. Terminá cuando una vuelta entera no deje hallazgos reales.

## Reglas

- **Máximo 5 vueltas.** Si sigue apareciendo algo, el problema es de diseño: pará y contáselo a la persona.
- **El review lo hace un modelo distinto del que escribió el código.** Si Grok escribió, revisa Claude o GPT, y al revés. Los arreglos sí los puede hacer un ejecutor, con el hallazgo como SPEC.
- **Al cerrar, dejá una línea en el MR/PR:** cuántas vueltas hubo, qué se arregló y qué se descartó, y por qué.
