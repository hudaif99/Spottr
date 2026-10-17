import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/schedule/schedule_bloc.dart';
import '../blocs/schedule/schedule_event.dart';

class ReminderLifecycle extends StatefulWidget {
  final Widget child;
  const ReminderLifecycle({super.key, required this.child});
  @override
  State<ReminderLifecycle> createState() => _ReminderLifecycleState();
}

class _ReminderLifecycleState extends State<ReminderLifecycle> {
  late final AppLifecycleListener _listener;
  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        context.read<ScheduleBloc>().add(LoadSchedule(refreshReminders: true));
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
