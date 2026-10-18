import 'package:equatable/equatable.dart';

/// Base type for expected, recoverable errors surfaced to the UI.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The tapped tile cannot slide into the empty cell.
final class InvalidMoveFailure extends Failure {
  const InvalidMoveFailure([super.message = 'Movimiento inválido']);
}

/// The requested action is not allowed in the current game status.
final class GameStateFailure extends Failure {
  const GameStateFailure(super.message);
}

/// Local persistence (Hive / SharedPreferences) failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
