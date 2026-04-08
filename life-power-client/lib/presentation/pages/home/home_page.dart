import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/theme.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/data/services/health_data_service.dart';
import 'package:life_power_client/data/services/api_service.dart' as api;
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/providers/auth_provider.dart';
import 'package:life_power_client/presentation/widgets/energy_ring.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';
import 'package:life_power_client/presentation/widgets/main_navigation_bar.dart';
import 'package:life_power_client/presentation/widgets/energy_chart.dart';
import 'dart:async';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  int _todaySteps = 0;
  double _sleepHours = 0.0;
  int _waterIntake = 0;
  int _moodScore = 0;
  bool _isDataLoaded = false;
  DateTime? _lastWaterTime;
  DateTime? _lastMoodTime;
  bool _isSyncing = false;
  bool _showDebugLog = false;
  List<String> _logMessages = [];
  Timer? _reminderTimer;
  
  late AnimationController _waterAnimController;

  final Map<String, int> _feelings = {
    'feel_super': 10,
    'feel_calm': 7,
    'feel_normal': 5,
    'feel_tired': 3,
    'feel_stressed': 1,
  };

  void _addLog(String message) {
    setState(() {
      _logMessages.add('[${DateTime.now().toString().substring(11, 19)}] $message');
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
    final lastWater = await ref.read(healthDataServiceProvider).getLastWaterTime();
    final lastMood = await ref.read(healthDataServiceProvider).getLastMoodTime();
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
    return now.difference(_lastWaterTime!).inHours >= 2;
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
    if (lastTime.year == now.year && lastTime.month == now.month && lastTime.day == now.day) {
      if (isMorning && lastTime.isAfter(morningStart) && lastTime.isBefore(morningEnd)) return false;
      if (isEvening && lastTime.isAfter(eveningStart) && lastTime.isBefore(eveningEnd)) return false;
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
    
    if (mounted) {
      setState(() {
        if (healthData != null) {
          _todaySteps = healthData.steps;
          _sleepHours = healthData.sleepHours ?? 0.0;
        }
        if (dailySignal != null) {
          _waterIntake = dailySignal.waterIntake ?? 0;
          _moodScore = dailySignal.moodScore ?? 0;
        }
        _isDataLoaded = true;
      });
    }
  }

  Future<void> _syncHealthData() async {
    if (_isSyncing) return;
    _addLog('HomePage: Starting sync process');
    setState(() => _isSyncing = true);

    try {
      final healthService = ref.read(healthDataServiceProvider);
      final apiService = ref.read(api.apiServiceProvider);

      await healthService.requestPermissions();
      final healthData = await healthService.syncHealthData();
      
      if (mounted && healthData != null) {
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
          _isSyncing = false;
        });
        _addLog('HomePage: Sync completed successfully');
      } else {
        setState(() => _isSyncing = false);
      }
    } catch (e) {
      _addLog('HomePage: Error during sync: $e');
      setState(() => _isSyncing = false);
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
          energyState.isLoading || energyState.currentEnergy == null
              ? const Center(child: CircularProgressIndicator())
              : _buildEnergyContent(context, energyState),
          
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
                if (_shouldShowWaterReminder())
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
          if (_showDebugLog) _buildDebugOverlay(context),
        ],
      ),
      bottomNavigationBar: MainNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildFloatingReminder({
    required String label, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
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

  PreferredSizeWidget _buildAppBar(BuildContext context, authState, energyState) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.bubble_chart, color: const Color(0xFF535f6f)),
          const SizedBox(width: 8),
          Text(tr('app_name'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2a3435))),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.bug_report, color: Color(0xFF727d7e)), onPressed: () => setState(() => _showDebugLog = !_showDebugLog)),
        _buildCareIcon(energyState),
        _buildUserAvatar(authState),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCareIcon(EnergyState energyState) {
    return Stack(
      children: [
        IconButton(icon: const Icon(Icons.favorite_outline, color: Color(0xFF727d7e)), onPressed: () => Navigator.pushNamed(context, '/care')),
        if ((energyState.careMessages ?? []).isNotEmpty)
          Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFfe8983), shape: BoxShape.circle))),
      ],
    );
  }

  Widget _buildUserAvatar(authState) {
    return CircleAvatar(radius: 16, backgroundColor: const Color(0xFFd9e5e6), child: Text(authState.user?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF535f6f))));
  }

  Widget _buildEnergyContent(BuildContext context, EnergyState energyState) {
    final energy = energyState.currentEnergy!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildEnergyRingSection(context, energy),
          const SizedBox(height: 48),
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
    final energyColor = AppTheme.getEnergyColor(energy.level);
    return SizedBox(
      width: 288,
      height: 288,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: energy.score / 100,
              strokeWidth: 14,
              backgroundColor: const Color(0xFFd9e5e6).withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(energyColor),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${energy.score}', style: const TextStyle(fontSize: 88, fontWeight: FontWeight.w800, color: Color(0xFF2a3435), height: 1)),
                  const Text('%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF475363))),
                ],
              ),
              const SizedBox(height: 8),
              Text(tr('current_energy').toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF566162), letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatcherSection(BuildContext context, EnergyState energyState) {
    return Column(
      children: [
        WatcherAvatarList(
          watchers: (energyState.myWatchers ?? []).isEmpty 
            ? [WatcherAvatarData(name: 'Demo 1'), WatcherAvatarData(name: 'Demo 2')]
            : energyState.myWatchers!.map((w) => WatcherAvatarData(name: w.username, imageUrl: w.avatarUrl)).toList(),
          maxDisplay: 4,
          avatarSize: 40,
        ),
        const SizedBox(height: 16),
        Text('${energyState.currentEnergy?.watcherCount ?? 0} ${tr('people_watching_you')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF566162))),
      ],
    );
  }

  Widget _buildInsightBentoGrid(BuildContext context, EnergyCurrent energy) {
    return Column(
      children: [
        GestureDetector(onTap: () => _syncHealthData(), child: _buildMainInsightCard()),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInsightCard(icon: Icons.monitor_heart, iconColor: const Color(0xFFff4d6d), title: tr('pulse_stability'), value: '${(energy.confidence * 100).round()}%')),
            const SizedBox(width: 16),
            Expanded(child: _buildInsightCard(icon: Icons.auto_awesome, iconColor: const Color(0xFFff4d6d), title: tr('aura_sync'), value: _getAuraSyncStatus(energy.level))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStepsCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildSleepCard()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildWaterCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildMoodCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildMainInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF2a3435).withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 20))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.favorite, color: Color(0xFFff4d6d), size: 28),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFff4d6d).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(tr('synchronized'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFff4d6d), letterSpacing: 1))),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('heart_mind_harmony'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2a3435))),
          const SizedBox(height: 8),
          Text(tr('heart_mind_harmony_desc'), style: const TextStyle(fontSize: 14, color: Color(0xFF566162), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildInsightCard({required IconData icon, required Color iconColor, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFf0f4f5), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF566162), letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2a3435))),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFf0f4f5), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_walk, color: Color(0xFF006f1d), size: 24),
          const SizedBox(height: 12),
          Text(tr('peak_flow').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF566162))),
          const SizedBox(height: 8),
          Text('$_todaySteps', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2a3435))),
          const SizedBox(height: 4),
          Text('/ ${Constants.targetSteps} ${tr('steps')}', style: const TextStyle(fontSize: 12, color: Color(0xFF566162))),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFf0f4f5), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bedtime, color: Color(0xFFfec330), size: 24),
          const SizedBox(height: 12),
          Text(tr('rest_quality').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF566162))),
          const SizedBox(height: 8),
          Text('${_sleepHours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2a3435))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFf0f4f5), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.water_drop, color: Color(0xFF4ea8de), size: 24),
          const SizedBox(height: 12),
          Text(tr('water_intake'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF566162))),
          const SizedBox(height: 8),
          Text('$_waterIntake ml', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2a3435))),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_waterIntake / 2000).clamp(0.0, 1.0), backgroundColor: const Color(0xFFd9e5e6), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ea8de)), minHeight: 6),
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
    return GestureDetector(
      onTap: () => _showMoodStatusSelector(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFf0f4f5), borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.blur_on, color: Color(0xFF9d4edd), size: 24),
            const SizedBox(height: 12),
            Text(tr('mental_state'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF566162))),
            const SizedBox(height: 8),
            Text(_getCurrentMoodText(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2a3435))),
            const SizedBox(height: 8),
            Text(tr('tap_to_change_feel'), style: const TextStyle(fontSize: 9, color: Color(0xFF727d7e))),
          ],
        ),
      ),
    );
  }

  String _getCurrentMoodText() {
    if (_moodScore == 0) return tr('not_set');
    return tr(_feelings.entries.firstWhere((e) => e.value == _moodScore, orElse: () => _feelings.entries.first).key);
  }

  void _showMoodStatusSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('current_mood_prompt'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ..._feelings.entries.map((e) => ListTile(
                title: Text(tr(e.key), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                trailing: _moodScore == e.value ? const Icon(Icons.check_circle, color: Color(0xFF9d4edd)) : null,
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _moodScore = e.value);
                  await ref.read(healthDataServiceProvider).updateLastMoodTime();
                  await _checkReminders();
                  _syncManualData(_waterIntake, e.value);
                },
              )).toList(),
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
        return Positioned.fill(child: Center(child: Opacity(opacity: 1.0 - _waterAnimController.value, child: Container(width: 100 + 200 * _waterAnimController.value, height: 100 + 200 * _waterAnimController.value, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4ea8de).withOpacity(0.3)), child: const Center(child: Icon(Icons.water_drop, size: 80, color: Color(0xFF4ea8de)))))));
      },
    );
  }

  Future<void> _addWaterWithAnimation() async {
    _waterAnimController.forward(from: 0);
    final newIntake = _waterIntake + 250;
    setState(() => _waterIntake = newIntake);
    await ref.read(healthDataServiceProvider).updateLastWaterTime();
    await _checkReminders();
    await _syncManualData(newIntake, _moodScore);
  }

  Future<void> _syncManualData(int water, int mood) async {
    if (!_isDataLoaded) {
      // If data isn't loaded yet, try to load it first to avoid overwriting with defaults
      await _loadHealthData();
    }
    
    final healthService = ref.read(healthDataServiceProvider);
    final apiService = ref.read(api.apiServiceProvider);
    
    final healthData = await healthService.syncHealthData();
    if (healthData != null) {
      // Re-fetch latest from server to be absolutely sure we have the latest other fields
      final latestSignal = await apiService.getDailySignal();
      
      await apiService.createSignal(
        SignalFeatureCreate(
          date: healthData.date,
          steps: healthData.steps,
          sleepHours: healthData.sleepHours,
          activeMinutes: healthData.activeMinutes,
          // Use the provided water/mood, but if we just fetched latest, maybe use those if they are newer?
          // For now, trust the caller's water/mood as they are the ones doing the action.
          waterIntake: water,
          moodScore: mood > 0 ? mood : (latestSignal?.moodScore),
        ),
      );
      await ref.read(energyProvider.notifier).getCurrentEnergy();
    }
  }

  Widget _buildHistorySection(BuildContext context, EnergyState energyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('energy_history').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF566162), letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
          child: EnergyChart(history: energyState.history ?? EnergyHistory(snapshots: [])),
        ),
      ],
    );
  }

  Widget _buildChargeButton(BuildContext context) {
    return SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2a3435), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () => Navigator.pushNamed(context, '/charge'), child: Text(tr('charge_now'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))));
  }

  Widget _buildDebugOverlay(BuildContext context) {
    return Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7), child: Column(children: [Container(color: Colors.grey[800], child: ListTile(title: const Text('Debug Log', style: TextStyle(color: Colors.white)), trailing: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _showDebugLog = false)))), Expanded(child: ListView.builder(itemCount: _logMessages.length, itemBuilder: (context, i) => ListTile(title: Text(_logMessages[i], style: const TextStyle(color: Colors.white, fontSize: 12)))))])));
  }

  String _getAuraSyncStatus(String level) {
    if (level == 'high') return tr('aura_active');
    if (level == 'medium') return tr('aura_stable');
    return tr('aura_low');
  }

  Widget _buildWelcomePage(BuildContext context) {
    return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.bolt, size: 80), Text(tr('app_name'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: Text(tr('login')))])));
  }
}
