class Constants {
  // API 端点
  //static const String baseUrl = 'http://localhost:8000';
  //static const String baseUrl = 'https://power-api-production.up.railway.app/';
  static const String baseUrl = 'http://10.140.68.238:8000/';
  // API 路径
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authSettings = '/auth/settings';
  static const String energyCurrent = '/energy/current';
  static const String energyHistory = '/energy/history';
  static const String energySignal = '/energy/signals/daily';
  static const String energyUserHistory = '/energy/history';
  static const String watcherInvite = '/watchers/invite';
  static const String watcherResponse = '/watchers/response';
  static const String watcherMyWatchers = '/watchers/my-watchers';
  static const String watcherWatching = '/watchers/watching';
  static const String watcherPending = '/watchers/pending';
  static const String careMessage = '/care/messages';
  static const String careMessageSent = '/care/messages/sent';
  static const String chargeManual = '/charge/manual';
  static const String chargeDailyLimit = '/charge/daily-limit';
  static const String chargeHistory = '/charge/history';

  // 能量等级
  static const String energyHigh = 'high';
  static const String energyMedium = 'medium';
  static const String energyLow = 'low';

  // 充电限制
  static const int maxDailyCharges = 3;

  // 存储键
  static const String storageToken = 'auth_token';
  static const String storageRefreshToken = 'refresh_token';
  static const String storageUserId = 'user_id';
  static const String storageLowEnergyThreshold = 'low_energy_threshold';
  static const String storageShareEnergyData = 'share_energy_data';
  static const String storageEnableNotifications = 'enable_notifications';

  // 动画时长
  static const Duration animationDuration = Duration(milliseconds: 500);
  static const Duration breathingAnimationDuration = Duration(seconds: 15);

  // 健康目标
  static const int targetSteps = 8000;
  static const double targetSleep = 8.0;
}
