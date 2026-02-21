import 'package:equatable/equatable.dart';

enum TimerMode { none, stopwatch, countdown }

abstract class TimerState extends Equatable {
  final TimerMode mode;
  final int currentSeconds;
  final int totalDurationSeconds; // Only for countdown
  final bool isRunning;

  const TimerState({
    required this.mode,
    required this.currentSeconds,
    this.totalDurationSeconds = 0,
    required this.isRunning,
  });

  @override
  List<Object?> get props => [
    mode,
    currentSeconds,
    totalDurationSeconds,
    isRunning,
  ];
}

class TimerInitial extends TimerState {
  const TimerInitial()
    : super(mode: TimerMode.none, currentSeconds: 0, isRunning: false);
}

class TimerRunInProgress extends TimerState {
  const TimerRunInProgress({
    required super.mode,
    required super.currentSeconds,
    super.totalDurationSeconds,
  }) : super(isRunning: true);
}

class TimerRunPause extends TimerState {
  const TimerRunPause({
    required super.mode,
    required super.currentSeconds,
    super.totalDurationSeconds,
  }) : super(isRunning: false);
}

class TimerRunComplete extends TimerState {
  const TimerRunComplete({required super.mode, super.totalDurationSeconds})
    : super(currentSeconds: 0, isRunning: false);
}
