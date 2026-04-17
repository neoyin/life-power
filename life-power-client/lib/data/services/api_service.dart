import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/data/models/user.dart';
import 'package:life_power_client/data/models/user_settings.dart';
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/data/models/watcher.dart';
import 'package:life_power_client/data/models/user_detail.dart';
import 'package:life_power_client/data/models/charge.dart';
import 'package:life_power_client/data/models/upload.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  final Dio _dio = Dio();
  SharedPreferences? _sharedPrefs;

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

  Future<SharedPreferences> _getPrefs() async {
    _sharedPrefs ??= await SharedPreferences.getInstance();
    return _sharedPrefs!;
  }

  Future<String?> _getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(Constants.storageToken);
  }

  Future<String?> getToken() async {
    return _getToken();
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(Constants.storageRefreshToken);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(Constants.storageToken, token);
  }

  Future<void> _saveRefreshToken(String refreshToken) async {
    final prefs = await _getPrefs();
    await prefs.setString(Constants.storageRefreshToken, refreshToken);
  }

  Future<void> _clearTokens() async {
    final prefs = await _getPrefs();
    await prefs.remove(Constants.storageToken);
    await prefs.remove(Constants.storageRefreshToken);
    await prefs.remove(Constants.storageUserId);
  }

  Future<void> clearAuth() async {
    await _clearTokens();
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
    try {
      final response = await _dio.post(
        Constants.authRegister,
        data: user.toJson(),
      );
      return User.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          throw errorData['detail'];
        }
      }
      throw e;
    }
  }

  Future<User> login(UserAuth auth) async {
    try {
      final response = await _dio.post(
        Constants.authLogin,
        data: auth.toJson(),
      );
      final token = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      await _saveToken(token);
      await _saveRefreshToken(refreshToken);
      return User.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          throw errorData['detail'];
        }
      }
      throw e;
    }
  }

  Future<User> updateProfile({String? fullName, String? avatarUrl}) async {
    final response = await _dio.put(
      Constants.authMe,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );
    return User.fromJson(response.data);
  }

  Future<List<User>> searchUsers(String query) async {
    final response = await _dio.get(
      '/auth/search',
      queryParameters: {'query': query},
    );
    var list = response.data as List;
    return list.map((i) => User.fromJson(i)).toList();
  }

  // 用户设置相关
  Future<UserSettings?> getUserSettings() async {
    try {
      final response = await _dio.get(Constants.authSettings);
      return UserSettings.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<UserSettings> updateUserSettings({
    int? lowEnergyThreshold,
    bool? enableNotifications,
    bool? shareEnergyData,
  }) async {
    final response = await _dio.put(
      Constants.authSettings,
      data: {
        if (lowEnergyThreshold != null)
          'low_energy_threshold': lowEnergyThreshold,
        if (enableNotifications != null)
          'enable_notifications': enableNotifications,
        if (shareEnergyData != null) 'share_energy_data': shareEnergyData,
      },
    );
    return UserSettings.fromJson(response.data);
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

  Future<EnergyHistory> getUserEnergyHistory(int userId, {int days = 7}) async {
    final response = await _dio.get(
      Constants.energyUserHistory,
      queryParameters: {'days': days, 'user_id': userId},
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

  Future<SignalFeature?> getDailySignal() async {
    try {
      final dateStr = DateTime.now().toIso8601String();
      debugPrint('[API] getDailySignal called with date: $dateStr');
      final response = await _dio
          .get(Constants.energySignal, queryParameters: {'date': dateStr});
      debugPrint('[API] getDailySignal response: ${response.data}');
      if (response.data == null) {
        return null;
      }
      return SignalFeature.fromJson(response.data);
    } catch (e) {
      debugPrint('[API] getDailySignal error: $e');
      return null;
    }
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

  Future<UserDetail> getUserDetail(int userId) async {
    final response = await _dio.get('/watchers/user/$userId');
    return UserDetail.fromJson(response.data);
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

  Future<SignalFeature> incrementBreathing() async {
    // 1. Get current signal
    final daily = await getDailySignal();
    final currentSessions = daily?.breathingSessions ?? 0;

    // 2. Create signal with incremented count
    return createSignal(
      SignalFeatureCreate(
        date: DateTime.now(),
        breathingSessions: currentSessions + 1,
      ),
    );
  }

  Future<DailyChargeLimit> getDailyChargeLimit() async {
    final response = await _dio.get(Constants.chargeDailyLimit);
    return DailyChargeLimit.fromJson(response.data);
  }

  Future<PresignedUrlData> getAvatarPresignedUrl({String contentType = 'image/jpeg'}) async {
    final response = await _dio.post(
      '/upload/avatar/presigned-url',
      data: {'content_type': contentType},
    );
    return PresignedUrlData.fromJson(response.data);
  }

  Future<void> uploadToR2({
    required String presignedUrl,
    required Map<String, String> fields,
    required Uint8List bytes,
    required String filename,
  }) async {
    String contentType = 'application/octet-stream';
    if (filename.toLowerCase().endsWith('.png')) {
      contentType = 'image/png';
    } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else if (filename.toLowerCase().endsWith('.webp')) {
      contentType = 'image/webp';
    }

    final dio = Dio();
    dio.options.validateStatus = (status) => status != null && status < 500;

    final response = await dio.put(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  }

  Future<User> updateAvatar(String avatarUrl) async {
    final response = await _dio.put(
      '/auth/me/avatar',
      data: {'avatar_url': avatarUrl},
    );
    return User.fromJson(response.data);
  }

  Future<String> uploadAvatarDirect(Uint8List bytes, String filename, String contentType) async {
    final mimeType = contentType.split('/')[0];
    final subType = contentType.split('/')[1];
    final mediaType = MediaType(mimeType, subType);

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: mediaType,
      ),
    });

    final response = await _dio.post(
      '/upload/avatar/direct-upload',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    return response.data['public_url'] as String;
  }
}
