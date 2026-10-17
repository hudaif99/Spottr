import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/local_database_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LocalDatabaseService _localDbService;

  SettingsBloc(this._localDbService) : super(const SettingsState()) {
    on<SettingsEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _handle(SettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      if (event is LoadSettings) {
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
            replaceProfile: true,
            isSaving: false,
          ),
        );
        return;
      }
      emit(state.copyWith(isSaving: true));
      if (event is UpdateProfile) {
        await _localDbService.saveProfile(
          name: event.name,
          age: event.age,
          gender: event.gender,
          height: event.height,
          weight: event.weight,
        );
        emit(
          state.copyWith(
            userName: event.name,
            userAge: event.age,
            userGender: event.gender,
            userHeight: event.height,
            userWeight: event.weight,
            replaceProfile: true,
            profileRevision: state.profileRevision + 1,
            isSaving: false,
          ),
        );
      } else if (event is UpdateThemeMode) {
        await _localDbService.saveThemeMode(event.mode);
        emit(state.copyWith(themeMode: event.mode, isSaving: false));
      } else if (event is UpdateKeepScreenAwake) {
        await _localDbService.saveKeepScreenAwake(event.keepAwake);
        emit(state.copyWith(keepScreenAwake: event.keepAwake, isSaving: false));
      } else if (event is UpdatePlayTimerSound) {
        await _localDbService.savePlayTimerSound(event.playSound);
        emit(state.copyWith(playTimerSound: event.playSound, isSaving: false));
      }
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Could not save your changes. Try again.',
        ),
      );
    }
  }
}
