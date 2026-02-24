import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/datasources/local_database_service.dart';
import 'timer_event.dart';
import 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final LocalDatabaseService _localDbService;
  StreamSubscription<int>? _tickerSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  TimerBloc(this._localDbService) : super(const TimerInitial()) {
    on<StartRestTimer>(_onStartRestTimer);
    on<StartStopwatch>(_onStartStopwatch);
    on<PauseTimer>(_onPauseTimer);
    on<ResumeTimer>(_onResumeTimer);
    on<ResetTimer>(_onResetTimer);
    on<TickTimer>(_onTickTimer);
  }

  void _onStartRestTimer(StartRestTimer event, Emitter<TimerState> emit) {
    emit(
      TimerRunInProgress(
        mode: TimerMode.countdown,
        currentSeconds: event.durationSeconds,
        totalDurationSeconds: event.durationSeconds,
      ),
    );
    _tickerSubscription?.cancel();
    _tickerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => 1)
        .listen((_) {
          if (state.isRunning && state.mode == TimerMode.countdown) {
            add(TickTimer(state.currentSeconds - 1));
          }
        });
  }

  void _onStartStopwatch(StartStopwatch event, Emitter<TimerState> emit) {
    emit(
      const TimerRunInProgress(mode: TimerMode.stopwatch, currentSeconds: 0),
    );
    _tickerSubscription?.cancel();
    _tickerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => 1)
        .listen((_) {
          if (state.isRunning && state.mode == TimerMode.stopwatch) {
            add(TickTimer(state.currentSeconds + 1));
          }
        });
  }

  void _onPauseTimer(PauseTimer event, Emitter<TimerState> emit) {
    if (state is TimerRunInProgress) {
      _tickerSubscription?.pause();
      emit(
        TimerRunPause(
          mode: state.mode,
          currentSeconds: state.currentSeconds,
          totalDurationSeconds: state.totalDurationSeconds,
        ),
      );
    }
  }

  void _onResumeTimer(ResumeTimer event, Emitter<TimerState> emit) {
    if (state is TimerRunPause) {
      _tickerSubscription?.resume();
      emit(
        TimerRunInProgress(
          mode: state.mode,
          currentSeconds: state.currentSeconds,
          totalDurationSeconds: state.totalDurationSeconds,
        ),
      );
    }
  }

  void _onResetTimer(ResetTimer event, Emitter<TimerState> emit) {
    _tickerSubscription?.cancel();
    emit(const TimerInitial());
  }

  void _onTickTimer(TickTimer event, Emitter<TimerState> emit) {
    if (state.mode == TimerMode.countdown) {
      if (event.elapsedSeconds > 0) {
        if (event.elapsedSeconds == 3 && _localDbService.getPlayTimerSound()) {
          // Play the 3-beep sound when 3 seconds remain, to sync with the countdown
          _audioPlayer.setVolume(1.0).then((_) {
            _audioPlayer
                .play(AssetSource('sounds/timer_done.mp3'))
                .catchError((_) {});
          });
        }
        emit(
          TimerRunInProgress(
            mode: state.mode,
            currentSeconds: event.elapsedSeconds,
            totalDurationSeconds: state.totalDurationSeconds,
          ),
        );
      } else {
        _tickerSubscription?.cancel();
        if (_localDbService.getPlayTimerSound()) {
          HapticFeedback.heavyImpact();
        }
        emit(
          TimerRunComplete(
            mode: state.mode,
            totalDurationSeconds: state.totalDurationSeconds,
          ),
        );
      }
    } else if (state.mode == TimerMode.stopwatch) {
      emit(
        TimerRunInProgress(
          mode: state.mode,
          currentSeconds: event.elapsedSeconds,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
