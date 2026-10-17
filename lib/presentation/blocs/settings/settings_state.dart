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
  final bool isSaving;
  final String? errorMessage;
  final int profileRevision;

  const SettingsState({
    this.userName,
    this.userAge,
    this.userGender,
    this.userHeight,
    this.userWeight,
    this.themeMode = 'system',
    this.keepScreenAwake = true,
    this.playTimerSound = true,
    this.isSaving = false,
    this.errorMessage,
    this.profileRevision = 0,
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
    bool? isSaving,
    String? errorMessage,
    int? profileRevision,
    bool replaceProfile = false,
  }) {
    return SettingsState(
      userName: replaceProfile ? userName : userName ?? this.userName,
      userAge: replaceProfile ? userAge : userAge ?? this.userAge,
      userGender: userGender ?? this.userGender,
      userHeight: replaceProfile ? userHeight : userHeight ?? this.userHeight,
      userWeight: replaceProfile ? userWeight : userWeight ?? this.userWeight,
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      playTimerSound: playTimerSound ?? this.playTimerSound,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      profileRevision: profileRevision ?? this.profileRevision,
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
    isSaving,
    errorMessage,
    profileRevision,
  ];
}
