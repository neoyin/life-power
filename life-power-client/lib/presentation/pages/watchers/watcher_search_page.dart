import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/data/models/user.dart';
import 'package:life_power_client/data/models/watcher.dart';
import 'package:life_power_client/data/services/api_service.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';

enum UserRelationStatus {
  none,
  watchingMe,
  watching,
  pending,
}

class WatcherSearchPage extends ConsumerStatefulWidget {
  const WatcherSearchPage({Key? key}) : super(key: key);

  @override
  _WatcherSearchPageState createState() => _WatcherSearchPageState();
}

class _WatcherSearchPageState extends ConsumerState<WatcherSearchPage> {
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(energyProvider.notifier).getWatchers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('error'))),
      );
    }
  }

  Future<void> _sendInvitation(User user) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.inviteWatcher(WatcherRelationCreate(targetId: user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('invitation_sent'))),
      );
      ref.read(energyProvider.notifier).getWatchers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('invitation_failed'))),
      );
    }
  }

  UserRelationStatus _getUserStatus(User user, EnergyState energyState) {
    final watchersIds = energyState.watchers?.map((w) => w.user_id).toSet() ?? {};
    final myWatchersIds = energyState.myWatchers?.map((w) => w.id).toSet() ?? {};
    final pendingSentIds = energyState.pendingRequests?.map((r) => r.targetId).toSet() ?? {};

    if (watchersIds.contains(user.id)) {
      return UserRelationStatus.watching;
    } else if (myWatchersIds.contains(user.id)) {
      return UserRelationStatus.watchingMe;
    } else if (pendingSentIds.contains(user.id)) {
      return UserRelationStatus.pending;
    }
    return UserRelationStatus.none;
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
          tr('search_users'),
          style: const TextStyle(color: Color(0xFF2a3435), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2a3435)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('enter_username'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _handleSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(child: Text(tr('no_results')))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return _buildUserItem(user, energyState);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(User user, EnergyState energyState) {
    final status = _getUserStatus(user, energyState);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              WatcherAvatar(
                name: user.username,
                size: 48,
                showGradientBorder: false,
              ),
              if (status != UserRelationStatus.none)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(status),
                      border: Border.all(color: Colors.white, width: 2),
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
                  user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (user.fullName != null)
                  Text(
                    user.fullName!,
                    style: const TextStyle(color: Color(0xFF566162), fontSize: 13),
                  ),
                const SizedBox(height: 4),
                _buildStatusBadge(status),
              ],
            ),
          ),
          _buildActionButton(user, status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserRelationStatus status) {
    if (status == UserRelationStatus.none) {
      return const SizedBox.shrink();
    }

    String text;
    Color bgColor;
    Color textColor;

    switch (status) {
      case UserRelationStatus.watching:
        text = tr('watching');
        bgColor = const Color(0xFF006f1d).withOpacity(0.1);
        textColor = const Color(0xFF006f1d);
        break;
      case UserRelationStatus.watchingMe:
        text = tr('watching_me');
        bgColor = const Color(0xFF535f6f).withOpacity(0.1);
        textColor = const Color(0xFF535f6f);
        break;
      case UserRelationStatus.pending:
        text = tr('pending');
        bgColor = const Color(0xFFfec330).withOpacity(0.1);
        textColor = const Color(0xFFfec330);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(User user, UserRelationStatus status) {
    switch (status) {
      case UserRelationStatus.watching:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF006f1d).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tr('mutual_watch'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006f1d),
            ),
          ),
        );
      case UserRelationStatus.watchingMe:
        return ElevatedButton(
          onPressed: () => _sendInvitation(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2a3435),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(tr('watch_back')),
        );
      case UserRelationStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFfec330).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tr('waiting'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfec330),
            ),
          ),
        );
      default:
        return ElevatedButton(
          onPressed: () => _sendInvitation(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2a3435),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(tr('invite')),
        );
    }
  }

  Color _getStatusColor(UserRelationStatus status) {
    switch (status) {
      case UserRelationStatus.watching:
        return const Color(0xFF006f1d);
      case UserRelationStatus.watchingMe:
        return const Color(0xFF535f6f);
      case UserRelationStatus.pending:
        return const Color(0xFFfec330);
      default:
        return Colors.transparent;
    }
  }
}
