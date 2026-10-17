import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/datasources/local_database_service.dart';
import 'timer_event.dart';
import 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final LocalDatabaseService _settings;
  final DateTime Function() _now;
  Timer? _ticker;
  AudioPlayer? _audio;
  DateTime? _deadline;
  DateTime? _started;
  bool _played = false;

  TimerBloc(this._settings, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const TimerInitial()) {
    on<TimerEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }
  void _startTicks() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => add(RefreshTimer()),
    );
  }

  Future<void> _stopSound() async {
    try {
      await _audio?.stop();
    } catch (_) {
      /* Sound is optional. */
    }
  }

  Future<void> _playSound() async {
    try {
      _audio ??= AudioPlayer();
      await _audio!.play(AssetSource('sounds/timer_done.mp3'));
    } catch (_) {
      /* Sound is optional. */
    }
  }

  void _handle(TimerEvent event, Emitter<TimerState> emit) {
    if (event is StartRestTimer) {
      _stopSound();
      _played = false;
      _deadline = _now().add(Duration(seconds: event.durationSeconds));
      emit(
        TimerRunInProgress(
          mode: TimerMode.countdown,
          currentSeconds: event.durationSeconds,
          totalDurationSeconds: event.durationSeconds,
        ),
      );
      _startTicks();
    } else if (event is StartStopwatch) {
      _started = _now();
      emit(
        const TimerRunInProgress(mode: TimerMode.stopwatch, currentSeconds: 0),
      );
      _startTicks();
    } else if (event is PauseTimer && state.isRunning) {
      _ticker?.cancel();
      emit(
        TimerRunPause(
          mode: state.mode,
          currentSeconds: state.currentSeconds,
          totalDurationSeconds: state.totalDurationSeconds,
        ),
      );
    } else if (event is ResumeTimer && state is TimerRunPause) {
      _deadline = _now().add(Duration(seconds: state.currentSeconds));
      _started = _now().subtract(Duration(seconds: state.currentSeconds));
      emit(
        TimerRunInProgress(
          mode: state.mode,
          currentSeconds: state.currentSeconds,
          totalDurationSeconds: state.totalDurationSeconds,
        ),
      );
      _startTicks();
    } else if (event is ResetTimer) {
      _ticker?.cancel();
      _deadline = null;
      _started = null;
      _stopSound();
      emit(const TimerInitial());
    } else if (event is RefreshTimer && state.isRunning) {
      if (state.mode == TimerMode.countdown && _deadline != null) {
        final remaining = (_deadline!.difference(_now()).inMilliseconds / 1000)
            .ceil()
            .clamp(0, state.totalDurationSeconds);
        if (remaining <= 3 && remaining > 0 && !_played) {
          _played = true;
          if (_settings.getPlayTimerSound()) _playSound();
        }
        if (remaining == 0) {
          _ticker?.cancel();
          if (_settings.getPlayTimerSound()) {
            HapticFeedback.lightImpact().catchError((_) {});
          }
          emit(
            TimerRunComplete(
              mode: state.mode,
              totalDurationSeconds: state.totalDurationSeconds,
            ),
          );
        } else {
          emit(
            TimerRunInProgress(
              mode: state.mode,
              currentSeconds: remaining,
              totalDurationSeconds: state.totalDurationSeconds,
            ),
          );
        }
      } else if (state.mode == TimerMode.stopwatch && _started != null) {
        emit(
          TimerRunInProgress(
            mode: state.mode,
            currentSeconds: _now().difference(_started!).inSeconds,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _audio?.dispose();
    await super.close();
  }
}
