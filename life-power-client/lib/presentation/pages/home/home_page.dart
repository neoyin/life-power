import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/theme.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/providers/auth_provider.dart';
import 'package:life_power_client/presentation/widgets/energy_ring.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).checkAuthStatus();
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(energyProvider.notifier).getCurrentEnergy();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final energyState = ref.watch(energyProvider);

    if (authState.user == null) {
      return _buildWelcomePage(context);
    }

    return _buildHomePage(context, energyState, authState);
  }

  Widget _buildWelcomePage(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.bubble_chart, color: const Color(0xFF535f6f)),
            const SizedBox(width: 8),
            Text(
              tr('app_name'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2a3435),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 100, color: const Color(0xFF535f6f)),
            const SizedBox(height: 24),
            Text(
              tr('app_name'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              tr('welcome'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text(tr('login')),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text(tr('register')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(0),
    );
  }

  Widget _buildHomePage(
      BuildContext context, EnergyState energyState, authState) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.bubble_chart, color: const Color(0xFF535f6f)),
            const SizedBox(width: 8),
            Text(
              tr('app_name'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2a3435),
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.notifications, color: const Color(0xFF727d7e)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFd9e5e6),
            child: Text(
              authState.user?.username[0].toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF535f6f),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: energyState.isLoading
          ? Center(child: CircularProgressIndicator())
          : energyState.currentEnergy != null
              ? _buildEnergyContent(context, energyState)
              : Center(child: Text(tr('loading'))),
      bottomNavigationBar: _buildBottomNavBar(0),
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
          const SizedBox(height: 48),
          _buildWatcherSection(context, energyState),
          const SizedBox(height: 32),
          _buildInsightBentoGrid(context, energy),
          const SizedBox(height: 32),
          _buildChargeButton(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEnergyRingSection(BuildContext context, energy) {
    final energyColor = AppTheme.getEnergyColor(energy.level);

    return Column(
      children: [
        SizedBox(
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
                      Text(
                        '${energy.score}',
                        style: const TextStyle(
                          fontSize: 88,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2a3435),
                          height: 1,
                        ),
                      ),
                      Text(
                        '%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475363),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('current_energy').toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF566162),
                      letterSpacing: 1,
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

  Widget _buildWatcherSection(BuildContext context, EnergyState energyState) {
    return Column(
      children: [
        WatcherAvatarList(
          watchers: [
            WatcherAvatarData(name: 'User 1'),
            WatcherAvatarData(name: 'User 2'),
            WatcherAvatarData(name: 'User 3'),
            WatcherAvatarData(name: 'User 4'),
            WatcherAvatarData(name: 'User 5'),
          ],
          maxDisplay: 4,
          avatarSize: 40,
        ),
        const SizedBox(height: 16),
        Text(
          '${energyState.currentEnergy?.watcherCount ?? 0} ${tr('people_watching_you')}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF566162),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBentoGrid(BuildContext context, energy) {
    return Column(
      children: [
        Container(
          width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.energy_savings_leaf,
                      color: const Color(0xFF006f1d)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF94f990).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tr('optimal'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006f1d),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tr('soulful_resilience'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('soulful_resilience_desc'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF566162),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFf0f4f5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bedtime,
                        color: const Color(0xFF535f6f), size: 24),
                    const SizedBox(height: 12),
                    Text(
                      tr('rest_quality').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF566162),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '8.4',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2a3435),
                            ),
                          ),
                          TextSpan(
                            text: 'hrs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF566162),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFf0f4f5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bolt, color: const Color(0xFFfec330), size: 24),
                    const SizedBox(height: 12),
                    Text(
                      tr('peak_flow').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF566162),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '14:20',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2a3435),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChargeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/charge'),
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
            Text(
              tr('charge_energy'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(int currentIndex) {
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
              _buildNavItem(
                  context, 1, Icons.battery_charging_full, tr('nav_charge')),
              _buildNavItem(context, 2, Icons.group, tr('nav_watching')),
              _buildNavItem(context, 3, Icons.settings, tr('nav_settings')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, IconData icon, String label) {
    final isSelected = index == 0;
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
