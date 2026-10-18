# Sliding Puzzle — Especificación y Decisiones de Diseño UI/UX

> Documento de diseño frontend (Wave 2B) · Material 3 · Español · WCAG AA

---

## 1. Identidad Visual y Filosofía de Diseño

El diseño de **Sliding Puzzle** combina la estética moderna y limpia de **Material 3 (M3)** con una sensación táctil y lúdica. La experiencia es ágil, responsiva y accesible para jugadores casuales y expertos.

- **Estilo**: Material Design 3 con bordes suaves, superficies con tonalidades sutiles (`surfaceContainer`), y retroalimentación visual clara e instantánea.
- **Tono**: Dinámico, pulido y enfocado en la concentración del jugador.
- **Herramienta**: Google Stitch no estuvo disponible en el entorno CLI local; todas las decisiones de diseño se han formalizado directamente en código modular en `lib/app/theme/` y se documentan aquí.

---

## 2. Paleta de Colores y Tokens

### 2.1 Semilla y Esquemas de Color
- **Seed Color**: `#2563EB` (Azul zafiro vibrante, moderno y con excelente contraste).
- **Acentos secundarios**: Ámbar cálido (`#F59E0B`) para insignias, récords personales y estados dorados.
- **Modos**:
  - **Claro (`ThemeMode.light`)**: Superficies nítidas (`#F8FAFC`), texto de alto contraste (`#0F172A`), fichas con gradiente suave y sombra ligera.
  - **Oscuro (`ThemeMode.dark`)**: Fondo oscuro profundo pero no negro puro (`#0F172A`), superficies `surfaceContainer` en `#1E293B`, menor fatiga visual.
  - **Sistema (`ThemeMode.system`)**: Sigue la configuración del sistema operativo del usuario.

### 2.2 Fichas (Tiles)
- **Ficha estándar**: Superficie `primaryContainer` con texto `onPrimaryContainer`.
- **Ficha en posición correcta (`isTileHome`)**: Borde sutil acentuado con `tertiary` o `primary` y ligera elevación para recompensar el progreso sin distraer.
- **Ficha vacía**: Espacio transparente o hendidura suave con fondo `surfaceContainerHighest` con bajo contraste para dar sensación de hueco.

### 2.3 Contraste y Accesibilidad (WCAG AA)
- Todos los textos principales cumplen una relación de contraste superior a 4.5:1.
- Fichas y botones tienen etiquetas semánticas explícitas y roles de accesibilidad para lectores de pantalla.
- Targets táctiles mínimos de **48 × 48 dp**.

---

## 3. Tokens de Animación y Movimiento

Definidos en `lib/app/theme/tokens.dart`:

| Elemento | Duración | Curva | Descripción |
|---|---|---|---|
| Desplazamiento de ficha (`tileMoveDuration`) | **140 ms** | `Curves.easeOutCubic` | Rápido, elástico y satisfactorio |
| Sacudida de error (`invalidShakeDuration`) | **250 ms** | `Curves.easeInOut` | 3 oscilaciones rápidas en eje X |
| Pulso de temporizador (<10 s) | **1000 ms** | `Curves.easeInOut` | Latido en rojo de alerta |
| Transición entre pantallas (`transitionDuration`) | **250 ms** | `Curves.easeInOut` | Fade-through suave |
| Logo de Splash | **800 ms** escalonado | `Curves.easeOutBack` | Fichas flotantes que encajan en su sitio |

### Reducción de Movimiento
Si `MediaQuery.of(context).disableAnimations` es `true` o `UserSettings.reduceMotion` está activado:
- Las duraciones se reducen a `Duration.zero` o transiciones instantáneas.
- Se eliminan sacudidas y latidos continuos.

---

## 4. Arquitectura de Pantallas

### 4.1 Splash Screen (`/splash`)
- Rejilla animada 2×2 o 3×3 que forma el icono del juego.
- Espera asíncrona concurrente de:
  1. `appDependenciesProvider.future` (Hive y SharedPreferences).
  2. `settingsControllerProvider.future` (Ajustes de usuario).
  3. `feedbackServiceProvider.preload()` (Buffers de audio).
- Tiempo mínimo de estancia de **1.2 segundos** para permitir la apreciación de la animación de bienvenida.
- Navegación automática a `/menu` mediante `context.go('/menu')`.

### 4.2 Menú Principal (`/menu`)
- Cabecera con título del juego y tarjeta de nivel actual:
  - Muestra el nivel ("Fácil", "Medio", "Difícil", "Experto", "Maestro").
  - Si la dificultad es adaptativa, muestra la tendencia (`promoted`: "↑ En ascenso", `demoted`: "↓ Ajustando", `unchanged`: "Estable").
- Botones de acción principales en columna centrada:
  - **"Jugar"** (`FilledButton`)
  - **"Marcadores"** (`OutlinedButton`)
  - **"Configuración"** (`OutlinedButton`)
  - **"Instrucciones"** (`OutlinedButton`)

### 4.3 Pantalla de Juego (`/game`)
- Al entrar: dispara `gameControllerProvider.notifier.start()`.
- **HUD**:
  - Temporizador con semántica `Tiempo {mm:ss}` (si hay límite, cuenta regresiva; últimos 10 s parpadea en color de error).
  - Movimientos con semántica `Movimientos {n}`.
  - Nivel con semántica `Nivel {nombre}` y dimensiones del tablero (ej. "Medio (4×4)").
  - Botón **"Pausa"**, botón **"Reiniciar"**, botón **"Salir"**.
- **Tablero**:
  - `LayoutBuilder` cuadrado responsivo: `min(w, h) * 0.9` hasta un máximo de `560 dp`.
  - En pantallas horizontales (landscape o desktop ancho ≥ 760 dp), HUD y controles se colocan al lateral en un layout de dos columnas sin desbordamiento.
  - Soporte de gestos: **Tap** y **Swipe/Arrastre** (evaluado por velocidad o distancia ≥ 24 dp) hacia la celda vacía.
  - Deslizamiento múltiple si se toca una ficha en la misma fila/columna que el hueco.
  - `RepaintBoundary` por cada ficha para optimizar la rasterización a 60/120 FPS.
- **Overlay de Pausa**:
  - Fondo semi-transparente que bloquea interacción y oculta el contenido del tablero.
  - Excluye el fondo de la semántica (`ExcludeSemantics`) y toques para evitar duplicidad de botones en el árbol.
  - Botón **"Reanudar"**, **"Reiniciar"**, **"Salir"**.
- **Diálogo de Confirmación de Salida**:
  - Botón "Salir" o gesto de atrás (`PopScope`).
  - Pregunta al usuario: "Si ya moviste fichas, la partida se registrará como abandono."
  - Al confirmar: ejecuta `abandon()` y navega a `/menu`.

### 4.4 Pantalla de Resultado (`/result`)
- Requiere `extra: GameResult`. Si se accede sin `extra`, redirige a `/menu`.
- Título: **"¡Victoria!"** o **"Derrota"** (o "Partida abandonada").
- Insignia destacada **"¡Nuevo récord!"** cuando `result.isPersonalBest == true`.
- Métricas detalladas:
  - Tiempo transcurrido y récord histórico del nivel (`personalBestProvider`).
  - Movimientos y eficiencia (`movimientos / profundidad mínima`).
  - Nivel y tamaño de tablero.
- Botones: **"Jugar de nuevo"** (inicia nueva partida) y **"Menú"** (vuelve al menú).

### 4.5 Pantalla de Marcadores (`/leaderboard`)
- Cabecera con estadísticas globales (`playerStatsProvider`): partidas jugadas, victorias, tasa de victoria, racha actual y mejor racha.
- Pestañas (`TabBar`) por cada `DifficultyLevel` (Fácil, Medio, Difícil, Experto, Maestro).
- Lista top 10 con rangos 1..10, duración, movimientos y fecha formateada.
- Estados explícitos de carga (`CircularProgressIndicator`), vacío ("No hay récords registrados todavía") y error.
- Botón **"Volver"** o flecha de navegación en AppBar.

### 4.6 Pantalla de Configuración (`/settings`)
- Opciones reactivas conectadas a `settingsControllerProvider`:
  - **Tema**: SegmentedButton o ListTile (Sistema / Claro / Oscuro).
  - **Sonido**: Switch (Activado / Desactivado).
  - **Vibración**: Switch (Activado / Desactivado).
  - **Dificultad adaptativa**: Switch.
  - **Nivel manual**: Selector de nivel (Fácil, Medio, Difícil, Experto, Maestro), habilitado únicamente cuando la dificultad adaptativa está apagada.
  - **Reducir animaciones**: Switch.
- Botón **"Volver"**.

### 4.7 Pantalla de Instrucciones (`/instructions`)
- Reglas del rompecabezas deslizante.
- Tabla explicativa de niveles y tamaños de tablero.
- Explicación del algoritmo adaptativo (cómo se evalúan las rachas de victorias/derrotas y la velocidad).
- Botón **"Volver"**.

---

## 5. Contrato de Accesibilidad y Semántica (QA)

Para compatibilidad estricta con Playwright y lectores de pantalla:
1. **Fichas**: `Semantics(label: "Ficha $n, fila $r, columna $c" (+ ", movible" si canMove), button: true, onTap: onTap, enabled: canMove)` (filas y columnas 1-based).
2. **Botones**: `Semantics` o texto exacto:
   `"Jugar"`, `"Marcadores"`, `"Configuración"`, `"Instrucciones"`, `"Pausa"`, `"Reanudar"`, `"Reiniciar"`, `"Salir"`, `"Jugar de nuevo"`, `"Menú"`, `"Volver"`.
3. **HUD**:
   - `Semantics(label: "Tiempo $mm:$ss")`
   - `Semantics(label: "Movimientos $n")`
   - `Semantics(label: "Nivel $nombre")`
4. **Nombres de niveles**: "Fácil", "Medio", "Difícil", "Experto", "Maestro".
