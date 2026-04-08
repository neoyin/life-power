import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/data/models/user_settings.dart';
import 'package:life_power_client/data/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier(ref.watch(apiServiceProvider));
});

class UserSettingsState {
  final UserSettings? settings;
  final bool isLoading;
  final bool isSyncing;
  final String? error;

  UserSettingsState({
    this.settings,
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
  });

  UserSettingsState copyWith({
    UserSettings? settings,
    bool? isLoading,
    bool? isSyncing,
    String? error,
  }) {
    return UserSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error ?? this.error,
    );
  }
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  final ApiService _apiService;

  UserSettingsNotifier(this._apiService) : super(UserSettingsState());

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    final prefs = await SharedPreferences.getInstance();
    final cachedThreshold = prefs.getInt(Constants.storageLowEnergyThreshold);
    final cachedShareEnergy = prefs.getBool(Constants.storageShareEnergyData);
    final cachedNotifications = prefs.getBool(Constants.storageEnableNotifications);

    if (cachedThreshold != null || cachedShareEnergy != null || cachedNotifications != null) {
      state = state.copyWith(
        settings: UserSettings(
          id: 0,
          userId: 0,
          lowEnergyThreshold: cachedThreshold ?? 30,
          enableNotifications: cachedNotifications ?? true,
          shareEnergyData: cachedShareEnergy ?? true,
        ),
        isLoading: false,
      );
    }

    state = state.copyWith(isSyncing: true);
    try {
      final settings = await _apiService.getUserSettings();
      if (settings != null) {
        await _cacheSettings(settings);
        state = state.copyWith(settings: settings, isSyncing: false);
      } else {
        state = state.copyWith(isSyncing: false);
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  Future<void> updateSettings({
    int? lowEnergyThreshold,
    bool? enableNotifications,
    bool? shareEnergyData,
  }) async {
    final currentSettings = state.settings;
    if (currentSettings != null) {
      final newSettings = UserSettings(
        id: currentSettings.id,
        userId: currentSettings.userId,
        lowEnergyThreshold: lowEnergyThreshold ?? currentSettings.lowEnergyThreshold,
        enableNotifications: enableNotifications ?? currentSettings.enableNotifications,
        shareEnergyData: shareEnergyData ?? currentSettings.shareEnergyData,
      );
      state = state.copyWith(settings: newSettings);
      await _cacheSettings(newSettings);
    }

    state = state.copyWith(isSyncing: true);
    try {
      final settings = await _apiService.updateUserSettings(
        lowEnergyThreshold: lowEnergyThreshold,
        enableNotifications: enableNotifications,
        shareEnergyData: shareEnergyData,
      );
      await _cacheSettings(settings);
      state = state.copyWith(settings: settings, isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  Future<void> _cacheSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Constants.storageLowEnergyThreshold, settings.lowEnergyThreshold);
    await prefs.setBool(Constants.storageShareEnergyData, settings.shareEnergyData);
    await prefs.setBool(Constants.storageEnableNotifications, settings.enableNotifications);
  }
}
