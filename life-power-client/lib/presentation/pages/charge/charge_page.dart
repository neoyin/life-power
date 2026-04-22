import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/data/services/health_data_service.dart';
import 'package:life_power_client/data/services/api_service.dart' as api;
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/data/models/charge.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/widgets/progress_bar.dart';
import 'package:life_power_client/presentation/widgets/drain_card.dart';
import 'package:life_power_client/presentation/widgets/zen_tip_card.dart';
import 'package:life_power_client/presentation/widgets/main_navigation_bar.dart';

/// 呼吸状态
enum BreathingState { idle, preparing, breathing, completed }

class ChargePage extends ConsumerStatefulWidget {
  const ChargePage({Key? key}) : super(key: key);

  @override
  _ChargePageState createState() => _ChargePageState();
}

class _ChargePageState extends ConsumerState<ChargePage>
    with TickerProviderStateMixin {
  // ---- 呼吸动画控制器 ----
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late Animation<double> _celebrationOpacity;
  // 循环进度弧形动画控制器（3段）
  late List<AnimationController> _cycleControllers;

  // ---- 手动充电动画状态 ----
  bool _isCharging = false;
  bool _showChargeSuccess = false;

  // ---- 状态变量 ----
  BreathingState _state = BreathingState.idle;
  int _completedCycles = 0;
  Timer? _preparationTimer;
  String _instructionText = '';
  bool _showCelebration = false;

  // ---- 呼吸引导状态 ----
  bool _showBreathingGuide = true;
  late AnimationController _guidePulseController;

  // ---- 数据变量 ----
  bool _mounted = true;
  int _todaySteps = 0;
  double _sleepHours = 0;
  int _waterIntake = 0;
  int _moodScore = 5;
  int _remainingCharges = 3;
  SignalFeature? _latestSignal;
  ChargeHistory? _chargeHistory;

  // 能量概览用
  int _currentEnergyScore = 0;
  String _energyLevel = 'low';
  String _energyTrend = '--';

  @override
  void initState() {
    super.initState();

    // 先初始化呼吸主动画控制器（避免late未初始化错误）
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // 庆祝动画
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _celebrationScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.elasticOut,
      ),
    );
    _celebrationOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // 呼吸引导脉冲动画
    _guidePulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 3段循环进度指示器
    _cycleControllers = List.generate(3, (index) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2500), // 每阶段2.5s，与呼吸同步
      );
      return ctrl;
    });

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
        setState(() => _instructionText = tr('exhale'));
      } else if (status == AnimationStatus.dismissed) {
        if (_state == BreathingState.breathing) {
          _completedCycles++;
          if (_completedCycles <= _cycleControllers.length) {
            _cycleControllers[_completedCycles - 1].forward();
          }
          if (_completedCycles >= 3) {
            _finishBreathing();
          } else {
            _breathingController.forward();
            setState(() => _instructionText = tr('inhale'));
          }
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBreathingGuide();
      _loadHealthData();
      _loadRemainingCharges();
      _loadEnergyOverview();
      _loadChargeHistory();
    });
  }

  Future<void> _checkBreathingGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenGuide = prefs.getBool('has_seen_breathing_guide') ?? false;
    if (mounted) {
      setState(() {
        _showBreathingGuide = !hasSeenGuide;
      });
      if (_showBreathingGuide) {
        _guidePulseController.repeat(reverse: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showBreathingGuideOverlay();
          }
        });
      }
    }
  }

  Future<void> _dismissBreathingGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_breathing_guide', true);
    _guidePulseController.stop();
    if (mounted) {
      setState(() => _showBreathingGuide = false);
    }
  }

  Future<void> _loadEnergyOverview() async {
    try {
      final energyState = ref.read(energyProvider);
      if (mounted) {
        setState(() {
          _currentEnergyScore = energyState.currentEnergy!.score;
          _energyLevel = energyState.currentEnergy!.level;
          _energyTrend = energyState.currentEnergy!.trend;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadChargeHistory() async {
    try {
      // 计算本月已过天数（从本月1号到今天）
      final now = DateTime.now();
      final daysInMonthSoFar = now.day;
      final history =
          await ref.read(api.apiServiceProvider).getChargeHistory(days: daysInMonthSoFar);
      if (mounted) {
        setState(() {
          _chargeHistory = history;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHealthData() async {
    final healthService = ref.read(healthDataServiceProvider);
    final apiService = ref.read(api.apiServiceProvider);

    final healthData = await healthService.syncHealthData();
    if (mounted && healthData != null) {
      final newSteps = healthData.steps > _todaySteps ? healthData.steps : _todaySteps;
      final newSleepHours = (healthData.sleepHours ?? 0) > _sleepHours ? (healthData.sleepHours ?? 0) : _sleepHours;
      setState(() {
        _todaySteps = newSteps;
        _sleepHours = newSleepHours;
      });

      await apiService.createSignal(
        SignalFeatureCreate(
          date: healthData.date,
          steps: newSteps,
        ),
      );
    }

    try {
      await ref.read(energyProvider.notifier).getTodaySignalIfNeeded();
      final signal = ref.read(energyProvider).todaySignal;
      if (_mounted) {
        setState(() {
          _latestSignal = signal;
          final apiSteps = signal?.steps ?? 0;
          _todaySteps = apiSteps > _todaySteps ? apiSteps : _todaySteps;
          final apiSleepHours = signal?.sleepHours ?? 0.0;
          _sleepHours = apiSleepHours > _sleepHours ? apiSleepHours : _sleepHours;
          _waterIntake = signal?.waterIntake ?? 0;
          _moodScore = signal?.moodScore ?? 5;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _mounted = false;
    _preparationTimer?.cancel();
    _breathingController.dispose();
    _celebrationController.dispose();
    _guidePulseController.dispose();
    for (var c in _cycleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ===================== 呼吸训练交互 =====================

  void _handleTapDown(TapDownDetails details) {
    if (_state != BreathingState.idle) return;

    setState(() {
      _state = BreathingState.preparing;
      _instructionText = tr('prepare_breathing');
    });

    _preparationTimer = Timer(const Duration(seconds: 3), () {
      if (_state == BreathingState.preparing) {
        _startBreathingCycles();
      }
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (_state == BreathingState.preparing) {
      _abortBreathing();
    } else if (_state == BreathingState.completed) {
      setState(() => _state = BreathingState.idle);
    }
  }

  void _handleTapCancel() {
    if (_state == BreathingState.preparing) {
      _abortBreathing();
    } else if (_state == BreathingState.breathing) {
      _showPartialBreathingFeedback();
    }
  }

  void _showPartialBreathingFeedback() {
    final completedCycles = _completedCycles;
    if (completedCycles > 0) {
      final message = tr('partial_breathing').replaceAll('{count}', '$completedCycles');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFfe8983).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.air,
                    color: Color(0xFFfe8983),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
    _abortBreathing();
  }

  void _startBreathingCycles() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = BreathingState.breathing;
      _completedCycles = 0;
      // 重置所有循环进度
      for (var c in _cycleControllers) {
        c.reset();
      }
      _instructionText = tr('inhale');
    });
    _breathingController.forward();
  }

  void _abortBreathing() {
    _preparationTimer?.cancel();
    _breathingController.stop();
    _breathingController.reset();
    for (var c in _cycleControllers) {
      c.reset();
    }
    setState(() {
      _state = BreathingState.idle;
      _instructionText = '';
      _completedCycles = 0;
    });
  }

  void _finishBreathing() {
    HapticFeedback.heavyImpact();
    setState(() {
      _state = BreathingState.completed;
      _instructionText = tr('synchronized');
      _showCelebration = true;
    });

    _celebrationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _showCelebration) {
        setState(() {
          _showCelebration = false;
        });
        _celebrationController.reset();
      }
    });

    // Show motivational feedback
    _showBreathingFeedback();

    // Sync and Charge
    ref.read(api.apiServiceProvider).incrementBreathing().then((_) {
      if (mounted) {
        ref.read(energyProvider.notifier).getCurrentEnergy().then((_) {
          if (mounted) {
            _loadEnergyOverview();
            _loadChargeHistory();
            _loadHealthData();
          }
        });
      }
    });
  }

  void _showBreathingFeedback() {
    final random = DateTime.now().millisecondsSinceEpoch % 6 + 1;
    final message = tr('breathing_done_$random');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF006f1d).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: Color(0xFF006f1d),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2a3435),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  void _showBreathingGuideOverlay() {
    if (!_showBreathingGuide) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFfe8983).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFfe8983),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('breathing_guide_title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('breathing_guide_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF566162),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0f4f5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildGuideStep(Icons.touch_app, tr('breathing_guide_step1')),
                        const SizedBox(height: 8),
                        _buildGuideStep(Icons.air, tr('breathing_guide_step2')),
                        const SizedBox(height: 8),
                        _buildGuideStep(Icons.pause_circle_outline, tr('breathing_guide_step3')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _dismissBreathingGuide();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFfe8983),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        tr('breathing_guide_start'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF535f6f)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF535f6f),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== 手动充电交互 =====================

  void _chargeEnergy(String method) async {
    if (_isCharging) return;

    final previousCharges = _remainingCharges;
    final previousEnergy = _currentEnergyScore;
    final chargeAmount = _getChargeAmount(method);

    setState(() {
      _remainingCharges--;
      _currentEnergyScore = (_currentEnergyScore + chargeAmount).clamp(0, 100);
      _isCharging = true;
      _showChargeSuccess = true;
    });

    try {
      await ref.read(energyProvider.notifier).chargeEnergy(method);
      if (mounted) {
        setState(() {
          _isCharging = false;
          _remainingCharges = ref.read(energyProvider).remainingCharges;
        });
      }
      _showChargeFeedback(_remainingCharges);
      _loadEnergyOverview();
      _loadChargeHistory();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showChargeSuccess = false);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _remainingCharges = previousCharges;
          _currentEnergyScore = previousEnergy;
          _isCharging = false;
          _showChargeSuccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9c4343).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Color(0xFF9c4343),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('charge_failed'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2a3435),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      }
    }
  }

  int _getChargeAmount(String method) {
    switch (method) {
      case 'manual':
        return 5;
      case 'quick_steps':
        return 5;
      case 'quick_water':
        return 3;
      case 'quick_sleep':
        return 8;
      case 'quick_mood':
        return 2;
      default:
        return 5;
    }
  }

  Future<void> _loadRemainingCharges() async {
    try {
      final limit =
          await ref.read(api.apiServiceProvider).getDailyChargeLimit();
      if (mounted) {
        setState(() {
          _remainingCharges = limit.remainingCharges;
        });
      }
    } catch (_) {}
  }

  void _showChargeFeedback(int remaining) {
    final message = remaining > 0
        ? '${tr('charge_success')} ($remaining ${tr('charges_remaining')})'
        : tr('charge_limit_reached');
    final color =
        remaining > 0 ? const Color(0xFF006f1d) : const Color(0xFF9f403d);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  remaining > 0 ? Icons.bolt : Icons.battery_alert,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2a3435),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  /// 获取耗电项对应的改善建议action
  String _getActionKeyForDrain(String drainType) {
    switch (drainType) {
      case 'steps':
        return 'action_walk';
      case 'water':
        return 'action_drink_water';
      case 'sleep':
        return 'action_rest';
      case 'mood':
        return 'action_breathe';
      default:
        return 'action_walk';
    }
  }

  IconData _getIconForDrain(String drainType) {
    switch (drainType) {
      case 'steps':
        return Icons.directions_walk;
      case 'water':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'mood':
        return Icons.self_improvement;
      default:
        return Icons.directions_run;
    }
  }

  void _showActionSuggestion(String actionKey) {
    String title = tr(actionKey);
    Map<String, String> suggestions = {
      'action_walk': tr('sedentary_desc'),
      'action_drink_water': tr('dehydrated_desc'),
      'action_rest': tr('insufficient_sleep_desc'),
      'action_breathe': tr('low_mood_desc'),
    };

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF006f1d).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForDrain(
                    {'action_walk': 'steps', 'action_drink_water': 'water',
                     'action_rest': 'sleep', 'action_breathe': 'mood'}
                            [actionKey] ??
                        'steps'),
                color: const Color(0xFF006f1d),
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2a3435),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              suggestions[actionKey] ??
                  'Take a small step towards better energy.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF566162),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006f1d),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(tr('got_it')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== UI 构建方法 =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          tr('nav_charge'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2a3435),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ====== 区块1: 能量概览头部 ======
                _buildEnergyOverview(),
                const SizedBox(height: 28),

                // ====== 区块2: 今日四维进度 ======
                _buildTodayProgress(),
                const SizedBox(height: 28),

                // ====== 区块3: 呼吸训练核心区 ======
                _buildBreathingSection(),
                const SizedBox(height: 28),

                // ====== 区块4: 手动充电 + 快速行动 ======
                _buildManualChargeButton(),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 24),

                // ====== 区块5: 耗电详情分析 ======
                _buildDrainDetails(),
                const SizedBox(height: 24),

                // ====== 区块6: 本周充电记录 ======
                _buildChargeHistorySection(),
                const SizedBox(height: 16),

                // ====== 禅意提示（保留原有位置下移） ======
                _buildZenTip(),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 庆祝遮罩层
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),
      bottomNavigationBar: MainNavigationBar(currentIndex: 1),
    );
  }

  // ---------- 区块1: 能量概览（电池卡片样式） ----------
  Widget _buildEnergyOverview() {
    final scoreColor = _getEnergyColor(_energyLevel);
    final fillRatio = (_currentEnergyScore / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a3435).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: scoreColor),
              const SizedBox(width: 6),
              Text(
                tr('energy_overview'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2a3435),
                ),
              ),
              const Spacer(),
              // 趋势标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _energyTrend.contains('+')
                      ? const Color(0xFF006f1d).withOpacity(0.08)
                      : _energyTrend.contains('-')
                          ? const Color(0xFF9c4343).withOpacity(0.08)
                          : const Color(0xFF2a3435).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _energyTrend.contains('+')
                          ? Icons.trending_up
                          : _energyTrend.contains('-')
                              ? Icons.trending_down
                              : Icons.horizontal_rule,
                      size: 14,
                      color: _energyTrend.contains('+')
                          ? const Color(0xFF006f1d)
                          : _energyTrend.contains('-')
                              ? const Color(0xFF9c4343)
                              : const Color(0xFF535f6f),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _energyTrend.contains('+') || _energyTrend.contains('-')
                          ? '$_energyTrend${tr('vs_yesterday')}'
                          : tr('energy_overview'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _energyTrend.contains('+')
                            ? const Color(0xFF006f1d)
                            : _energyTrend.contains('-')
                                ? const Color(0xFF9c4343)
                                : const Color(0xFF535f6f),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 电池图 + 分数
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 电池图示
              _buildBatteryVisual(fillRatio, scoreColor),
              const SizedBox(width: 20),
              // 右侧文字信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_currentEnergyScore',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scoreColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLevelLabel(_energyLevel),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scoreColor.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 充电进度条
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fillRatio,
                        minHeight: 6,
                        backgroundColor: scoreColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 电池造型可视化
  Widget _buildBatteryVisual(double fillRatio, Color scoreColor) {
    return SizedBox(
      width: 64,
      height: 96,
      child: CustomPaint(
        painter: _BatteryPainter(
          fillRatio: fillRatio,
          color: scoreColor,
        ),
      ),
    );
  }

  Color _getEnergyColor(String level) {
    switch (level) {
      case 'high':
        return const Color(0xFF006f1d);
      case 'medium':
        return const Color(0xFFe6a000);
      default:
        return const Color(0xFF9c4343);
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'high':
        return tr('energy_high');
      case 'medium':
        return tr('energy_medium');
      default:
        return tr('energy_low');
    }
  }

  String _getMoodEmoji() {
    if (_moodScore == 0) return '—';
    if (_moodScore >= 9) return '⚡';
    if (_moodScore >= 7) return '🧘';
    if (_moodScore >= 5) return '😑';
    if (_moodScore >= 3) return '📉';
    return '🔥';
  }

  // ---------- 区块2: 今日四维进度 ----------
  Widget _buildTodayProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('todays_progress'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
          ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFffffff),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2a3435).withOpacity(0.06),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              ProgressBar(
                icon: Icons.directions_walk,
                label: tr('walking'),
                value: _todaySteps,
                maxValue: Constants.targetSteps,
                unit: tr('steps'),
                progressColor: const Color(0xFF006f1d),
              ),
              const SizedBox(height: 20),
              ProgressBar(
                icon: Icons.bedtime,
                label: tr('sleep'),
                value: _sleepHours,
                maxValue: Constants.targetSleep + 1.0,
                unit: tr('hours'),
                progressColor: const Color(0xFF535f6f),
              ),
              const SizedBox(height: 20),
              ProgressBar(
                icon: Icons.water_drop,
                label: tr('water'),
                value: _waterIntake,
                maxValue: 2000,
                unit: tr('ml'),
                progressColor: const Color(0xFF4EA8DE),
              ),
              const SizedBox(height: 20),
              ProgressBar(
                icon: Icons.emoji_emotions_outlined,
                label: '${tr('mood')} ${_getMoodEmoji()}',
                value: _moodScore,
                maxValue: 10,
                unit: '',
                progressColor: const Color(0xFF9D4EDD),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- 区块3: 呼吸训练核心区 ----------
  Widget _buildBreathingSection() {
    Color ringColor;
    switch (_state) {
      case BreathingState.preparing:
        ringColor = const Color(0xFF535f6f);
        break;
      case BreathingState.breathing:
        ringColor = const Color(0xFFfe8983);
        break;
      case BreathingState.completed:
        ringColor = const Color(0xFF006f1d);
        break;
      case BreathingState.idle:
      default:
        ringColor = const Color(0xFFfe8983);
    }

    return Center(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (context, child) {
            double scale = (_state == BreathingState.breathing)
                ? _breathingAnimation.value
                : (_state == BreathingState.preparing
                    ? 1.08
                    : 1.0);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外围3段循环进度弧形
                    ..._buildCycleArcs(ringColor),
                    // 主呼吸圆按钮
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            ringColor.withOpacity(0.25),
                            ringColor.withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ringColor.withOpacity(0.2),
                            blurRadius: 36,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _state == BreathingState.idle
                                  ? tr('hold_to_sync')
                                  : _instructionText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              _state == BreathingState.completed
                                  ? Icons.check_circle
                                  : Icons.favorite,
                              size: 56,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建3段循环完成进度弧形
  List<Widget> _buildCycleArcs(Color baseColor) {
    final list = <Widget>[];
    for (int i = 0; i < 3; i++) {
      final isCompleted = _completedCycles > i;
      final isCurrent =
          _state == BreathingState.breathing && _completedCycles == i;
      final arcColor =
          isCompleted ? const Color(0xFF006f1d) : baseColor.withOpacity(0.3);
      final arcWidth = isCurrent ? 4.0 : 3.0;

      list.add(
        Positioned.fill(
          child: CustomPaint(
            painter: _CycleArcPainter(
              cycleIndex: i,
              totalCycles: 3,
              color: arcColor,
              strokeWidth: arcWidth,
              progress:
                  isCompleted ? 1.0 : (_breathingController.isAnimating ? _breathingAnimation.value : 0.0),
            ),
          ),
        ),
      );
    }
    return list;
  }

  // ---------- 区块4: 手动充电按钮 ----------
  Widget _buildManualChargeButton() {
    final bool isDisabled = _remainingCharges <= 0 || _isCharging;
    final bgColor = _showChargeSuccess
        ? const Color(0xFF006f1d)
        : (isDisabled
            ? const Color(0xFFd9e0e6)
            : const Color(0xFF535f6f));

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isDisabled ? null : () => _chargeEnergy('manual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: isDisabled ? const Color(0xFF9aa3ab) : Colors.white,
              disabledBackgroundColor: const Color(0xFFd9e0e6),
              disabledForegroundColor: const Color(0xFF9aa3ab),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: _isCharging
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                    ),
                  )
                : _showChargeSuccess
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 22),
                          SizedBox(width: 8),
                          Text('✓ Done', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDisabled ? Icons.battery_alert : Icons.battery_charging_full,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isDisabled ? tr('charge_exhausted') : tr('manual_charge'),
                          ),
                          if (!isDisabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_remainingCharges/3',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ),
        if (isDisabled && _remainingCharges <= 0) ...[
          const SizedBox(height: 8),
          Text(
            tr('charge_recovery_hint'),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF727d7e),
            ),
          ),
        ],
      ],
    );
  }

  // ---------- 快速行动卡片组 ----------
  Widget _buildQuickActions() {
    if (_remainingCharges <= 0) return const SizedBox.shrink();

    final actions = <Map<String, dynamic>>[];
    if (_todaySteps < 5000) {
      actions.add({
        'type': 'steps',
        'icon': Icons.directions_walk,
        'title': tr('action_walk'),
        'subtitle': '5 ${tr('minutes')}',
        'energy': '+5',
        'color': const Color(0xFF006f1d),
      });
    }
    if (_latestSignal != null && _latestSignal!.waterIntake != null && _latestSignal!.waterIntake! < 1000) {
      actions.add({
        'type': 'water',
        'icon': Icons.water_drop,
        'title': tr('action_drink_water'),
        'subtitle': '1 ${tr('glass')}',
        'energy': '+3',
        'color': const Color(0xFF4EA8DE),
      });
    }
    if (_sleepHours > 0 && _sleepHours < 6.0) {
      actions.add({
        'type': 'sleep',
        'icon': Icons.bedtime,
        'title': tr('action_rest'),
        'subtitle': '20 ${tr('minutes')}',
        'energy': '+8',
        'color': const Color(0xFF535f6f),
      });
    }
    if (_latestSignal != null && _latestSignal!.moodScore != null && _latestSignal!.moodScore! < 5) {
      actions.add({
        'type': 'mood',
        'icon': Icons.self_improvement,
        'title': tr('action_breathe'),
        'subtitle': '1 ${tr('minutes')}',
        'energy': '+2',
        'color': const Color(0xFFfe8983),
      });
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            tr('quick_charge'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2a3435),
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((action) {
            return GestureDetector(
              onTap: () => _performQuickAction(action['type'] as String),
              child: Container(
                width: (MediaQuery.of(context).size.width - 72) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (action['color'] as Color).withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2a3435),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF727d7e),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        action['energy'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: action['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _performQuickAction(String type) async {
    if (type == 'water') {
      try {
        await _performQuickWaterAction();
      } catch (e) {
        if (mounted) {
          setState(() => _isCharging = false);
        }
        debugPrint('Error performing quick water action: $e');
      }
      return;
    }

    if (type == 'steps') {
      try {
        await _performQuickStepsAction();
      } catch (e) {
        if (mounted) {
          setState(() => _isCharging = false);
        }
        debugPrint('Error performing quick steps action: $e');
      }
      return;
    }

    try {
      await ref.read(energyProvider.notifier).chargeEnergy('quick_$type');

      if (!mounted) return;

      setState(() {
        _remainingCharges = ref.read(energyProvider).remainingCharges;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006f1d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Color(0xFF006f1d),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('quick_charge_success'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );

      if (!mounted) return;
      _loadEnergyOverview();
      _loadChargeHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9c4343).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFF9c4343),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('charge_failed'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
  }

  // ---------- 区块5: 耗电详情 ----------
  Future<void> _performQuickWaterAction() async {
    if (_isCharging || _remainingCharges <= 0) return;

    final apiService = ref.read(api.apiServiceProvider);
    
    setState(() => _isCharging = true);

    try {
      // 1. 先进行能量充电（扣除次数）
      await ref.read(energyProvider.notifier).chargeEnergy('quick_water');
      
      // 2. 如果成功，再更新信号项
      final currentWater = _latestSignal?.waterIntake ?? 0;
      final newWater = currentWater + 250;

      await apiService.createSignal(
        SignalFeatureCreate(
          date: DateTime.now(),
          waterIntake: newWater,
        ),
      );

      if (!mounted) return;

      if (mounted) {
        setState(() {
          _isCharging = false;
          _remainingCharges = ref.read(energyProvider).remainingCharges;
          _latestSignal = SignalFeature(
            id: _latestSignal?.id ?? 0,
            userId: _latestSignal?.userId ?? 0,
            date: DateTime.now(),
            steps: _latestSignal?.steps ?? 0,
            sleepHours: _latestSignal?.sleepHours ?? 0,
            waterIntake: newWater,
            moodScore: _latestSignal?.moodScore ?? 5,
            breathingSessions: _latestSignal?.breathingSessions ?? 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EA8DE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Color(0xFF4EA8DE),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('quick_charge_success'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );

      await ref.read(energyProvider.notifier).getTodaySignal();
      await ref.read(energyProvider.notifier).getCurrentEnergy();
      _loadHealthData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9c4343).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFF9c4343),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('charge_failed'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
  }

  Future<void> _performQuickStepsAction() async {
    if (_isCharging || _remainingCharges <= 0) return;

    final apiService = ref.read(api.apiServiceProvider);
    
    setState(() => _isCharging = true);

    try {
      // 1. 先进行能量充电（扣除次数）
      await ref.read(energyProvider.notifier).chargeEnergy('quick_steps');

      // 2. 成功后更新信号项
      final currentSteps = _latestSignal?.steps ?? 0;
      final newSteps = currentSteps + 500;

      await apiService.createSignal(
        SignalFeatureCreate(
          date: DateTime.now(),
          steps: newSteps,
        ),
      );

      if (mounted) {
        setState(() {
          _isCharging = false;
          _remainingCharges = ref.read(energyProvider).remainingCharges;
          _latestSignal = SignalFeature(
            id: _latestSignal?.id ?? 0,
            userId: _latestSignal?.userId ?? 0,
            date: DateTime.now(),
            steps: newSteps,
            sleepHours: _latestSignal?.sleepHours ?? 0,
            waterIntake: _latestSignal?.waterIntake ?? 0,
            moodScore: _latestSignal?.moodScore ?? 5,
            breathingSessions: _latestSignal?.breathingSessions ?? 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006f1d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    color: Color(0xFF006f1d),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('quick_charge_success'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );

      await ref.read(energyProvider.notifier).getTodaySignal();
      await ref.read(energyProvider.notifier).getCurrentEnergy();
      _loadHealthData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9c4343).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFF9c4343),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('charge_failed'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
  }

  Widget _buildDrainDetails() {
    List<Widget> drainCards = [];

    // Steps (Sedentary)
    if (_todaySteps < 5000) {
      double missing = (8000 - _todaySteps) / 8000.0;
      int drain = (missing * 15).round().clamp(1, 15);
      drainCards.add(DrainCard(
        title: tr('sedentary'),
        subtitle: tr('sedentary_desc'),
        percentage: drain,
        icon: Icons.chair,
        onTap: () => _showActionSuggestion('action_walk'),
      ));
      drainCards.add(const SizedBox(height: 14));
    }

    // Sleep
    if (_sleepHours > 0 && _sleepHours < 6.0) {
      int drain = ((7.0 - _sleepHours) * 8).round().clamp(1, 15);
      drainCards.add(DrainCard(
        title: tr('insufficient_sleep'),
        subtitle: tr('insufficient_sleep_desc'),
        percentage: drain,
        icon: Icons.nightlight,
        onTap: () => _showActionSuggestion('action_rest'),
      ));
      drainCards.add(const SizedBox(height: 14));
    }

    // Water
    if (_latestSignal != null && _latestSignal!.waterIntake != null) {
      int water = _latestSignal!.waterIntake!;
      if (water < 1000) {
        int drain = ((2000 - water) / 2000.0 * 10).round().clamp(1, 10);
        drainCards.add(DrainCard(
          title: tr('dehydrated'),
          subtitle: tr('dehydrated_desc'),
          percentage: drain,
          icon: Icons.water_drop,
          onTap: () => _showActionSuggestion('action_drink_water'),
        ));
        drainCards.add(const SizedBox(height: 14));
      }
    }

    // Mood
    if (_latestSignal != null && _latestSignal!.moodScore != null) {
      int mood = _latestSignal!.moodScore!;
      if (mood < 5) {
        int drain = ((5 - mood) * 3).clamp(1, 15);
        drainCards.add(DrainCard(
          title: tr('low_mood'),
          subtitle: tr('low_mood_desc'),
          percentage: drain,
          icon: Icons.mood_bad,
          onTap: () => _showActionSuggestion('action_breathe'),
        ));
        drainCards.add(const SizedBox(height: 14));
      }
    }

    if (drainCards.isEmpty) {
      return const SizedBox.shrink();
    }

    drainCards.removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('drain_details'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a3435),
          ),
        ),
        const SizedBox(height: 16),
        ...drainCards,
      ],
    );
  }

  // ---------- 区块6: 本月充电记录 ----------
  Widget _buildChargeHistorySection() {
    if (_chargeHistory == null) {
      return const SizedBox.shrink();
    }

    final history = _chargeHistory!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('this_month_footprint'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a3435),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF006f1d).withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF006f1d).withOpacity(0.12),
            ),
          ),
          child: Column(
            children: [
              // 月历热力图（全宽）
              _buildMonthHeatmap(history.dailySummaries),
              const SizedBox(height: 16),
              // 统计数字（横排）
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.self_improvement,
                      value: '${history.totalBreathing}',
                      label: tr('breathing_sessions_label'),
                      color: const Color(0xFF006f1d),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.bolt,
                      value: '${history.totalManual}',
                      label: tr('manual_charges_label'),
                      color: const Color(0xFFe6a000),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.local_fire_department,
                      value: '${history.streakDays}',
                      label: tr('consecutive_days'),
                      color: const Color(0xFFfe8983),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeatmap(List<DayChargeSummary> summaries) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    // 本月1号是星期几（Mon=1, Sun=7，转为Mon=0的0-6索引）
    final startWeekday = firstDayOfMonth.weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final today = now.day;

    // 构建日期到summary的映射
    final summaryMap = <String, DayChargeSummary>{};
    for (var s in summaries) {
      summaryMap[s.date] = s;
    }

    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Column(
      children: [
        // 星期标题行
        Row(
          children: weekdays.map((label) => Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF727D7E),
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // 日历网格：按周分行
        ...List.generate(((startWeekday + daysInMonth) / 7).ceil(), (weekIdx) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List.generate(7, (colIdx) {
                final dayNumber = weekIdx * 7 + colIdx - startWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox.shrink());
                }
                final dateStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
                final daySummary = summaryMap[dateStr];
                final hasActivity = daySummary?.hasActivity ?? false;
                final isToday = dayNumber == today;
                final chargeCount = daySummary?.totalCharges ?? 0;

                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: hasActivity
                            ? const Color(0xFF006f1d).withOpacity(
                                0.4 + (chargeCount > 1 ? 0.3 : 0) + (chargeCount > 2 ? 0.2 : 0))
                            : const Color(0xFFe8eeef),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(
                                color: const Color(0xFF006f1d),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                            color: hasActivity ? Colors.white : const Color(0xFF9aa3ab),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2a3435),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF727D7E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- 禅意提示 ----------
  Widget _buildZenTip() {
    String tipKey = 'zen_tip_general_1';

    if (_latestSignal != null &&
        _latestSignal!.moodScore != null &&
        _latestSignal!.moodScore! < 5) {
      tipKey = 'zen_tip_mood';
    } else if (_sleepHours > 0 && _sleepHours < 6.0) {
      tipKey = 'zen_tip_sleep';
    } else if (_latestSignal != null &&
        _latestSignal!.waterIntake != null &&
        _latestSignal!.waterIntake! < 1000) {
      tipKey = 'zen_tip_water';
    } else if (_todaySteps < 5000) {
      tipKey = 'zen_tip_move';
    } else {
      final random = DateTime.now().millisecondsSinceEpoch % 3 + 1;
      tipKey = 'zen_tip_general_$random';
    }

    return ZenTipCard(
      title: tr('zen_tip'),
      message: tr(tipKey),
    );
  }

  // ---------- 庆祝遮罩层 ----------
  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3 * _celebrationOpacity.value),
            child: Center(
              child: Transform.scale(
                scale: _celebrationScale.value,
                child: Opacity(
                  opacity: _celebrationOpacity.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006f1d),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF006f1d).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('charging_complete'), // 已修复国际化
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _instructionText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===================== 自定义绘制: 循环弧形进度 =====================

class _CycleArcPainter extends CustomPainter {
  final int cycleIndex;
  final int totalCycles;
  final Color color;
  final double strokeWidth;
  final double progress;

  _CycleArcPainter({
    required this.cycleIndex,
    required this.totalCycles,
    required this.color,
    required this.strokeWidth,
    this.progress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 4;
    final sweepPerCycle = (2 * math.pi) / totalCycles;
    final startAngle = -math.pi / 2 + (cycleIndex * sweepPerCycle);
    final sweepAngle = sweepPerCycle * 0.85; // 每段留间隙

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CycleArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}

// ===================== 自定义绘制: 电池图标 =====================

class _BatteryPainter extends CustomPainter {
  final double fillRatio;
  final Color color;

  _BatteryPainter({required this.fillRatio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final capPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // 电池主体尺寸
    final bodyLeft = 8.0;
    final bodyTop = 10.0;
    final bodyRight = size.width - 8.0;
    final bodyBottom = size.height - 6.0;
    final bodyW = bodyRight - bodyLeft;
    final bodyH = bodyBottom - bodyTop;
    final radius = 6.0;

    // 电池帽（正极凸起）
    final capW = 16.0;
    final capH = 6.0;
    final capLeft = (size.width - capW) / 2;
    final capTop = bodyTop - capH + 2;
    final capR = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(capLeft, capTop, capW, capH),
        Radius.circular(capR),
      ),
      capPaint,
    );

    // 电池外壳
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyW, bodyH),
      Radius.circular(radius),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // 电量填充（从底部向上）
    if (fillRatio > 0) {
      final fillH = (bodyH - 8) * fillRatio;
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bodyLeft + 4,
          bodyBottom - 4 - fillH,
          bodyW - 8,
          fillH,
        ),
        Radius.circular(3),
      );
      canvas.drawRRect(fillRect, fillPaint);
    }

    // 闪电图标（居中，当电量>0时）
    if (fillRatio > 0.05) {
      final boltPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill;
      final cx = size.width / 2;
      final cy = (bodyTop + bodyBottom) / 2;
      final boltPath = Path()
        ..moveTo(cx - 3, cy - 8)
        ..lineTo(cx - 7, cy + 1)
        ..lineTo(cx - 1, cy + 1)
        ..lineTo(cx + 3, cy + 8)
        ..lineTo(cx + 7, cy - 1)
        ..lineTo(cx + 1, cy - 1)
        ..close();
      canvas.drawPath(boltPath, boltPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.fillRatio != fillRatio || oldDelegate.color != color;
}
