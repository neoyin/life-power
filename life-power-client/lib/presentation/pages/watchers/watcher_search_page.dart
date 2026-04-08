import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/data/models/user.dart';
import 'package:life_power_client/data/models/watcher.dart';
import 'package:life_power_client/data/services/api_service.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';

class WatcherSearchPage extends ConsumerStatefulWidget {
  const WatcherSearchPage({Key? key}) : super(key: key);

  @override
  _WatcherSearchPageState createState() => _WatcherSearchPageState();
}

class _WatcherSearchPageState extends ConsumerState<WatcherSearchPage> {
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
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
                          return _buildUserItem(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(User user) {
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
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFd9e5e6),
            child: Text(user.username[0].toUpperCase()),
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
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _sendInvitation(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2a3435),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('invite')),
          ),
        ],
      ),
    );
  }
}
