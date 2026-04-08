import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

final healthDataServiceProvider = Provider<HealthDataService>((ref) {
  return HealthDataService();
});

class HealthDataService {
  static const _channel = MethodChannel('com.example.life_power/health');
  static const _lastWaterTimeKey = 'last_water_time';
  static const _lastMoodTimeKey = 'last_mood_time';
  bool _isTrackingStarted = false;

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final status = await Permission.activityRecognition.request();
    await Permission.sensors.request(); 
    
    if (status.isGranted) {
      _isTrackingStarted = true;
      final hasUsageStats = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      if (hasUsageStats == false) {
        await _channel.invokeMethod('openUsageStatsSettings');
      }
    }
    return status.isGranted;
  }

  Future<DateTime?> getLastWaterTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastWaterTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> updateLastWaterTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastWaterTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastMoodTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastMoodTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> updateLastMoodTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastMoodTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final activityOk = await Permission.activityRecognition.isGranted;
    final usageOk = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
    return activityOk && (usageOk ?? false);
  }

  Future<HealthSyncData?> syncHealthData() async {
    if (kIsWeb) return null;

    final hasActivityPermission = await Permission.activityRecognition.isGranted;
    if (!hasActivityPermission) return null;

    try {
      int? steps;
      try {
        steps = await _channel.invokeMethod<int>('getTodaySteps');
      } catch (e) {
        steps = 0;
      }

      double? sleepHours;
      final hasUsagePermission = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      
      if (hasUsagePermission == true) {
        sleepHours = await _channel.invokeMethod<double>('getSleepDuration');
        if (sleepHours == 0.0) {
          sleepHours = _getSimulatedSleepHours();
        }
      } else {
        sleepHours = _getSimulatedSleepHours();
      }

      final activeMinutes = _getActiveMinutes(steps ?? 0);

      final data = HealthSyncData(
        steps: steps ?? 0,
        sleepHours: sleepHours,
        activeMinutes: activeMinutes,
        date: DateTime.now(),
        isSimulatedSleep: hasUsagePermission != true || sleepHours == null,
      );
      
      return data;
    } catch (e) {
      print('HealthDataService: Error getting health data: $e');
      return null;
    }
  }

  int _getActiveMinutes(int steps) {
    if (steps <= 0) return 0;
    return (steps / 65).round(); 
  }
  
  double _getSimulatedSleepHours() {
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final dayOfWeek = now.weekday;

    double baseSleepHours;
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      baseSleepHours = 6.8 + (daySeed % 10) / 10.0;
    } else {
      baseSleepHours = 7.8 + (daySeed % 15) / 10.0;
    }

    final offset = ((daySeed * 7) % 10) / 20.0 - 0.25;
    final sleepHours = (baseSleepHours + offset).clamp(5.5, 9.5);

    return double.parse(sleepHours.toStringAsFixed(1));
  }
}

class HealthSyncData {
  final int steps;
  final double? sleepHours;
  final int? activeMinutes;
  final DateTime date;
  final bool isSimulatedSleep;

  HealthSyncData({
    required this.steps,
    this.sleepHours,
    this.activeMinutes,
    required this.date,
    this.isSimulatedSleep = false,
  });
}
