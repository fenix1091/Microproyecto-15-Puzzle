# 🧩 Sliding Puzzle

Rompecabezas deslizante moderno hecho con **Flutter**: tableros de 3×3 a 6×6, dificultad que se adapta a cómo juegas, récords locales, temas claro y oscuro, y accesibilidad para lectores de pantalla.

[![Flutter CI](https://github.com/fenix1091/Microproyecto-15-Puzzle/actions/workflows/flutter.yml/badge.svg)](https://github.com/fenix1091/Microproyecto-15-Puzzle/actions/workflows/flutter.yml)
[![Playwright](https://github.com/fenix1091/Microproyecto-15-Puzzle/actions/workflows/playwright.yml/badge.svg)](https://github.com/fenix1091/Microproyecto-15-Puzzle/actions/workflows/playwright.yml)

---

## El juego

Las fichas numeradas están desordenadas en una cuadrícula con un hueco. El objetivo es dejarlas **en orden del 1 al último**, de izquierda a derecha y de arriba abajo, con el hueco en la esquina inferior derecha.

### Cómo se juega

1. En el menú pulsa **Jugar**.
2. **Toca una ficha** que esté en la misma fila o columna que el hueco y se deslizará hacia él. Si hay varias fichas entre medio, se mueven todas juntas y cuenta como **un solo movimiento**.
3. También puedes **deslizar** el dedo o el mouse hacia el hueco.
4. El reloj empieza con tu primer movimiento. Si llegas a cero antes de resolverlo, **pierdes**.
5. Durante la partida tienes **Pausa**, **Reiniciar** (vuelve a la misma mezcla) y **Salir**. Si sales después de mover alguna ficha, la partida cuenta como abandono.

Todas las mezclas son **siempre resolubles**: se generan con movimientos válidos desde el tablero ordenado.

### Niveles

| Nivel | Tablero | Tiempo límite |
|---|---|---|
| Fácil | 3×3 | 5 min |
| Medio | 4×4 | 6 min |
| Difícil | 4×4 | 4 min |
| Experto | 5×5 | 8 min |
| Maestro | 6×6 | 12 min |

### Dificultad adaptativa

Con la opción activada (por defecto), el juego ajusta el reto según tu historial:

- **Subes de nivel** con 3 victorias seguidas usando menos del 60 % del tiempo.
- **Bajas de nivel** con 2 derrotas seguidas o si sueles quedarte sin tiempo.
- Dentro de cada nivel se ajustan la mezcla y el tiempo (±20 %) según tu velocidad y eficiencia.

Si prefieres elegir el nivel, desactiva **Dificultad adaptativa** en **Configuración** y escoge el **Nivel manual**.

### Otras pantallas

- **Marcadores:** los 10 mejores tiempos de cada nivel, tu récord personal y tus estadísticas (victorias, promedios, rachas).
- **Configuración:** tema (sistema / claro / oscuro), sonido, vibración, dificultad y reducir animaciones.
- **Instrucciones:** las reglas dentro del juego.

---

## Ejecutarlo en tu computadora

### Requisitos

- [Git](https://git-scm.com/)
- [Flutter 3.47.7 (stable)](https://docs.flutter.dev/get-started/install). Revisa con `flutter doctor`.
- Google Chrome (para la versión web)

### Pasos

```bash
git clone https://github.com/fenix1091/Microproyecto-15-Puzzle.git
cd Microproyecto-15-Puzzle
flutter pub get
flutter run -d chrome
```

Versión optimizada (release) servida en local:

```bash
flutter build web --release
npx http-server build/web -p 8080   # luego abre http://localhost:8080
```

En Android o iOS, conecta un dispositivo o emulador y ejecuta `flutter run`. Hace falta el Android SDK o Xcode. Esas plataformas todavía no están verificadas.

### ⚠️ Si usas Windows

- Clona el proyecto en una ruta **sin acentos ni espacios** (por ejemplo `C:\dev\Microproyecto-15-Puzzle`). Con caracteres como `ó` en la ruta, `flutter analyze` y `flutter build` fallan.
- Usa **PowerShell** o CMD, no Git Bash.
- Si `flutter pub get` pide *symlink support*, activa el **Modo de desarrollador**: Configuración → Sistema → Para desarrolladores.

---

## Para desarrolladores

### Arquitectura

Clean Architecture por feature, con **Riverpod** para estado e inyección de dependencias, **go_router** para la navegación y **Hive** y **SharedPreferences** para la persistencia.

```
lib/
  app/        # composición: router, temas, providers (DI)
  core/       # Result, Failure, Clock, RandomSource, config
  shared/     # widgets y servicios comunes (audio/háptica)
  features/
    splash/ menu/ game/ leaderboard/ settings/ instructions/
      domain/        # entidades, algoritmos, repositorios (interfaces), casos de uso
      data/          # implementaciones Hive / SharedPreferences
      application/   # controladores Riverpod
      presentation/  # páginas y widgets
```

La especificación técnica completa está en [`docs/SPEC.md`](docs/SPEC.md). La revisión técnica está en [`docs/REVIEW.md`](docs/REVIEW.md) y el informe de QA en [`docs/QA_REPORT.md`](docs/QA_REPORT.md). Los assets (sonidos, iconos, fuentes) y cómo se comportan en el sistema se explican en [`docs/ASSETS.md`](docs/ASSETS.md).

### Tests

```bash
flutter analyze
flutter test                      # unitarios + widgets
flutter test --coverage
```

Integración en Chrome (necesita [ChromeDriver](https://googlechromelabs.github.io/chrome-for-testing/) de la misma versión que Chrome):

```bash
chromedriver --port=4444
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d web-server --browser-name=chrome --headless
```

End-to-end con Playwright sobre los builds web de QA:

```bash
npm ci
npx playwright install
flutter build web --release --dart-define=QA=true --dart-define=QA_SEED=42
flutter build web --release --dart-define=QA=true --dart-define=QA_SEED=42 --dart-define=QA_SHUFFLE_MOVES=1 --output build/web_qa_win
flutter build web --release --dart-define=QA=true --dart-define=QA_SEED=42 --dart-define=QA_TIME_LIMIT=5 --output build/web_qa_timeout
npx playwright test
```

Opciones de compilación para QA: `QA=true` expone el árbol de accesibilidad en el DOM, `QA_SEED` fija la mezcla, `QA_SHUFFLE_MOVES` genera tableros casi resueltos y `QA_TIME_LIMIT` reduce el tiempo límite (en segundos).

### CI / CD

| Workflow | Qué hace |
|---|---|
| `flutter.yml` | formato, análisis, tests con cobertura, build web y test de integración |
| `playwright.yml` | e2e en Chromium, Firefox, WebKit, Pixel 5, iPhone 12 y teléfono en horizontal |
