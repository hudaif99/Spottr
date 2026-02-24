import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final String? userName;
  final int? userAge;
  final String? userGender;
  final double? userHeight;
  final double? userWeight;

  final String themeMode;
  final bool keepScreenAwake;
  final bool playTimerSound;

  const SettingsState({
    this.userName,
    this.userAge,
    this.userGender,
    this.userHeight,
    this.userWeight,
    this.themeMode = 'system',
    this.keepScreenAwake = true,
    this.playTimerSound = true,
  });

  SettingsState copyWith({
    String? userName,
    int? userAge,
    String? userGender,
    double? userHeight,
    double? userWeight,
    String? themeMode,
    bool? keepScreenAwake,
    bool? playTimerSound,
  }) {
    return SettingsState(
      userName: userName ?? this.userName,
      userAge: userAge ?? this.userAge,
      userGender: userGender ?? this.userGender,
      userHeight: userHeight ?? this.userHeight,
      userWeight: userWeight ?? this.userWeight,
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      playTimerSound: playTimerSound ?? this.playTimerSound,
    );
  }

  @override
  List<Object?> get props => [
    userName,
    userAge,
    userGender,
    userHeight,
    userWeight,
    themeMode,
    keepScreenAwake,
    playTimerSound,
  ];
}
