abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

class UpdateProfile extends SettingsEvent {
  final String? name;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;

  UpdateProfile({this.name, this.age, this.gender, this.height, this.weight});
}

class UpdateThemeMode extends SettingsEvent {
  final String mode; // 'system', 'light', 'dark'
  UpdateThemeMode(this.mode);
}

class UpdateKeepScreenAwake extends SettingsEvent {
  final bool keepAwake;
  UpdateKeepScreenAwake(this.keepAwake);
}

class UpdatePlayTimerSound extends SettingsEvent {
  final bool playSound;
  UpdatePlayTimerSound(this.playSound);
}
