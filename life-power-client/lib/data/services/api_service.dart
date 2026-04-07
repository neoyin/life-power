import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/data/models/user.dart';
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/data/models/watcher.dart';
import 'package:life_power_client/data/models/charge.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  final Dio _dio = Dio();
  SharedPreferences? _prefs;

  ApiService() {
    _dio.options.baseUrl = Constants.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token 过期，尝试刷新
          final refreshToken = await _getRefreshToken();
          if (refreshToken != null) {
            try {
              final response = await _dio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newToken = response.data['access_token'];
              await _saveToken(newToken);
              // 重试原请求
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              // 刷新失败，跳转到登录
              await _clearTokens();
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<String?> _getToken() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(Constants.storageToken);
  }

  Future<String?> _getRefreshToken() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(Constants.storageRefreshToken);
  }

  Future<void> _saveToken(String token) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(Constants.storageToken, token);
  }

  Future<void> _saveRefreshToken(String refreshToken) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(Constants.storageRefreshToken, refreshToken);
  }

  Future<void> _clearTokens() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(Constants.storageToken);
    await _prefs!.remove(Constants.storageRefreshToken);
    await _prefs!.remove(Constants.storageUserId);
  }

  void clearAuth() {
    _clearTokens();
  }

  // 认证相关
  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get(Constants.authMe);
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<User> register(UserRegister user) async {
    final response = await _dio.post(
      Constants.authRegister,
      data: user.toJson(),
    );
    return User.fromJson(response.data);
  }

  Future<User> login(UserAuth auth) async {
    final response = await _dio.post(
      Constants.authLogin,
      data: auth.toJson(),
    );
    final token = response.data['access_token'];
    final refreshToken = response.data['refresh_token'];
    await _saveToken(token);
    await _saveRefreshToken(refreshToken);
    return User.fromJson(response.data);
  }

  // 能量相关
  Future<EnergyCurrent> getCurrentEnergy() async {
    final response = await _dio.get(Constants.energyCurrent);
    return EnergyCurrent.fromJson(response.data);
  }

  Future<EnergyHistory> getEnergyHistory({int days = 7}) async {
    final response = await _dio.get(
      Constants.energyHistory,
      queryParameters: {'days': days},
    );
    return EnergyHistory.fromJson(response.data);
  }

  Future<SignalFeature> createSignal(SignalFeatureCreate signal) async {
    final response = await _dio.post(
      Constants.energySignal,
      data: signal.toJson(),
    );
    return SignalFeature.fromJson(response.data);
  }

  // 守望者相关
  Future<WatcherRelation> inviteWatcher(WatcherRelationCreate relation) async {
    final response = await _dio.post(
      Constants.watcherInvite,
      data: relation.toJson(),
    );
    return WatcherRelation.fromJson(response.data);
  }

  Future<WatcherRelation> respondToWatcherRequest(
      int relationId, String status) async {
    final response = await _dio.put(
      '${Constants.watcherResponse}/$relationId',
      data: WatcherRelationUpdate(status: status).toJson(),
    );
    return WatcherRelation.fromJson(response.data);
  }

  Future<List<User>> getMyWatchers() async {
    final response = await _dio.get(Constants.watcherMyWatchers);
    var list = response.data as List;
    return list.map((i) => User.fromJson(i)).toList();
  }

  Future<List<WatcherInfo>> getWatching() async {
    final response = await _dio.get(Constants.watcherWatching);
    var list = response.data as List;
    return list.map((i) => WatcherInfo.fromJson(i)).toList();
  }

  Future<List<WatcherRelation>> getPendingRequests() async {
    final response = await _dio.get(Constants.watcherPending);
    var list = response.data as List;
    return list.map((i) => WatcherRelation.fromJson(i)).toList();
  }

  // 关怀消息相关
  Future<CareMessage> sendCareMessage(CareMessageCreate message) async {
    final response = await _dio.post(
      Constants.careMessage,
      data: message.toJson(),
    );
    return CareMessage.fromJson(response.data);
  }

  Future<CareMessage> updateCareMessage(int messageId, String emoji) async {
    final response = await _dio.put(
      '${Constants.careMessage}/$messageId',
      data: CareMessageUpdate(emojiResponse: emoji).toJson(),
    );
    return CareMessage.fromJson(response.data);
  }

  Future<List<CareMessage>> getCareMessages() async {
    final response = await _dio.get(Constants.careMessage);
    var list = response.data as List;
    return list.map((i) => CareMessage.fromJson(i)).toList();
  }

  Future<List<CareMessage>> getSentMessages() async {
    final response = await _dio.get(Constants.careMessageSent);
    var list = response.data as List;
    return list.map((i) => CareMessage.fromJson(i)).toList();
  }

  // 充电相关
  Future<ChargeResponse> manualCharge({String method = 'manual'}) async {
    final response = await _dio.post(
      Constants.chargeManual,
      queryParameters: {'method': method},
    );
    return ChargeResponse.fromJson(response.data);
  }

  Future<DailyChargeLimit> getDailyChargeLimit() async {
    final response = await _dio.get(Constants.chargeDailyLimit);
    return DailyChargeLimit.fromJson(response.data);
  }
}
