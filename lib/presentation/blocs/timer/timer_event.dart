import 'package:equatable/equatable.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

class StartRestTimer extends TimerEvent {
  final int durationSeconds;
  const StartRestTimer(this.durationSeconds);

  @override
  List<Object?> get props => [durationSeconds];
}

class StartStopwatch extends TimerEvent {}

class PauseTimer extends TimerEvent {}

class ResumeTimer extends TimerEvent {}

class ResetTimer extends TimerEvent {}

class RefreshTimer extends TimerEvent {}
