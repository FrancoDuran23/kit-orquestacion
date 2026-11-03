---
name: code-review-en-loop
description: Usar antes de dar por terminado un ticket, un MR/PR o la integración de varios slices. Corre /code-review, arregla lo que encuentra y repite hasta que salga limpio. No reemplaza los tests; los complementa.
---

# Code review en loop

Un review solo es una foto: el arreglo de un hallazgo suele traer otro. Se repite hasta que no quede nada.

## Ciclo

1. Asegurate de que el diff esté completo (todos los slices integrados) y los tests pasen.
2. Corré `/code-review` sobre la rama contra su base (nivel `high` por defecto).
3. Por cada hallazgo:
   - **Real:** arreglalo con su test, si el bug lo amerita.
   - **Falso positivo:** anotá en una línea por qué no aplica. No lo "arregles" para callar al reviewer.
4. Re-corré los tests.
5. Volvé al paso 2. Terminá cuando una vuelta entera no deje hallazgos reales.

## Reglas

- Máximo 5 vueltas. Si sigue apareciendo algo, el problema es de diseño: pará y contáselo a la persona.
- Los arreglos los puede hacer un ejecutor (un slice chico con el hallazgo como SPEC), pero **el review lo corre otro modelo**, nunca el que escribió el código.
- Al cerrar, dejá en el MR/PR una línea: cuántas vueltas, qué se arregló y qué se descartó y por qué.
