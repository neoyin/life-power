import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/widgets/energy_status_dot.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';

class WatchersPage extends ConsumerStatefulWidget {
  const WatchersPage({Key? key}) : super(key: key);

  @override
  _WatchersPageState createState() => _WatchersPageState();
}

class _WatchersPageState extends ConsumerState<WatchersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(energyProvider.notifier).getWatchers();
    });
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
          tr('nav_watching'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2a3435),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF535f6f)),
            onPressed: () {
              _showAddWatcherDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildPeopleWatchingMe(),
            const SizedBox(height: 32),
            _buildPeopleIWatch(energyState),
            const SizedBox(height: 32),
            _buildImpactCard(),
            const SizedBox(height: 32),
            _buildEnergyShareCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildPeopleWatchingMe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('people_watching_me'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a3435),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              WatcherAvatar(
                name: 'User 1',
                size: 64,
                showGradientBorder: true,
              ),
              const SizedBox(width: 16),
              WatcherAvatar(
                name: 'User 2',
                size: 64,
                showGradientBorder: true,
              ),
              const SizedBox(width: 16),
              WatcherAvatar(
                name: 'User 3',
                size: 64,
                showGradientBorder: true,
              ),
              const SizedBox(width: 16),
              WatcherAvatar(
                name: 'User 4',
                size: 64,
                showGradientBorder: true,
              ),
              const SizedBox(width: 16),
              WatcherAvatar(
                name: tr('add'),
                size: 64,
                isAddButton: true,
                onTap: () {
                  _showAddWatcherDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleIWatch(EnergyState energyState) {
    final watchers = energyState.watchers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('people_i_watch'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a3435),
          ),
        ),
        const SizedBox(height: 16),
        if (watchers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFffffff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.group_off, size: 48, color: const Color(0xFFd9e5e6)),
                const SizedBox(height: 16),
                Text(
                  tr('no_watchers'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF566162),
                  ),
                ),
              ],
            ),
          )
        else
          ...watchers.map((watcher) => _buildWatcherItem(watcher)),
      ],
    );
  }

  Widget _buildWatcherItem(watcher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Stack(
            children: [
              WatcherAvatar(
                name: watcher.username,
                size: 56,
                showGradientBorder: true,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getEnergyStatusColor(watcher.energyLevel),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  watcher.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a3435),
                  ),
                ),
                const SizedBox(height: 4),
                EnergyLevelBadge(level: watcher.energyLevel),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _showSendCareDialog(watcher);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF535f6f),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              tr('send_care'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF535f6f), Color(0xFF475363)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF535f6f).withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('impact'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '12',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('people_positively_influenced'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyShareCard() {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF94f990).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.share,
              color: Color(0xFF006f1d),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('energy_share'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a3435),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tr('sharing_energy_status')} 8 ${tr('watchers')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF566162),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF006f1d).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tr('on'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006f1d),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWatcherDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('add')),
          content: Text(tr('no_watchers')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('add')),
            ),
          ],
        );
      },
    );
  }

  void _showSendCareDialog(watcher) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${tr('send_care')} ${watcher.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCareOption('You matter!', Icons.favorite),
              _buildCareOption('Take care!', Icons.health_and_safety),
              _buildCareOption('You are strong!', Icons.bolt),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCareOption(String message, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF535f6f)),
      title: Text(message),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  Color _getEnergyStatusColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
      case 'energetic':
        return const Color(0xFF006f1d);
      case 'medium':
      case 'balanced':
        return const Color(0xFFfec330);
      case 'low':
      case 'low battery':
        return const Color(0xFF9f403d);
      default:
        return const Color(0xFF727d7e);
    }
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
    final isSelected = index == 2;
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
