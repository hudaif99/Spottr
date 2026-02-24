import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/local_database_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LocalDatabaseService _localDbService;

  SettingsBloc(this._localDbService) : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateKeepScreenAwake>(_onUpdateKeepScreenAwake);
    on<UpdatePlayTimerSound>(_onUpdatePlayTimerSound);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        userName: _localDbService.getUserName(),
        userAge: _localDbService.getUserAge(),
        userGender: _localDbService.getUserGender(),
        userHeight: _localDbService.getUserHeight(),
        userWeight: _localDbService.getUserWeight(),
        themeMode: _localDbService.getThemeMode(),
        keepScreenAwake: _localDbService.getKeepScreenAwake(),
        playTimerSound: _localDbService.getPlayTimerSound(),
      ),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.name != null) await _localDbService.saveUserName(event.name!);
    if (event.age != null) await _localDbService.saveUserAge(event.age!);
    if (event.gender != null)
      await _localDbService.saveUserGender(event.gender!);
    if (event.height != null)
      await _localDbService.saveUserHeight(event.height!);
    if (event.weight != null)
      await _localDbService.saveUserWeight(event.weight!);

    emit(
      state.copyWith(
        userName: event.name,
        userAge: event.age,
        userGender: event.gender,
        userHeight: event.height,
        userWeight: event.weight,
      ),
    );
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _localDbService.saveThemeMode(event.mode);
    emit(state.copyWith(themeMode: event.mode));
  }

  Future<void> _onUpdateKeepScreenAwake(
    UpdateKeepScreenAwake event,
    Emitter<SettingsState> emit,
  ) async {
    await _localDbService.saveKeepScreenAwake(event.keepAwake);
    emit(state.copyWith(keepScreenAwake: event.keepAwake));
  }

  Future<void> _onUpdatePlayTimerSound(
    UpdatePlayTimerSound event,
    Emitter<SettingsState> emit,
  ) async {
    await _localDbService.savePlayTimerSound(event.playSound);
    emit(state.copyWith(playTimerSound: event.playSound));
  }
}
