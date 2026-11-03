---
name: qa-con-video
description: Usar al abrir o mandar un MR/PR con cambios visibles para el usuario. Graba videos con Playwright del flujo cambiado y deja un comentario de QA en el issue (para quien prueba) y otro corto en el MR/PR (evidencia para quien revisa). También cuando pregunten si un ticket ya tiene su QA o su video.
---

# QA con video en el issue y el MR

Que el link al MR no sea lo único que quede en el issue: quien prueba tiene que poder hacerlo sin preguntar.

## Cuándo

- Solo en tickets propios (asignados a vos y con MR/PR hecho por vos).
- **Al abrir el MR/PR:** comentario corto con los videos, como evidencia para el revisor.
- **Cuando se aprueba o mergea:** comentario completo de QA en el issue, con los mismos videos.
- Antes de publicar, mostrale a la persona el texto y los videos y esperá su OK: comentar es visible para todo el equipo.

## 1. Chequear si ya está

```bash
glab issue view NNN --comments        # GitLab
gh issue view NNN --comments          # GitHub
```

Si ya hay un QA con videos, solo agregá lo que falte.

## 2. Grabar

- Levantá la app en local.
- Grabá con Playwright: por script (`record_video_dir`) o con el MCP de Playwright (`.mcp.json` del kit). Los scripts van en un directorio temporal, nunca en el repo.
- **Un video por caso**, corto, que arranque en la pantalla relevante. Mostrá el antes y el después, si se puede.
- Pasalos a `.mp4` (`ffmpeg -i in.webm -c:v libx264 -pix_fmt yuv420p out.mp4`): los `.webm` no se ven inline en todos lados.

## 3. Subir

- GitLab: `glab api projects/:id/uploads -F file=@video.mp4` devuelve el markdown para pegar.
- GitHub: arrastrar el archivo al comentario, o subirlo como asset de un release/draft y linkearlo.

El mismo upload sirve para el issue y para el MR.

## 4. Comentario en el issue

```markdown
## QA

**Qué cambió:** <una o dos líneas, en lenguaje del usuario>
**Dónde se ve:** <menú → pantalla → acción>
**Cómo debería funcionar:** <el comportamiento esperado>

### Casos a probar
1. <caso feliz> → <resultado>
2. <caso borde> → <resultado>
3. <lo que NO debería cambiar> → <resultado>

### Videos
<un video por caso, con título>
```

## 5. Comentario en el MR/PR

Dos líneas de qué se ve en cada video, más los videos. Sin repetir el QA entero.
