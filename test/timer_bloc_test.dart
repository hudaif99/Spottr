import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/presentation/blocs/timer/timer_bloc.dart';
import 'package:spottr/presentation/blocs/timer/timer_event.dart';
import 'package:spottr/presentation/blocs/timer/timer_state.dart';

class _SilentSettings extends LocalDatabaseService {
  @override
  bool getPlayTimerSound() => false;
}

void main() {
  test(
    'rest reconciles elapsed background time and cannot go negative',
    () async {
      var now = DateTime(2026, 10, 11, 10);
      final bloc = TimerBloc(_SilentSettings(), now: () => now);
      addTearDown(bloc.close);
      var next = bloc.stream.first;
      bloc.add(const StartRestTimer(90));
      await next;
      now = now.add(const Duration(seconds: 61));
      next = bloc.stream.first;
      bloc.add(RefreshTimer());
      await next;
      expect(bloc.state.currentSeconds, 29);
      now = now.add(const Duration(minutes: 3));
      next = bloc.stream.first;
      bloc.add(RefreshTimer());
      await next;
      expect(bloc.state, isA<TimerRunComplete>());
      expect(bloc.state.currentSeconds, 0);
    },
  );
}
