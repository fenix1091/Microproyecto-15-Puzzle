# Informe de QA — Sliding Puzzle

## Resumen

La ejecución completa terminó con **67 casos aprobados en el resumen de Playwright, 0 fallos inesperados y 5 omitidos**. De los 67 aprobados, 49 pasaron normalmente y 18 son fallos esperados (`test.fail`) de tres hallazgos reproducidos en los seis proyectos; se omite la medición de rendimiento fuera de Chromium de escritorio. Se registraron **3 hallazgos medios**, sin críticos, altos ni bajos.

| Severidad | Casos |
|---|---:|
| Crítico | 0 |
| Alto | 0 |
| Medio | 3 |
| Bajo | 0 |

| Área | Casos |
|---|---:|
| funcional | 1 |
| UI | 0 |
| UX | 0 |
| rendimiento | 0 |
| responsive | 0 |
| accesibilidad | 2 |

## Entorno y ejecución

- Windows, desde la junction ASCII `D:\dev\sliding_puzzle`.
- Flutter 3.47.7 stable, Dart 3.13.5; Node.js 24.14.1; npm 11.11.0; Playwright 1.64.1.
- Matriz: Chromium, Firefox, WebKit, Pixel 5, iPhone 12 y teléfono horizontal (844×390).
- Variantes QA: build normal con `QA=true` y semilla 42; build de victoria con `QA_SHUFFLE_MOVES=1`; build de derrota con `QA_TIME_LIMIT=5`.
- Resultado de `npx playwright test`: 49 aprobados normalmente, 18 fallos esperados asociados a QA-001..QA-003, 0 fallos inesperados y 5 omitidos (rendimiento fuera de Chromium de escritorio). Playwright incluye los 18 fallos esperados en sus 67 aprobados.
- Rendimiento en Chromium de escritorio: 30 toques en Maestro tardaron 7.37 s; se muestrearon 438 cuadros y 4 intervalos superaron 32 ms. El tiempo incluye la interacción automatizada de Playwright.

Para repetir desde PowerShell:

```powershell
cd D:\dev\sliding_puzzle
npm ci
flutter build web --release --dart-define=QA=true --dart-define=QA_SEED=42
flutter build web --release --dart-define=QA=true --dart-define=QA_SEED=42 --dart-define=QA_SHUFFLE_MOVES=1 --output build/web_qa_win
flutter build web --release --dart-define=QA=true --dart-define=QA_SEED=42 --dart-define=QA_TIME_LIMIT=5 --output build/web_qa_timeout
npx playwright install chromium firefox webkit
npx playwright test
```

## Hallazgos

### QA-001 · Las métricas del HUD no tienen etiquetas accesibles individuales
- Severidad: Medio
- Área: accesibilidad
- Descripción: el árbol de semántica anuncia el nivel, los movimientos y el tiempo como texto dentro de un único grupo sin nombre. No expone los tres nombres requeridos (`Nivel …`, `Movimientos …`, `Tiempo mm:ss`) para navegación por etiquetas.
- Pasos para reproducir: abrir una partida y consultar el árbol de accesibilidad en cualquiera de los seis proyectos.
- Resultado esperado / obtenido: cada métrica aparece como nodo con su etiqueta especificada / aparece el grupo de texto “Nivel Fácil Movimientos 0 Tiempo 05:00”.
- Causa probable: los nodos `Semantics` que declaran las etiquetas se fusionan con el grupo de HUD; los wrappers no establecen un límite semántico independiente en [game_hud.dart:112](../lib/features/game/presentation/widgets/game_hud.dart#L112), [game_hud.dart:123](../lib/features/game/presentation/widgets/game_hud.dart#L123) y [game_hud.dart:133](../lib/features/game/presentation/widgets/game_hud.dart#L133).
- Solución recomendada: aislar cada etiqueta en su propio nodo de semántica y comprobar que el lector de pantalla y los selectores por etiqueta las reciben por separado.
- Evidencia: `HUD exposes the required individual accessible labels`; [captura](qa/QA-001-hud-semantics.png).

### QA-002 · La variante `QA_SHUFFLE_MOVES=1` no genera un tablero de un movimiento
- Severidad: Medio
- Área: funcional
- Descripción: el override QA pone la longitud de mezcla en 1, pero conserva la profundidad mínima del nivel Fácil. Con `QA_SEED=42`, el tablero generado requiere 4 movimientos para resolverse, por lo que la variante no permite probar una victoria con un toque como se documenta.
- Pasos para reproducir: compilar `web_qa_win` con `QA_SHUFFLE_MOVES=1`; iniciar la partida y calcular la solución mínima desde las fichas etiquetadas.
- Resultado esperado / obtenido: solución de un movimiento / solución de cuatro movimientos con la semilla fija.
- Causa probable: [start_game.dart:58](../lib/features/game/domain/usecases/start_game.dart#L58)–[start_game.dart:69](../lib/features/game/domain/usecases/start_game.dart#L69) mantiene `minSolutionDepth`; [shuffler.dart:20](../lib/features/game/domain/services/shuffler.dart#L20)–[shuffler.dart:25](../lib/features/game/domain/services/shuffler.dart#L25) continúa la caminata hasta esa profundidad o su límite.
- Solución recomendada: al activar el override de mezcla para QA, ajustar también la profundidad mínima de manera que `QA_SHUFFLE_MOVES=1` produzca un tablero resoluble en un toque.
- Evidencia: `QA_SHUFFLE_MOVES=1 creates a one-move board`; [captura](qa/QA-002-shuffle-distance.png).

### QA-003 · La dificultad adaptativa aparece deshabilitada para tecnologías de asistencia
- Severidad: Medio
- Área: accesibilidad
- Descripción: el interruptor se ve habilitado y responde al toque, pero Playwright y el árbol de semántica lo exponen como deshabilitado. Las personas que navegan con teclado o lector de pantalla no pueden cambiar la opción de forma accesible.
- Pasos para reproducir: abrir Configuración con la dificultad adaptativa activa y consultar el nodo `switch` “Dificultad adaptativa”.
- Resultado esperado / obtenido: interruptor habilitado / nodo marcado `disabled`.
- Causa probable: el switch de dificultad está en el mismo grupo semántico que el `ListTile` deshabilitado de “Nivel manual”; revisar la estructura entre [settings_page.dart:172](../lib/features/settings/presentation/settings_page.dart#L172) y [settings_page.dart:196](../lib/features/settings/presentation/settings_page.dart#L196).
- Solución recomendada: separar el switch y el selector manual en nodos de lista independientes para que el estado deshabilitado del selector no se propague al switch.
- Evidencia: `adaptive difficulty control is enabled for keyboard and screen reader users`; [captura](qa/QA-003-adaptive-control.png).

## Re-verificación (coordinador, 2026-10-18)

| ID | Estado | Corrección | Verificación |
|---|---|---|---|
| QA-001 | **Resuelto** | `game_hud.dart:113,124,135`: un nodo `Semantics(container: true)` por métrica | Sondeo del DOM: `Nivel Fácil`, `Movimientos 0` y `Tiempo 05:00` son tres `flt-semantics` hoja independientes. Flutter web publica las etiquetas de solo texto como contenido, no como `aria-label`, así que la prueba ahora usa nodos hoja por texto exacto en lugar de `getByLabel`. |
| QA-002 | **Resuelto** | `start_game.dart:31-36,73`: el override `QA_SHUFFLE_MOVES` pone `minSolutionDepth = 0` | Prueba e2e en los 6 proyectos. Se eliminó el valor de reserva fijo `[3, 2, 5, 8]` y ahora se espera a que existan fichas antes de leer el tablero (en WebKit se leía antes de tiempo). |
| QA-003 | **Resuelto** | `settings_page.dart:172,192`: el switch adaptativo queda aislado del selector manual deshabilitado | Prueba e2e en los 6 proyectos. La prueba de Maestro comprueba el nivel por texto accesible (`toContainText`), no por `aria-label`. |

Ajustes de la suite:
- Rendimiento: el primer intervalo incluye el calentamiento y Chromium headless pinta a menudo a 30 fps (33 ms). Ahora solo cuentan como caídas los cuadros de más de 50 ms, con aserción `< 5`. Resultado: 30 toques en 6×6, 406 cuadros, **0 de más de 50 ms**, peor cuadro 50 ms.
- `retries: 1`: el arranque en frío de WebKit con 3 workers a veces supera los 30 s. Las pruebas afectadas pasan aisladas (8/8) y en el reintento se reportan como *flaky*.

**Resultado final de `npx playwright test`:** 66 aprobadas, 1 *flaky* (WebKit, arranque en frío), 5 omitidas, **0 fallos** y 0 fallos esperados.

## Cobertura aprobada

- Splash llega al menú; Marcadores, Configuración e Instrucciones abren y regresan.
- Las fichas movibles actualizan el contador; un toque inválido no lo incrementa; Pausa detiene el cuadro renderizado, Reanudar continúa y Reiniciar limpia los movimientos.
- El diálogo Salir permite cancelar y confirmar el regreso al menú.
- El tablero de QA se puede resolver hasta Victoria; “Jugar de nuevo” y “Menú” funcionan; las victorias aparecen en Marcadores. La variante de límite de tiempo llega a Derrota.
- Tema oscuro y sonido desactivado persisten después de recargar; las capturas de menú claro y oscuro difieren.
- Los botones reciben foco de teclado; tablero y botón Pausa caben en el viewport probado de cada proyecto.
- No se capturaron errores de consola o excepciones JavaScript al abrir menú y partida.
