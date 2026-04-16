import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/presentation/providers/auth_provider.dart';
import 'package:life_power_client/presentation/providers/locale_provider.dart';
import 'package:life_power_client/presentation/providers/user_settings_provider.dart';
import 'package:life_power_client/presentation/widgets/threshold_slider.dart';
import 'package:life_power_client/presentation/widgets/privacy_toggle.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';
import 'package:life_power_client/presentation/widgets/main_navigation_bar.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/data/services/health_data_service.dart';
import 'package:life_power_client/data/services/api_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      ref.read(userSettingsProvider.notifier).loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(userSettingsProvider);
    final settings = settingsState.settings;
    final thresholdValue = settings?.lowEnergyThreshold.toDouble() ?? 30.0;
    final stepsTracking = settings?.shareEnergyData ?? true;
    final sleepIntelligence = settings?.enableNotifications ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr('nav_settings'),
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
            _buildUserProfileSection(),
            const SizedBox(height: 32),
            _buildLanguageSection(),
            const SizedBox(height: 32),
            _buildBatteryAlerts(
              thresholdValue,
              (value) {},
              (value) {
                ref.read(userSettingsProvider.notifier).updateSettings(
                      lowEnergyThreshold: value.round(),
                    );
              },
            ),
            const SizedBox(height: 32),
            _buildWatcherManagement(),
            const SizedBox(height: 32),
            _buildPrivacyData(
              stepsTracking,
              sleepIntelligence,
              (value) {
                ref.read(userSettingsProvider.notifier).updateSettings(
                      shareEnergyData: value,
                    );
              },
              (value) {
                ref.read(userSettingsProvider.notifier).updateSettings(
                      enableNotifications: value,
                    );
              },
            ),
            const SizedBox(height: 32),
            _buildDangerZone(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: MainNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildLanguageSection() {
    final locale = ref.watch(localeProvider);
    final isEnglish = locale.languageCode == 'en';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Color(0xFF535f6f)),
              const SizedBox(width: 8),
              Text(
                tr('language'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOption(
                  'English',
                  'EN',
                  isEnglish,
                  () => ref.read(localeProvider.notifier).setLocale('en'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageOption(
                  '中文',
                  'ZH',
                  !isEnglish,
                  () => ref.read(localeProvider.notifier).setLocale('zh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String language,
    String code,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF535f6f) : const Color(0xFFf0f4f5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              code,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF535f6f),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              language,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF535f6f),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    final user = ref.watch(authProvider).user;
    final displayName = user?.fullName ?? user?.username ?? 'User';
    final email = user?.email ?? '';
    final avatarUrl = user?.avatarUrl;

    return GestureDetector(
      onTap: () => _showEditProfileDialog(),
      child: Container(
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
            WatcherAvatar(
              key: ValueKey(user?.avatarUrl ?? 'default'),
              name: displayName,
              imageUrl: user?.avatarUrl,
              size: 72,
              showGradientBorder: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a3435),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF727d7e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: Color(0xFF535f6f),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tr('edit_profile'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF535f6f),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF727d7e),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = ref.read(authProvider).user;
    final nameController =
        TextEditingController(text: user?.fullName ?? user?.username ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    bool isLoading = false;
    bool isUploadingAvatar = false;
    String? tempAvatarUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tr('edit_profile')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isUploadingAvatar
                          ? null
                          : () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                                imageQuality: 85,
                              );

                              if (image == null) return;

                              setDialogState(() => isUploadingAvatar = true);

                              try {
                                final apiService = ref.read(apiServiceProvider);

                                final bytes = await image.readAsBytes();
                                final filename = image.name;
                                final contentType =
                                    image.mimeType ?? 'image/jpeg';

                                final publicUrl =
                                    await apiService.uploadAvatarDirect(
                                  bytes,
                                  filename,
                                  contentType,
                                );

                                setDialogState(() {
                                  tempAvatarUrl = publicUrl;
                                  isUploadingAvatar = false;
                                });
                              } catch (e, stackTrace) {
                                debugPrint('[Avatar Upload] ERROR: $e');
                                debugPrint(
                                    '[Avatar Upload] Stack trace: $stackTrace');
                                setDialogState(() => isUploadingAvatar = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('${tr('error')}: $e')),
                                  );
                                }
                              }
                            },
                      child: Stack(
                        children: [
                          WatcherAvatar(
                            key: ValueKey(
                                tempAvatarUrl ?? user?.avatarUrl ?? 'default'),
                            name: nameController.text.isNotEmpty
                                ? nameController.text
                                : 'U',
                            imageUrl: tempAvatarUrl ?? user?.avatarUrl,
                            size: 80,
                            showGradientBorder: true,
                          ),
                          if (isUploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF535f6f),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: tr('name'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: tr('email'),
                        border: const OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);
                          await ref.read(authProvider.notifier).updateProfile(
                                fullName: nameController.text,
                                avatarUrl: tempAvatarUrl,
                              );
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(tr('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBatteryAlerts(double thresholdValue,
      ValueChanged<double> onChanged, ValueChanged<double> onChangeEnd) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFF535f6f)),
              const SizedBox(width: 8),
              Text(
                tr('battery_alerts'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ThresholdSlider(
            value: thresholdValue,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildWatcherManagement() {
    final myWatchers = ref.watch(energyProvider).myWatchers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility, color: Color(0xFF535f6f)),
            const SizedBox(width: 8),
            Text(
              tr('watcher_management'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (myWatchers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFffffff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                tr('no_watchers'),
                style: const TextStyle(color: Color(0xFF727d7e)),
              ),
            ),
          )
        else
          ...myWatchers.map((watcher) =>
              _buildWatcherItem(watcher.username, tr('full_access'), true)),
        const SizedBox(height: 12),
        _buildAddWatcherButton(),
      ],
    );
  }

  Widget _buildWatcherItem(String name, String accessType, bool isFullAccess) {
    return Container(
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
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFd7e3f7),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF535f6f),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF006f1d),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a3435),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isFullAccess
                        ? const Color(0xFF006f1d).withOpacity(0.1)
                        : const Color(0xFFfec330).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    accessType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isFullAccess
                          ? const Color(0xFF006f1d)
                          : const Color(0xFFfec330),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF9f403d)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.volume_off, color: Color(0xFF727d7e)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAddWatcherButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf0f4f5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFd9e5e6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: Color(0xFF535f6f)),
          const SizedBox(width: 8),
          Text(
            tr('add_new'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF535f6f),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyData(
    bool stepsTracking,
    bool sleepIntelligence,
    ValueChanged<bool> onStepsTrackingChanged,
    ValueChanged<bool> onSleepIntelligenceChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF535f6f)),
            const SizedBox(width: 8),
            Text(
              tr('privacy_data'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<bool>(
          future: ref.read(healthDataServiceProvider).hasPermission(),
          builder: (context, snapshot) {
            final isGranted = snapshot.data ?? false;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGranted
                    ? const Color(0xFF006f1d).withOpacity(0.1)
                    : const Color(0xFFff4d6d).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isGranted ? Icons.check_circle : Icons.error_outline,
                    color: isGranted
                        ? const Color(0xFF006f1d)
                        : const Color(0xFFff4d6d),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('permission_status'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2a3435),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGranted
                              ? tr('permission_granted')
                              : tr('permission_not_granted'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isGranted
                                ? const Color(0xFF006f1d)
                                : const Color(0xFFff4d6d),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isGranted)
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(healthDataServiceProvider)
                            .requestPermissions();
                        ref.refresh(healthDataServiceProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF535f6f),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(tr('grant_permission')),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
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
              PrivacyToggle(
                title: tr('steps_tracking'),
                subtitle: tr('steps_tracking_desc'),
                icon: Icons.directions_walk,
                value: stepsTracking,
                onChanged: onStepsTrackingChanged,
              ),
              const Divider(height: 1),
              PrivacyToggle(
                title: tr('sleep_intelligence'),
                subtitle: tr('sleep_intelligence_desc'),
                icon: Icons.bedtime,
                value: sleepIntelligence,
                onChanged: onSleepIntelligenceChanged,
              ),
              const Divider(height: 1),
              PrivacyToggle(
                title: tr('live_location'),
                subtitle: tr('live_location_desc'),
                icon: Icons.location_on,
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('danger_zone'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9f403d),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF9f403d).withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF535f6f)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(tr('logout')),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showDeleteConfirmation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9f403d),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(tr('disconnect_delete')),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${tr('version')} v1.0.0',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF727d7e),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('delete_account')),
          content: Text(tr('delete_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9f403d),
              ),
              child: Text(tr('delete')),
            ),
          ],
        );
      },
    );
  }
}
