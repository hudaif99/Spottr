import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'presentation/blocs/plans/plans_bloc.dart';
import 'presentation/blocs/workout/workout_bloc.dart';
import 'presentation/blocs/timer/timer_bloc.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI and Hive internally
  await di.initDI();

  runApp(const VoltApp());
}

class VoltApp extends StatelessWidget {
  const VoltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<PlansBloc>()),
        BlocProvider(create: (_) => di.sl<WorkoutBloc>()),
        BlocProvider(create: (_) => di.sl<TimerBloc>()),
      ],
      child: MaterialApp(
        title: 'Volt',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
