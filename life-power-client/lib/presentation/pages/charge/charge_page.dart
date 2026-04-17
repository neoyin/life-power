import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/data/services/health_data_service.dart';
import 'package:life_power_client/data/services/api_service.dart' as api;
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/widgets/progress_bar.dart';
import 'package:life_power_client/presentation/widgets/drain_card.dart';
import 'package:life_power_client/presentation/widgets/zen_tip_card.dart';
import 'package:life_power_client/presentation/widgets/main_navigation_bar.dart';

enum BreathingState { idle, preparing, breathing, completed }

class ChargePage extends ConsumerStatefulWidget {
  const ChargePage({Key? key}) : super(key: key);

  @override
  _ChargePageState createState() => _ChargePageState();
}

class _ChargePageState extends ConsumerState<ChargePage> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late Animation<double> _celebrationOpacity;

  BreathingState _state = BreathingState.idle;
  int _completedCycles = 0;
  Timer? _preparationTimer;
  String _instructionText = '';
  bool _showCelebration = false;

  bool _mounted = true;
  int _todaySteps = 0;
  double _sleepHours = 0;
  int _remainingCharges = 3;
  SignalFeature? _latestSignal;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2500), // 2.5s per phase (inhale/exhale)
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

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

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
        setState(() => _instructionText = tr('exhale'));
      } else if (status == AnimationStatus.dismissed) {
        if (_state == BreathingState.breathing) {
          _completedCycles++;
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
      _loadHealthData();
      _loadRemainingCharges();
    });
  }

  Future<void> _loadHealthData() async {
    final healthService = ref.read(healthDataServiceProvider);
    final apiService = ref.read(api.apiServiceProvider);

    final healthData = await healthService.syncHealthData();
    if (mounted && healthData != null) {
      setState(() {
        _todaySteps = healthData.steps;
        _sleepHours = healthData.sleepHours ?? 0;
      });

      await apiService.createSignal(
        SignalFeatureCreate(
          date: healthData.date,
          steps: healthData.steps,
        ),
      );
    }

    try {
      final signal = await apiService.getDailySignal();
      if (_mounted) {
        setState(() {
          _latestSignal = signal;
          _todaySteps = signal?.steps ?? _todaySteps;
          _sleepHours = signal?.sleepHours ?? _sleepHours;
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
    super.dispose();
  }

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
    }
  }

  void _startBreathingCycles() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = BreathingState.breathing;
      _completedCycles = 0;
      _instructionText = tr('inhale');
    });
    _breathingController.forward();
  }

  void _abortBreathing() {
    _preparationTimer?.cancel();
    _breathingController.stop();
    _breathingController.reset();
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
      if (mounted) {
        setState(() => _showCelebration = false);
        _celebrationController.reset();
      }
    });

    // Show motivational feedback
    _showBreathingFeedback();

    // Sync and Charge (persistent via incrementBreathing)
    ref.read(api.apiServiceProvider).incrementBreathing().then((_) {
      ref.read(energyProvider.notifier).getCurrentEnergy();
      _loadHealthData();
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

  void _chargeEnergy(String method) {
    ref.read(energyProvider.notifier).chargeEnergy(method).then((_) {
      final energyState = ref.read(energyProvider);
      if (mounted) {
        setState(() {
          _remainingCharges = energyState.remainingCharges ?? 0;
        });
        _showChargeFeedback(energyState.remainingCharges ?? 0);
      }
    });
  }

  Future<void> _loadRemainingCharges() async {
    try {
      final limit = await ref.read(api.apiServiceProvider).getDailyChargeLimit();
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
    final color = remaining > 0 ? const Color(0xFF006f1d) : const Color(0xFF9f403d);
    
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildTodayProgress(),
                const SizedBox(height: 32),
                _buildBreathingButton(),
                const SizedBox(height: 32),
                _buildManualChargeButton(),
                const SizedBox(height: 32),
                _buildDrainDetails(),
                const SizedBox(height: 24),
                _buildZenTip(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),
      bottomNavigationBar: MainNavigationBar(currentIndex: 1),
    );
  }

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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                        const Text(
                          'Charging Complete!',
                          style: TextStyle(
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

  Widget _buildTodayProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('todays_progress'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a3435),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFffffff),
            borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 24),
              ProgressBar(
                icon: Icons.bedtime,
                label: tr('sleep'),
                value: _sleepHours > 0 ? _sleepHours : 8.4,
                maxValue: Constants.targetSleep + 1.0,
                unit: tr('hours'),
                progressColor: const Color(0xFF535f6f),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreathingButton() {
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
      child: Column(
        children: [
          GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                double scale = (_state == BreathingState.breathing) 
                    ? _breathingAnimation.value 
                    : (_state == BreathingState.preparing ? 1.1 : 1.0);
                
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ringColor.withOpacity(0.3),
                          ringColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ringColor.withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _state == BreathingState.idle ? tr('hold_to_sync') : _instructionText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            _state == BreathingState.completed ? Icons.check_circle : Icons.favorite,
                            size: 64,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualChargeButton() {
    final bool isDisabled = _remainingCharges <= 0;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => _chargeEnergy('manual'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? const Color(0xFFb0b8bf) : const Color(0xFF535f6f),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFd9e0e6),
          disabledForegroundColor: const Color(0xFF9aa3ab),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.battery_charging_full, size: 24),
            const SizedBox(width: 12),
            Text(tr('manual_charge')),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_remainingCharges/3',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrainDetails() {
    List<Widget> drainCards = [];

    // Steps (Sedentary)
    if (_todaySteps < 5000) {
      double missing = (8000 - _todaySteps) / 8000.0;
      int drain = (missing * 15).round().clamp(1, 15);
      drainCards.add(
        DrainCard(
          title: tr('sedentary'),
          subtitle: tr('sedentary_desc'),
          percentage: drain,
          icon: Icons.chair,
        ),
      );
      drainCards.add(const SizedBox(height: 12));
    }

    // Sleep (Insufficient / Late)
    if (_sleepHours > 0 && _sleepHours < 6.0) {
      int drain = ((7.0 - _sleepHours) * 8).round().clamp(1, 15);
      drainCards.add(
        DrainCard(
          title: tr('insufficient_sleep'),
          subtitle: tr('insufficient_sleep_desc'),
          percentage: drain,
          icon: Icons.nightlight,
        ),
      );
      drainCards.add(const SizedBox(height: 12));
    }

    // Water (Dehydrated)
    if (_latestSignal != null && _latestSignal!.waterIntake != null) {
      int water = _latestSignal!.waterIntake!;
      if (water < 1000) {
        int drain = ((2000 - water) / 2000.0 * 10).round().clamp(1, 10);
        drainCards.add(
          DrainCard(
            title: tr('dehydrated'),
            subtitle: tr('dehydrated_desc'),
            percentage: drain,
            icon: Icons.water_drop,
          ),
        );
        drainCards.add(const SizedBox(height: 12));
      }
    }

    // Mood (Low Mood)
    if (_latestSignal != null && _latestSignal!.moodScore != null) {
      int mood = _latestSignal!.moodScore!;
      if (mood < 5) {
        int drain = ((5 - mood) * 3).clamp(1, 15);
        drainCards.add(
          DrainCard(
            title: tr('low_mood'),
            subtitle: tr('low_mood_desc'),
            percentage: drain,
            icon: Icons.mood_bad,
          ),
        );
        drainCards.add(const SizedBox(height: 12));
      }
    }

    if (drainCards.isEmpty) {
      return const SizedBox.shrink();
    }

    // Remove the last SizedBox
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

  Widget _buildZenTip() {
    String tipKey = 'zen_tip_general_1';
    
    if (_latestSignal != null && _latestSignal!.moodScore != null && _latestSignal!.moodScore! < 5) {
      tipKey = 'zen_tip_mood';
    } else if (_sleepHours > 0 && _sleepHours < 6.0) {
      tipKey = 'zen_tip_sleep';
    } else if (_latestSignal != null && _latestSignal!.waterIntake != null && _latestSignal!.waterIntake! < 1000) {
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
}
