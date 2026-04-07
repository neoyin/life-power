import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/constants.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/widgets/progress_bar.dart';
import 'package:life_power_client/presentation/widgets/drain_card.dart';
import 'package:life_power_client/presentation/widgets/zen_tip_card.dart';

class ChargePage extends ConsumerStatefulWidget {
  const ChargePage({Key? key}) : super(key: key);

  @override
  _ChargePageState createState() => _ChargePageState();
}

class _ChargePageState extends ConsumerState<ChargePage> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isBreathing = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: Constants.breathingAnimationDuration,
      vsync: this,
    )..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _breathingController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    if (!_mounted) return;
    setState(() {
      _isBreathing = true;
    });
    _breathingController.forward();

    Future.delayed(Constants.breathingAnimationDuration, () {
      if (!_mounted) return;
      setState(() {
        _isBreathing = false;
      });
      _breathingController.stop();
      _chargeEnergy('breathing');
    });
  }

  void _chargeEnergy(String method) {
    ref.read(energyProvider.notifier).chargeEnergy(method);
  }

  @override
  Widget build(BuildContext context) {
    final energyState = ref.watch(energyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: SingleChildScrollView(
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
      bottomNavigationBar: _buildBottomNavBar(),
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
                value: 7429,
                maxValue: 10000,
                unit: tr('steps'),
                progressColor: const Color(0xFF006f1d),
              ),
              const SizedBox(height: 24),
              ProgressBar(
                icon: Icons.bedtime,
                label: tr('sleep'),
                value: 8.4,
                maxValue: 9,
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
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isBreathing ? null : _startBreathing,
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathingAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFfe8983).withOpacity(0.3),
                          const Color(0xFFfe8983).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFfe8983).withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 64,
                            color: _isBreathing ? Colors.white : const Color(0xFFfe8983),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isBreathing ? tr('breathing') : tr('hold_to_sync'),
                            style: TextStyle(
                              fontSize: 14,
                              color: _isBreathing ? Colors.white : const Color(0xFFfe8983),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isBreathing ? tr('release_to_stop') : tr('tap_hold_15_seconds'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF566162),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualChargeButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () => _chargeEnergy('manual'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF535f6f),
          foregroundColor: Colors.white,
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
            Text(tr('manual_charge'))
          ],
        ),
      ),
    );
  }

  Widget _buildDrainDetails() {
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
        DrainCard(
          title: tr('sedentary'),
          subtitle: tr('sedentary_desc'),
          percentage: 15,
          icon: Icons.chair,
        ),
        const SizedBox(height: 12),
        DrainCard(
          title: tr('stayed_up_late'),
          subtitle: tr('stayed_up_late_desc'),
          percentage: 8,
          icon: Icons.nightlight,
        ),
      ],
    );
  }

  Widget _buildZenTip() {
    return ZenTipCard(
      message: tr('zen_tip'),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a3435).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.bolt, tr('nav_home')),
              _buildNavItem(context, 1, Icons.battery_charging_full, tr('nav_charge')),
              _buildNavItem(context, 2, Icons.group, tr('nav_watching')),
              _buildNavItem(context, 3, Icons.settings, tr('nav_settings')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = index == 1;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/');
            break;
          case 1:
            Navigator.pushNamed(context, '/charge');
            break;
          case 2:
            Navigator.pushNamed(context, '/watchers');
            break;
          case 3:
            Navigator.pushNamed(context, '/settings');
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFd7e3f7).withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF535f6f)
                  : const Color(0xFF727d7e),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF535f6f)
                    : const Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
