import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'presentation/blocs/plans/plans_bloc.dart';
import 'presentation/blocs/plans/plans_event.dart';
import 'presentation/blocs/workout/workout_bloc.dart';
import 'presentation/blocs/workout/workout_event.dart';
import 'presentation/blocs/timer/timer_bloc.dart';
import 'presentation/blocs/history/history_bloc.dart';
import 'presentation/blocs/history/history_event.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
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
        BlocProvider(create: (_) => di.sl<PlansBloc>()..add(LoadPlans())),
        BlocProvider(create: (_) => di.sl<WorkoutBloc>()..add(ResumeWorkout())),
        BlocProvider(create: (_) => di.sl<TimerBloc>()),
        BlocProvider(create: (_) => di.sl<HistoryBloc>()..add(LoadHistory())),
        BlocProvider(create: (_) => di.sl<SettingsBloc>()..add(LoadSettings())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          ThemeMode currentThemeMode;
          switch (settingsState.themeMode) {
            case 'light':
              currentThemeMode = ThemeMode.light;
              break;
            case 'dark':
              currentThemeMode = ThemeMode.dark;
              break;
            case 'system':
            default:
              currentThemeMode = ThemeMode.system;
          }

          return MaterialApp(
            title: 'Volt',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentThemeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
