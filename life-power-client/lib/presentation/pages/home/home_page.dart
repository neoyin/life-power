import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/theme.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/core/logger.dart';
import 'package:life_power_client/data/services/health_data_service.dart';
import 'package:life_power_client/data/services/api_service.dart' as api;
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/providers/auth_provider.dart';
import 'package:life_power_client/presentation/widgets/energy_ring.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';
import 'package:life_power_client/presentation/widgets/main_navigation_bar.dart';
import 'package:life_power_client/presentation/widgets/energy_chart.dart';
import 'package:life_power_client/presentation/widgets/energy_ring_with_trend.dart';
import 'package:life_power_client/presentation/widgets/care_banner.dart';
import 'package:life_power_client/presentation/widgets/skeleton_loading.dart';
import 'package:life_power_client/presentation/widgets/sync_status_indicator.dart';
import 'package:life_power_client/presentation/widgets/suggestion_engine.dart';
import 'dart:async';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  int _todaySteps = 0;
  double _sleepHours = 0.0;
  int _waterIntake = 0;
  int _moodScore = 0;
  bool _isDataLoaded = false;
  DateTime? _lastWaterTime;
  DateTime? _lastMoodTime;
  SyncStatus _syncStatus = SyncStatus.idle;
  List<String> _logMessages = [];
  Timer? _reminderTimer;
  bool _suggestionDismissed = false;
  bool _isWaterCooldown = false;

  late AnimationController _waterAnimController;

  final Map<String, int> _feelings = {
    'feel_super': 10,
    'feel_calm': 7,
    'feel_normal': 5,
    'feel_tired': 3,
    'feel_stressed': 1,
  };

  final List<Map<String, dynamic>> _moodOptions = [
    {
      'key': 'feel_super',
      'score': 10,
      'icon': Icons.sentiment_very_satisfied,
      'color': const Color(0xFF9d4edd),
    },
    {
      'key': 'feel_calm',
      'score': 7,
      'icon': Icons.sentiment_satisfied,
      'color': const Color(0xFF4ea8de),
    },
    {
      'key': 'feel_normal',
      'score': 5,
      'icon': Icons.sentiment_neutral,
      'color': const Color(0xFF006f1d),
    },
    {
      'key': 'feel_tired',
      'score': 3,
      'icon': Icons.sentiment_dissatisfied,
      'color': const Color(0xFFfec330),
    },
    {
      'key': 'feel_stressed',
      'score': 1,
      'icon': Icons.sentiment_very_dissatisfied,
      'color': const Color(0xFF9c4343),
    },
  ];

  void _addLog(String message) {
    // 同时输出到 AppLogger 和本地日志列表
    AppLogger.i('HomePage', message);
    setState(() {
      _logMessages
          .add('[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logMessages.length > 50) _logMessages.removeAt(0);
    });
  }

  @override
  void initState() {
    super.initState();
    _waterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).checkAuthStatus();
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(energyProvider.notifier).getCurrentEnergy();
        ref.read(energyProvider.notifier).getTodaySignal();
        ref.read(energyProvider.notifier).getWatchers();
        ref.read(energyProvider.notifier).getEnergyHistory();
        ref.read(energyProvider.notifier).getCareMessages();
        _loadHealthData();
        _checkReminders();
      }
    });

    _reminderTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _checkReminders();
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _waterAnimController.dispose();
    super.dispose();
  }

  Future<void> _checkReminders() async {
    final lastWater =
        await ref.read(healthDataServiceProvider).getLastWaterTime();
    final lastMood =
        await ref.read(healthDataServiceProvider).getLastMoodTime();
    if (mounted) {
      setState(() {
        _lastWaterTime = lastWater;
        _lastMoodTime = lastMood;
      });
    }
  }

  bool _shouldShowWaterReminder() {
    if (_lastWaterTime == null) return true;
    final now = DateTime.now();
    if (now.hour < 7 || now.hour >= 21) return false;
    return now.difference(_lastWaterTime!).inMinutes >= 15;
  }

  bool _canDrinkWater() {
    if (_lastWaterTime == null) return true;
    return DateTime.now().difference(_lastWaterTime!).inMinutes >= 15;
  }

  bool _shouldShowMoodReminder() {
    final now = DateTime.now();

    final morningStart = DateTime(now.year, now.month, now.day, 7, 30);
    final morningEnd = DateTime(now.year, now.month, now.day, 10, 30);

    final eveningStart = DateTime(now.year, now.month, now.day, 18, 0);
    final eveningEnd = DateTime(now.year, now.month, now.day, 21, 0);

    bool isMorning = now.isAfter(morningStart) && now.isBefore(morningEnd);
    bool isEvening = now.isAfter(eveningStart) && now.isBefore(eveningEnd);

    if (!isMorning && !isEvening) return false;

    if (_lastMoodTime == null) return true;

    final lastTime = _lastMoodTime!;
    if (lastTime.year == now.year &&
        lastTime.month == now.month &&
        lastTime.day == now.day) {
      if (isMorning &&
          lastTime.isAfter(morningStart) &&
          lastTime.isBefore(morningEnd)) return false;
      if (isEvening &&
          lastTime.isAfter(eveningStart) &&
          lastTime.isBefore(eveningEnd)) return false;
    }

    return true;
  }

  Future<void> _loadHealthData() async {
    final healthService = ref.read(healthDataServiceProvider);
    final apiService = ref.read(api.apiServiceProvider);

    await healthService.requestPermissions();
    final healthData = await healthService.syncHealthData();

    // Fetch current day's signal from server to restore water/mood
    final dailySignal = await apiService.getDailySignal();
    debugPrint(
        '[HomePage] _loadData - dailySignal: ${dailySignal?.moodScore}, water: ${dailySignal?.waterIntake}');

    if (mounted) {
      setState(() {
        if (healthData != null) {
          _todaySteps = healthData.steps;
          _sleepHours = healthData.sleepHours ?? 0.0;
        }
        if (dailySignal != null) {
          _waterIntake = dailySignal.waterIntake ?? 0;
          _moodScore = dailySignal.moodScore ?? 0;
          debugPrint(
              '[HomePage] _loadData - setState _moodScore: ${_moodScore}');
        }
        _isDataLoaded = true;
      });
    }
  }

  Future<void> _syncHealthData() async {
    if (_syncStatus == SyncStatus.syncing) return;
    _addLog('HomePage: Starting sync process');
    setState(() => _syncStatus = SyncStatus.syncing);

    try {
      final healthService = ref.read(healthDataServiceProvider);
      final apiService = ref.read(api.apiServiceProvider);

      await healthService.requestPermissions();
      final healthData = await healthService.syncHealthData();

      if (mounted && healthData != null) {
        _addLog(
            'HomePage: Syncing data - steps: ${healthData.steps}, sleepHours: ${healthData.sleepHours}, activeMinutes: ${healthData.activeMinutes}, waterIntake: $_waterIntake, moodScore: $_moodScore');

        await apiService.createSignal(
          SignalFeatureCreate(
            date: healthData.date,
            steps: healthData.steps,
            sleepHours: healthData.sleepHours,
            activeMinutes: healthData.activeMinutes,
            waterIntake: _waterIntake,
            moodScore: _moodScore > 0 ? _moodScore : null,
          ),
        );
        await ref.read(energyProvider.notifier).getCurrentEnergy();

        setState(() {
          _todaySteps = healthData.steps;
          _sleepHours = healthData.sleepHours ?? 0.0;
          _syncStatus = SyncStatus.success;
        });
        _addLog(
            'HomePage: Sync completed successfully - steps: ${healthData.steps}, sleepHours: ${healthData.sleepHours}');

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _syncStatus == SyncStatus.success) {
            setState(() => _syncStatus = SyncStatus.idle);
          }
        });
      } else {
        _addLog('HomePage: No health data to sync');
        setState(() => _syncStatus = SyncStatus.error);
      }
    } catch (e) {
      _addLog('HomePage: Error during sync: $e');
      setState(() => _syncStatus = SyncStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final energyState = ref.watch(energyProvider);
    if (authState.user == null) return _buildWelcomePage(context);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: _buildAppBar(context, authState, energyState),
      body: Stack(
        children: [
          energyState.currentEnergy == null
              ? const HomePageSkeleton()
              : _buildEnergyContent(context, energyState),
          if (energyState.careMessages != null)
            CareBannerManager(
              careMessages: energyState.careMessages ?? [],
              onViewAll: () => Navigator.pushNamed(context, '/care'),
              onMessageTap: (message) {
                Navigator.pushNamed(context, '/care');
              },
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_shouldShowMoodReminder()) ...[
                  _buildFloatingReminder(
                    label: tr('sync_mood'),
                    icon: Icons.blur_on,
                    color: const Color(0xFF9d4edd),
                    onTap: () => _showMoodStatusSelector(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_shouldShowWaterReminder() && _canDrinkWater())
                  _buildFloatingReminder(
                    label: tr('go_drink_water'),
                    icon: Icons.water_drop,
                    color: const Color(0xFF4ea8de),
                    onTap: () => _addWaterWithAnimation(),
                  ),
              ],
            ),
          ),
          _buildWaterFillingOverlay(),
        ],
      ),
      bottomNavigationBar: MainNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildFloatingReminder(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, authState, energyState) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Icon(Icons.bubble_chart, color: const Color(0xFF535f6f)),
          const SizedBox(width: 8),
          Text(tr('app_name'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2a3435))),
        ],
      ),
      actions: [
        _buildCareIcon(energyState),
        _buildUserAvatar(authState),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCareIcon(EnergyState energyState) {
    return Stack(
      children: [
        IconButton(
            icon: const Icon(Icons.favorite_outline, color: Color(0xFF727d7e)),
            onPressed: () => Navigator.pushNamed(context, '/care')),
        if ((energyState.careMessages ?? []).isNotEmpty)
          Positioned(
              right: 12,
              top: 12,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFfe8983), shape: BoxShape.circle))),
      ],
    );
  }

  Widget _buildUserAvatar(authState) {
    final username =
        authState.user?.fullName ?? authState.user?.username ?? 'User';
    final avatarUrl = authState.user?.avatarUrl;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/settings'),
      child: WatcherAvatar(
        name: username,
        imageUrl: avatarUrl,
        size: 32,
        showGradientBorder: false,
      ),
    );
  }

  Widget _buildEnergyContent(BuildContext context, EnergyState energyState) {
    final energy = energyState.currentEnergy!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildEnergyRingSection(context, energy),
          const SizedBox(height: 32),
          _buildSuggestionCard(context, energyState),
          const SizedBox(height: 16),
          _buildWatcherSection(context, energyState),
          const SizedBox(height: 32),
          _buildInsightBentoGrid(context, energy),
          const SizedBox(height: 32),
          _buildHistorySection(context, energyState),
          const SizedBox(height: 32),
          _buildChargeButton(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEnergyRingSection(BuildContext context, EnergyCurrent energy) {
    final history = ref.read(energyProvider).history;
    final trendChange = EnergyTrendCalculator.calculateTrendChange(
      history?.snapshots ?? [],
      energy.score,
    );
    final insight = EnergyTrendCalculator.generateInsight(
      energy.score,
      energy.level,
      trendChange,
    );

    return EnergyRingWithTrend(
      score: energy.score,
      level: energy.level,
      trendChange: trendChange,
      insight: insight,
      onTap: () => _showEnergyDetail(context, energy, trendChange, insight),
    );
  }

  void _showEnergyDetail(BuildContext context, EnergyCurrent energy,
      int? trendChange, String? insight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFfafafa),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFd0d5d6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('energy_detail_title'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(tr('current_score'), '${energy.score}%'),
            const SizedBox(height: 12),
            _buildDetailRow(tr('energy_level'), tr(energy.level.toLowerCase())),
            const SizedBox(height: 12),
            if (trendChange != null)
              _buildDetailRow(
                tr('trend_vs_yesterday'),
                trendChange >= 0 ? '+$trendChange%' : '$trendChange%',
              ),
            const SizedBox(height: 12),
            if (insight != null) _buildDetailRow(tr('insight'), insight),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2a3435),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tr('got_it'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF727d7e),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2a3435),
          ),
        ),
      ],
    );
  }

  Widget _buildWatcherSection(BuildContext context, EnergyState energyState) {
    final myWatchers = energyState.myWatchers ?? [];
    return Column(
      children: [
        WatcherAvatarList(
          watchers: myWatchers.isEmpty
              ? [
                  WatcherAvatarData(name: 'Demo 1'),
                  WatcherAvatarData(name: 'Demo 2')
                ]
              : myWatchers
                  .map((w) => WatcherAvatarData(
                      name: w.username, imageUrl: w.avatarUrl))
                  .toList(),
          maxDisplay: 4,
          avatarSize: 40,
          onAvatarTap: myWatchers.isEmpty
              ? null
              : (index) {
                  if (index < myWatchers.length) {
                    _navigateToWatcherDetail(context, myWatchers[index]);
                  }
                },
        ),
        const SizedBox(height: 16),
        Text(
            '${energyState.currentEnergy?.watcherCount ?? 0} ${tr('people_watching_you')}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF566162))),
      ],
    );
  }

  void _navigateToWatcherDetail(BuildContext context, dynamic user) {
    Navigator.pushNamed(
      context,
      '/watcher_detail',
      arguments: {
        'userId': user.id,
      },
    );
  }

  Widget _buildSuggestionCard(BuildContext context, EnergyState energyState) {
    if (_suggestionDismissed) return const SizedBox.shrink();

    final energy = energyState.currentEnergy;
    if (energy == null) return const SizedBox.shrink();

    final SignalFeature? todaySignal = energyState.todaySignal;
    final unreadMessages = (energyState.careMessages ?? [])
        .where((m) => m.emojiResponse == null)
        .length;

    final suggestions = SuggestionEngine.generateSuggestions(
      energy: energy,
      todaySignal: todaySignal,
      unreadMessages: unreadMessages,
    );

    if (suggestions.isEmpty) return const SizedBox.shrink();

    final suggestion = suggestions.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            suggestion.color.withOpacity(0.15),
            suggestion.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: suggestion.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: suggestion.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              suggestion.icon,
              color: suggestion.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a3435),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  suggestion.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF566162),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            SuggestionEngine.getIconEmoji(suggestion.type),
            style: const TextStyle(fontSize: 28),
          ),
        ],
      ),
    );
  }

  void _dismissSuggestion() {
    setState(() => _suggestionDismissed = true);
  }

  Widget _buildInsightBentoGrid(BuildContext context, EnergyCurrent energy) {
    return Column(
      children: [
        _buildImportantCardsRow(energy),
        const SizedBox(height: 12),
        _buildBasicCardsRow(),
      ],
    );
  }

  Widget _buildImportantCardsRow(EnergyCurrent energy) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFff4d6d).withOpacity(0.1),
                  const Color(0xFFff4d6d).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFff4d6d).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFff4d6d).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.monitor_heart,
                        color: Color(0xFFff4d6d),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tr('pulse_stability').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF727d7e),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${(energy.confidence * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2a3435),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('pulse_stability_desc'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF727d7e),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.getEnergyColor(energy.level).withOpacity(0.1),
                  AppTheme.getEnergyColor(energy.level).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.getEnergyColor(energy.level).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.getEnergyColor(energy.level)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppTheme.getEnergyColor(energy.level),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tr('energy_status').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF727d7e),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEnergyLevelLabel(energy.level),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.getEnergyColor(energy.level),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('current_energy').toLowerCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF727d7e),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicCardsRow() {
    return Row(
      children: [
        Expanded(child: _buildStepsCard()),
        const SizedBox(width: 8),
        Expanded(child: _buildSleepCard()),
        const SizedBox(width: 8),
        Expanded(child: _buildWaterCard()),
        const SizedBox(width: 8),
        Expanded(child: _buildMoodCard()),
      ],
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFf0f4f5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk,
                  color: const Color(0xFF006f1d), size: 18),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _todaySteps >= Constants.targetSteps
                      ? const Color(0xFF006f1d)
                      : const Color(0xFF727d7e),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_todaySteps',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 2),
              Text(
                '/ ${Constants.targetSteps}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF727d7e)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tr('steps'),
            style: const TextStyle(fontSize: 9, color: Color(0xFF727d7e)),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFf0f4f5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime, color: Color(0xFFfec330), size: 18),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFfec330),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_sleepHours.toStringAsFixed(1)}h',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a3435),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr('sleep'),
            style: TextStyle(fontSize: 9, color: Color(0xFF727d7e)),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    final isDisabled = _isWaterCooldown || _waterIntake >= 2000;
    return GestureDetector(
      onTap: isDisabled ? null : _addWaterWithAnimation,
      child: AbsorbPointer(
        absorbing: isDisabled,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color:
                isDisabled ? const Color(0xFFf7f7f7) : const Color(0xFFf0f4f5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop,
                    color: isDisabled
                        ? const Color(0xFFc5c9ca)
                        : const Color(0xFF4ea8de),
                    size: 18,
                  ),
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _waterIntake >= 2000
                          ? const Color(0xFF4ea8de)
                          : const Color(0xFF727d7e),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_waterIntake}ml',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDisabled
                      ? const Color(0xFFa8adaf)
                      : const Color(0xFF2a3435),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tr('water'),
                style: TextStyle(
                  fontSize: 9,
                  color: isDisabled
                      ? const Color(0xFFb8bcbc)
                      : const Color(0xFF727d7e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodCard() {
    return GestureDetector(
      onTap: _showMoodStatusSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFf0f4f5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.blur_on, color: Color(0xFF9d4edd), size: 18),
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _moodScore >= 5
                        ? const Color(0xFF9d4edd)
                        : const Color(0xFF727d7e),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getMoodEmoji(),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              tr('mood'),
              style: TextStyle(fontSize: 9, color: Color(0xFF727d7e)),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji() {
    if (_moodScore == 0) return '—';
    if (_moodScore >= 8) return '😊';
    if (_moodScore >= 5) return '😐';
    if (_moodScore >= 3) return '😔';
    return '😢';
  }

  Widget _buildMainInsightCard() {
    return GestureDetector(
      onTap: _syncStatus == SyncStatus.syncing ? null : _syncHealthData,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF2a3435).withOpacity(0.06),
                  blurRadius: 40,
                  offset: const Offset(0, 20))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFff4d6d), size: 28),
                _buildSyncStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Text(tr('heart_mind_harmony'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a3435))),
            const SizedBox(height: 8),
            Text(tr('heart_mind_harmony_desc'),
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF566162), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;
    Widget? trailing;

    switch (_syncStatus) {
      case SyncStatus.idle:
        bgColor = const Color(0xFFf0f4f5);
        textColor = const Color(0xFF727d7e);
        text = tr('sync_idle');
        break;
      case SyncStatus.syncing:
        bgColor = const Color(0xFF4ea8de).withOpacity(0.1);
        textColor = const Color(0xFF4ea8de);
        text = tr('sync_syncing');
        trailing = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textColor,
          ),
        );
        break;
      case SyncStatus.success:
        bgColor = const Color(0xFF006f1d).withOpacity(0.1);
        textColor = const Color(0xFF006f1d);
        text = tr('sync_success');
        trailing = Icon(Icons.check_circle, size: 14, color: textColor);
        break;
      case SyncStatus.error:
        bgColor = const Color(0xFF9c4343).withOpacity(0.1);
        textColor = const Color(0xFF9c4343);
        text = tr('sync_error');
        trailing = Icon(Icons.refresh, size: 14, color: textColor);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            trailing,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFf0f4f5),
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF566162),
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435))),
        ],
      ),
    );
  }

  String _getCurrentMoodText() {
    debugPrint('[HomePage] _getCurrentMoodText - _moodScore: $_moodScore');
    if (_moodScore == 0) return tr('not_set');
    return tr(_feelings.entries
        .firstWhere((e) => e.value == _moodScore,
            orElse: () => _feelings.entries.first)
        .key);
  }

  void _showMoodStatusSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('current_mood_prompt'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ..._moodOptions.map((option) {
                final isSelected = _moodScore == option['score'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (option['color'] as Color).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (option['color'] as Color)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? (option['color'] as Color)
                          : const Color(0xFF727d7e),
                      size: 28,
                    ),
                    title: Text(
                      tr(option['key'] as String),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (option['color'] as Color)
                            : const Color(0xFF2a3435),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: option['color'] as Color)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() => _moodScore = option['score'] as int);
                      await ref
                          .read(healthDataServiceProvider)
                          .updateLastMoodTime();
                      await _checkReminders();
                      _syncManualData(_waterIntake, option['score'] as int);
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterFillingOverlay() {
    return AnimatedBuilder(
      animation: _waterAnimController,
      builder: (context, child) {
        if (!_waterAnimController.isAnimating) return const SizedBox.shrink();
        return Positioned.fill(
            child: Center(
                child: Opacity(
                    opacity: 1.0 - _waterAnimController.value,
                    child: Container(
                        width: 100 + 200 * _waterAnimController.value,
                        height: 100 + 200 * _waterAnimController.value,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4ea8de).withOpacity(0.3)),
                        child: const Center(
                            child: Icon(Icons.water_drop,
                                size: 80, color: Color(0xFF4ea8de)))))));
      },
    );
  }

  Future<void> _addWaterWithAnimation() async {
    if (_isWaterCooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('water_cooldown')),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _waterAnimController.forward(from: 0);
    final newIntake = _waterIntake + 250;
    setState(() {
      _waterIntake = newIntake;
      _isWaterCooldown = true;
    });
    await ref.read(healthDataServiceProvider).updateLastWaterTime();
    await _checkReminders();
    await _syncManualData(newIntake, _moodScore);

    Future.delayed(const Duration(minutes: 15), () {
      if (mounted) {
        setState(() => _isWaterCooldown = false);
      }
    });
  }

  Future<void> _syncManualData(int water, int mood) async {
    debugPrint(
        '[HomePage] _syncManualData called - water: $water, mood: $mood');

    if (!_isDataLoaded) {
      await _loadHealthData();
    }

    final healthService = ref.read(healthDataServiceProvider);
    final apiService = ref.read(api.apiServiceProvider);

    final healthData = await healthService.syncHealthData();
    debugPrint('[HomePage] _syncManualData - healthData: ${healthData?.steps}');

    if (healthData != null) {
      final latestSignal = await apiService.getDailySignal();
      debugPrint(
          '[HomePage] _syncManualData - latestSignal mood: ${latestSignal?.moodScore}');

      _addLog(
          'HomePage: Manual sync data - steps: ${healthData.steps}, sleepHours: ${healthData.sleepHours}, activeMinutes: ${healthData.activeMinutes}, waterIntake: $water, moodScore: $mood');

      await apiService.createSignal(
        SignalFeatureCreate(
          date: healthData.date,
          steps: healthData.steps,
          sleepHours: healthData.sleepHours,
          activeMinutes: healthData.activeMinutes,
          waterIntake: water,
          moodScore: mood > 0 ? mood : (latestSignal?.moodScore),
        ),
      );
      debugPrint(
          '[HomePage] _syncManualData - createSignal called with moodScore: ${mood > 0 ? mood : (latestSignal?.moodScore)}');

      await ref.read(energyProvider.notifier).getCurrentEnergy();

      _addLog('HomePage: Manual sync completed successfully');
    } else {
      debugPrint(
          '[HomePage] _syncManualData - healthData is null, trying with minimal data');
      // 即使没有健康数据，也尝试同步 mood 和 water
      await apiService.createSignal(
        SignalFeatureCreate(
          date: DateTime.now(),
          waterIntake: water,
          moodScore: mood > 0 ? mood : null,
        ),
      );
      debugPrint(
          '[HomePage] _syncManualData - createSignal called with waterIntake: $water, moodScore: ${mood > 0 ? mood : null}');
    }
  }

  Widget _buildHistorySection(BuildContext context, EnergyState energyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('energy_history').toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF566162),
                letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]),
          child: EnergyChart(
              history: energyState.history ?? EnergyHistory(snapshots: [])),
        ),
      ],
    );
  }

  Widget _buildChargeButton(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2a3435),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            onPressed: () => Navigator.pushNamed(context, '/charge'),
            child: Text(tr('charge_now'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold))));
  }

  String _getEnergyLevelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
      case 'energetic':
        return tr('energy_high');
      case 'medium':
      case 'balanced':
        return tr('energy_medium');
      case 'low':
      case 'low battery':
        return tr('energy_low');
      default:
        return level;
    }
  }

  Widget _buildWelcomePage(BuildContext context) {
    return Scaffold(
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.bolt, size: 80),
      Text(tr('app_name'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: Text(tr('login')))
    ])));
  }
}
