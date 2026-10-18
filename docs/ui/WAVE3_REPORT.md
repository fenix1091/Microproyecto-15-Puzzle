# Wave 3 Frontend Implementation Report

This report documents the resolution of all Wave 3 mediator decisions (C1–C7) and frontend findings (MED-001 through MED-023).

## Summary of Fixes

| ID | Description | File & Line |
|---|---|---|
| **C1 & MED-005** | GamePage result listener navigates to `/result` only on `won` or `lost`; abandon navigates to `/menu` | `lib/features/game/presentation/pages/game_page.dart:94-102` |
| **C2** | Exit dialog warning text updated to `"Si ya moviste fichas, la partida se registrará como abandono."` | `lib/shared/widgets/exit_confirmation_dialog.dart:36-39` |
| **C3 & MED-006** | GamePage start failure renders error view with "Reintentar" and "Volver" | `lib/features/game/presentation/pages/game_page.dart:123-162` |
| **C5 & MED-022** | Pausa button disabled when not playing; HUD pulse controller stopped when not playing | `lib/features/game/presentation/widgets/game_hud.dart:67-73,181` |
| **C6** | Route constants separated into `lib/app/routes.dart`, re-exported in `router.dart`, imports updated across presentation layer | `lib/app/routes.dart:1-12`, `lib/app/router.dart:15-18` |
| **C7** | Updated `DESIGN.md` contracts (250ms transitions, 760dp desktop breakpoint, pause exclusion, tile semantics) | `docs/ui/DESIGN.md:28-76` |
| **MED-001** | Declared `onTap: canMove ? widget.onTap : null` and `enabled: canMove` in TileView `Semantics` | `lib/features/game/presentation/widgets/tile_view.dart:73-77` |
| **MED-002** | SplashPage evaluates `depsAsync.hasError` before `isLoading` to render error state on startup failure | `lib/features/splash/presentation/splash_page.dart:95-103` |
| **MED-004** | Landscape GameHud wrapped in `SingleChildScrollView`; full responsive matrix test implemented | `lib/features/game/presentation/widgets/game_hud.dart:227`, `test/widget/responsive_overflow_test.dart:1-155` |
| **MED-008** | Pause overlay isolates background via `ExcludeSemantics` and `IgnorePointer`; PauseOverlay marked `scopesRoute: true` and `explicitChildNodes: true` | `lib/features/game/presentation/pages/game_page.dart:189-192`, `lib/features/game/presentation/widgets/pause_overlay.dart:33-36` |
| **MED-012** | GameHud wrapped in `RepaintBoundary`; BoardView receives `Board` directly, caches static `_EmptySlotsGrid` | `lib/features/game/presentation/widgets/game_hud.dart:140`, `lib/features/game/presentation/widgets/board_view.dart:32-34` |
| **MED-013** | Real `GameController` integration test verifying win navigation, abandon navigation, and lifecycle auto-pause | `test/widget/real_game_controller_test.dart:1-330` |
| **MED-015** | Safe pause on dispose without accessing unmounted Riverpod `ref` or protected state | `lib/features/game/presentation/pages/game_page.dart:51-68` |
| **MED-017** | Removed duplicate board coordinate computations and defensive try/catch blocks in TileView | `lib/features/game/presentation/widgets/tile_view.dart:28-36` |
| **MED-018** | Removed artificial user gesture marking in `gameLost()`; wired `recordUserGesture()` on root `Listener(onPointerDown: ...)` | `lib/shared/services/audio_feedback_service.dart:71-75`, `lib/app/app.dart:34-37` |
| **MED-019** | Displayed `DifficultyDecision` promoted/demoted trend chips on ResultPage and in GameHud | `lib/features/game/presentation/pages/result_page.dart:118-125`, `lib/features/game/presentation/widgets/game_hud.dart:164-171` |
| **MED-020** | `reduceMotion` respected in `AnimatedLogo`, BoardView win pulse animation (600ms), and page fade transitions | `lib/shared/widgets/animated_logo.dart:28-40`, `lib/features/game/presentation/widgets/board_view.dart:45-70`, `lib/app/router.dart:25-35` |
| **MED-021** | BoardView swipe recognition accepts drag distance threshold `>= 24.0` in addition to velocity threshold `>= 120.0` | `lib/features/game/presentation/widgets/board_view.dart:115-135` |
| **MED-023** | Fixed double semantics node in LeaderboardPage Volver button; formatted date numbers with two-digit padding (`dd/MM/yyyy`) | `lib/features/leaderboard/presentation/leaderboard_page.dart:45-53,115-122` |

## Verification
- `dart analyze` passes with 0 issues.
- `flutter test test/widget` passes all 61 tests.
- `flutter build web` compiles successfully.
