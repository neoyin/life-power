import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/data/models/energy.dart';
import 'package:life_power_client/data/models/watcher.dart';
import 'package:life_power_client/data/models/user_detail.dart';
import 'package:life_power_client/data/services/api_service.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';
import 'package:life_power_client/presentation/widgets/care_message_dialog.dart';
import 'package:life_power_client/presentation/widgets/dual_energy_chart.dart';

class WatcherDetailPage extends ConsumerStatefulWidget {
  final int userId; // 只接收用户ID，不再接收其他数据

  const WatcherDetailPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<WatcherDetailPage> createState() => _WatcherDetailPageState();
}

class _WatcherDetailPageState extends ConsumerState<WatcherDetailPage> {
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  bool _isLoadingEnergy = false;
  String? _error;

  UserDetail? _userDetail;
  List<CareMessage> _sentMessages = [];
  List<CareMessage> _receivedMessages = [];
  EnergyHistory? _myEnergyHistory;
  EnergyHistory? _otherEnergyHistory;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final detail = await apiService.getUserDetail(widget.userId);

      setState(() {
        _userDetail = detail;
        _isLoading = false;
      });

      // 加载消息和能量历史
      _loadMessages();
      _loadEnergyHistory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoadingMessages = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final sent = await apiService.getSentMessages();
      final received = await apiService.getCareMessages();

      setState(() {
        _sentMessages =
            sent.where((m) => m.recipientId == widget.userId).toList();
        _receivedMessages =
            received.where((m) => m.senderId == widget.userId).toList();
        _isLoadingMessages = false;
      });
    } catch (e) {
      setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _loadEnergyHistory() async {
    if (_userDetail == null) return;

    setState(() => _isLoadingEnergy = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final myHistory = await apiService.getEnergyHistory(days: 7);
      final otherHistory =
          await apiService.getUserEnergyHistory(widget.userId, days: 7);

      setState(() {
        _myEnergyHistory = myHistory;
        _otherEnergyHistory = otherHistory;
        _isLoadingEnergy = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('no_permission'))),
        );
      }
      setState(() => _isLoadingEnergy = false);
    }
  }

  String get _username =>
      _userDetail?.fullName ?? _userDetail?.username ?? 'Unknown';

  Future<void> _sendCareMessage(String message) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.sendCareMessage(
        CareMessageCreate(recipientId: widget.userId, content: message),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('care_sent')}: $message')),
        );
      }
      await _loadMessages();
      await _loadUserDetail(); // 刷新关怀统计
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error'))),
        );
      }
    }
  }

  void _showCareDialog() {
    CareMessageDialog.show(
      context: context,
      recipientName: _username,
      recipientId: widget.userId,
      onSend: (message) => _sendCareMessage(message),
    );
  }

  Future<void> _sendWatchRequest() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final requestData = WatcherRelationCreate(targetId: widget.userId);
      await apiService.inviteWatcher(requestData);
      await ref.read(energyProvider.notifier).getWatchers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('invitation_sent'))),
        );
      }

      _loadUserDetail();
      _loadEnergyHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('invitation_failed'))),
        );
      }
    }
  }

  Color _getEnergyColor(String level) {
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

  @override
  Widget build(BuildContext context) {
    ref.watch(energyProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFf8fafa),
        appBar: AppBar(
          backgroundColor: const Color(0xFFf8fafa),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2a3435)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            tr('watcher_detail'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a3435),
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _userDetail == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFf8fafa),
        appBar: AppBar(
          backgroundColor: const Color(0xFFf8fafa),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2a3435)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Color(0xFF9f403d)),
              const SizedBox(height: 16),
              Text(_error ?? 'Failed to load user'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserDetail,
                child: Text(tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _userDetail!;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf8fafa),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2a3435)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('watcher_detail'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a3435),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF535f6f)),
            onPressed: _loadUserDetail,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF535f6f)),
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildProfileHeader(detail),
              const SizedBox(height: 24),
              _buildQuickStats(detail),
              if (detail.isWatching || detail.isMutual) ...[
                const SizedBox(height: 24),
                _buildEnergyHistorySection(),
              ],
              const SizedBox(height: 24),
              _buildCareSection(),
              const SizedBox(height: 24),
              _buildMessageHistorySection(),
              const SizedBox(height: 24),
              _buildActionButtons(detail),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserDetail detail) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WatcherAvatar(
              name: _username,
              size: 90,
              showGradientBorder: true,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getEnergyColor(detail.energyLevel),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _username,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a3435),
          ),
        ),
        const SizedBox(height: 12),
        _buildRelationBadge(detail),
      ],
    );
  }

  Widget _buildRelationBadge(UserDetail detail) {
    final isMutual = detail.isMutual;
    final isPending = detail.isPending;

    String label;
    IconData icon;
    Color color;

    if (isMutual) {
      label = tr('mutual_watch');
      icon = Icons.handshake;
      color = const Color(0xFF006f1d);
    } else if (isPending) {
      label = tr('pending');
      icon = Icons.schedule;
      color = const Color(0xFFfec330);
    } else if (detail.isWatching) {
      label = tr('watching');
      icon = Icons.visibility;
      color = const Color(0xFF535f6f);
    } else if (detail.relationStatus == 'watching') {
      label = tr('watching_me');
      icon = Icons.visibility;
      color = const Color(0xFF535f6f);
    } else {
      label = tr('not_related');
      icon = Icons.person_add;
      color = const Color(0xFF727d7e);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(UserDetail detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a3435).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            Icons.bolt,
            detail.energyLevel.toUpperCase(),
            tr('energy_status'),
            _getEnergyColor(detail.energyLevel),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFd9e5e6)),
          _buildStatItem(
            Icons.favorite,
            '${detail.careStats.sentCount}/${detail.careStats.receivedCount}',
            tr('cares_sent'),
            const Color(0xFF9f403d),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFd9e5e6)),
          _buildStatItem(
            Icons.calendar_today,
            detail.daysTracking.toString(),
            tr('days'),
            const Color(0xFF535f6f),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF727d7e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyHistorySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF535f6f)),
              const SizedBox(width: 8),
              Text(
                tr('energy_history'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(tr('my_energy'), const Color(0xFF535f6f)),
              const SizedBox(width: 16),
              _buildLegendItem(_username, const Color(0xFF006f1d)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingEnergy)
            const Center(child: CircularProgressIndicator())
          else if (_myEnergyHistory == null ||
              _myEnergyHistory!.snapshots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr('no_energy_data'),
                  style: const TextStyle(color: Color(0xFF727d7e)),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: DualEnergyChart(
                myHistory: _myEnergyHistory!,
                otherHistory: _otherEnergyHistory,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF727d7e),
          ),
        ),
      ],
    );
  }

  Widget _buildCareSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFF535f6f)),
              const SizedBox(width: 8),
              Text(
                tr('send_care'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCareDialog,
              icon: const Icon(Icons.favorite),
              label: Text(tr('send_care')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9f403d),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageHistorySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF535f6f)),
              const SizedBox(width: 8),
              Text(
                tr('message_history'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a3435),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingMessages)
            const Center(child: CircularProgressIndicator())
          else if (_sentMessages.isEmpty && _receivedMessages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr('no_messages_yet'),
                  style: const TextStyle(color: Color(0xFF727d7e)),
                ),
              ),
            )
          else
            ..._buildChatBubbleList(),
        ],
      ),
    );
  }

  List<Widget> _buildChatBubbleList() {
    final List<Map<String, dynamic>> allMessages = [];

    for (final m in _sentMessages) {
      DateTime dt;
      final hasTimezone = m.createdAt.endsWith('Z') ||
          m.createdAt.contains('+') ||
          RegExp(r'-\d{2}:\d{2}$').hasMatch(m.createdAt);
      if (hasTimezone) {
        dt = DateTime.parse(m.createdAt).toLocal();
      } else {
        dt = DateTime.parse('${m.createdAt}Z').toLocal();
      }
      allMessages.add({'message': m, 'isSent': true, 'time': dt});
    }
    for (final m in _receivedMessages) {
      DateTime dt;
      final hasTimezone = m.createdAt.endsWith('Z') ||
          m.createdAt.contains('+') ||
          RegExp(r'-\d{2}:\d{2}$').hasMatch(m.createdAt);
      if (hasTimezone) {
        dt = DateTime.parse(m.createdAt).toLocal();
      } else {
        dt = DateTime.parse('${m.createdAt}Z').toLocal();
      }
      allMessages.add({'message': m, 'isSent': false, 'time': dt});
    }

    allMessages.sort(
        (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    return allMessages.map((item) {
      final message = item['message'] as CareMessage;
      final isSent = item['isSent'] as bool;
      final time = item['time'] as DateTime;
      return _buildChatBubble(message, isSent, time);
    }).toList();
  }

  Widget _buildChatBubble(CareMessage message, bool isSent, DateTime time) {
    final hasResponse =
        message.emojiResponse != null && message.emojiResponse!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFd9e5e6),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.person, size: 18, color: Color(0xFF535f6f)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.55),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSent ? const Color(0xFF006f1d) : const Color(0xFFf8fafa),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isSent ? 18 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2a3435).withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSent ? Colors.white : const Color(0xFF2a3435),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimeFromDateTime(time),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isSent ? Colors.white70 : const Color(0xFF727d7e),
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 6),
                        Icon(
                          hasResponse ? Icons.done_all : Icons.done,
                          size: 14,
                          color: hasResponse
                              ? const Color(0xFFa8e6cf)
                              : Colors.white54,
                        ),
                      ],
                      if (hasResponse && !isSent) ...[
                        const SizedBox(width: 4),
                        Text(
                          message.emojiResponse!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSent) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF006f1d).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.person, size: 18, color: Color(0xFF006f1d)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeFromDateTime(DateTime dt) {
    try {
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildActionButtons(UserDetail detail) {
    return Column(
      children: [
        if (!detail.isWatching &&
            !detail.isMutual &&
            !detail.isPending &&
            detail.relationStatus == 'none')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendWatchRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4a90d9),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                tr('send_watch_request'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (detail.isPending)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFfec330).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFFfec330)),
                const SizedBox(width: 8),
                Text(
                  tr('watch_request_pending'),
                  style: const TextStyle(color: Color(0xFFfec330)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _showRemoveConfirmation(detail),
            child: Text(
              tr('remove_watcher'),
              style: const TextStyle(
                color: Color(0xFF9f403d),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Color(0xFF9f403d)),
              title: Text(tr('block_user')),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Color(0xFF9f403d)),
              title: Text(tr('report_user')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(UserDetail detail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('remove_watcher')),
        content: Text('${tr('remove_watcher_confirm')} $_username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('watcher_removed'))),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9f403d),
            ),
            child: Text(tr('remove')),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('block_user')),
        content: Text('${tr('block_user_confirm')} $_username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('user_blocked'))),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9f403d),
            ),
            child: Text(tr('block')),
          ),
        ],
      ),
    );
  }
}
