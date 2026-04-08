import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/data/models/watcher.dart';
import 'package:life_power_client/data/services/api_service.dart';
import 'package:life_power_client/data/models/charge.dart';
import 'package:life_power_client/data/models/user.dart';

final energyProvider = StateNotifierProvider<EnergyNotifier, EnergyState>((ref) {
  return EnergyNotifier(ref.watch(apiServiceProvider));
});

class EnergyState {
  final EnergyCurrent? currentEnergy;
  final EnergyHistory? history;
  final List<WatcherInfo>? watchers;
  final List<User>? myWatchers;
  final List<CareMessage>? careMessages;
  final int remainingCharges;
  final bool isLoading;
  final String? error;

  EnergyState({
    this.currentEnergy,
    this.history,
    this.watchers,
    this.myWatchers,
    this.careMessages,
    this.remainingCharges = 3,
    this.isLoading = false,
    this.error,
  });

  EnergyState copyWith({
    EnergyCurrent? currentEnergy,
    EnergyHistory? history,
    List<WatcherInfo>? watchers,
    List<User>? myWatchers,
    List<CareMessage>? careMessages,
    int? remainingCharges,
    bool? isLoading,
    String? error,
  }) {
    return EnergyState(
      currentEnergy: currentEnergy ?? this.currentEnergy,
      history: history ?? this.history,
      watchers: watchers ?? this.watchers,
      myWatchers: myWatchers ?? this.myWatchers,
      careMessages: careMessages ?? this.careMessages,
      remainingCharges: remainingCharges ?? this.remainingCharges,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EnergyNotifier extends StateNotifier<EnergyState> {
  final ApiService _apiService;

  EnergyNotifier(this._apiService) : super(EnergyState());

  Future<void> getCurrentEnergy() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final energy = await _apiService.getCurrentEnergy();
      state = state.copyWith(currentEnergy: energy, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getEnergyHistory({int days = 7}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _apiService.getEnergyHistory(days: days);
      state = state.copyWith(history: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createSignal(SignalFeatureCreate signal) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createSignal(signal);
      // 重新获取当前能量
      await getCurrentEnergy();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> chargeEnergy(String method) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.manualCharge(method: method);
      // 重新获取当前能量
      await getCurrentEnergy();
      // 更新剩余充电次数
      state = state.copyWith(
        remainingCharges: response.remainingCharges,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getWatchers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final watchers = await _apiService.getWatching();
      final myWatchers = await _apiService.getMyWatchers();
      state = state.copyWith(
        watchers: watchers,
        myWatchers: myWatchers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getCareMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _apiService.getCareMessages();
      state = state.copyWith(careMessages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendCareMessage(int recipientId, String content) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.sendCareMessage(CareMessageCreate(recipientId: recipientId, content: content));
      // 重新获取消息列表
      await getCareMessages();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> replyCareMessage(int messageId, String emoji) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateCareMessage(messageId, emoji);
      // 重新获取消息列表
      await getCareMessages();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
