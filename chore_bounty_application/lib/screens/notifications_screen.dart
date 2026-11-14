import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../services/bounty_service.dart';
import '../widgets/bounty_form/bounty_category_icons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.user,
    required this.bounties,
    required this.onSelectBounty,
    this.householdId,
    this.initialBounties = const [],
    this.initialNotifications = const [],
    this.onRefreshParent,
  });

  final AppUser user;
  final BountyService bounties;
  final ValueChanged<Bounty> onSelectBounty;
  final String? householdId;
  final List<Bounty> initialBounties;
  final List<AppNotification> initialNotifications;
  final Future<void> Function()? onRefreshParent;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryGreen = Color(0xFF1B8354);
  static const Color bgLight = Color(0xFFFAF8F5);

  List<AppNotification> _notifications = [];
  List<Bounty> _bounties = [];
  bool _isLoading = false;
  Timer? _realtimeTimer;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  bool _isFromOtherUser(AppNotification n) {
    return !n.isTriggeredBy(widget.user.id.toString(), widget.user.name);
  }

  @override
  void initState() {
    super.initState();
    _bounties = List<Bounty>.from(widget.initialBounties);
    if (widget.initialNotifications.isNotEmpty) {
      _notifications = widget.initialNotifications.where(_isFromOtherUser).toList();
    } else if (_bounties.isNotEmpty) {
      _notifications = AppNotification.deriveFromBounties(
        _bounties,
        readIds: widget.bounties.readNotificationIds,
        currentUserId: widget.user.id.toString(),
        currentUserName: widget.user.name,
      );
    }
    _loadData(showSpinner: _notifications.isEmpty);

    if (!_isTestEnvironment) {
      _realtimeTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _loadData(showSpinner: false),
      );
    }
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final fetchedBounties = await widget.bounties.all(
        householdId: widget.householdId,
      );
      final effectiveBounties =
          fetchedBounties.isNotEmpty ? fetchedBounties : _bounties;
      final fetchedNotifications = await widget.bounties.notifications(
        householdId: widget.householdId,
        currentUserId: widget.user.id.toString(),
        currentUserName: widget.user.name,
        fallbackBounties: effectiveBounties,
      );

      if (!mounted) return;
      setState(() {
        _bounties = effectiveBounties;
        _notifications = fetchedNotifications.where(_isFromOtherUser).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadData(showSpinner: false);
    if (widget.onRefreshParent != null) {
      await widget.onRefreshParent!();
    }
  }

  Future<void> _handleMarkAsRead(AppNotification item) async {
    if (!item.isRead) {
      setState(() {
        _notifications = _notifications
            .map((n) => n.id == item.id ? n.copyWith(isRead: true) : n)
            .toList();
      });
      await widget.bounties.markNotificationRead(item.id);
      if (widget.onRefreshParent != null) {
        await widget.onRefreshParent!();
      }
    }
  }

  Future<void> _handleMarkAllRead() async {
    final visible = _notifications.where(_isFromOtherUser).toList();
    if (visible.isEmpty) return;
    final allIds = visible.map((n) => n.id).toList();
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    await widget.bounties.markAllNotificationsRead(
      householdId: widget.householdId,
      ids: allIds,
    );
    if (widget.onRefreshParent != null) {
      await widget.onRefreshParent!();
    }
  }

  String _formatDateGroup(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(dt.year, dt.month, dt.day);

    if (target == today) return 'Today';
    if (target == yesterday) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr =
        (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
    return '$monthStr ${dt.day}, ${dt.year}';
  }

  Map<String, List<AppNotification>> _groupByDate(
    List<AppNotification> items,
  ) {
    final grouped = <String, List<AppNotification>>{};
    for (final item in items) {
      final label = _formatDateGroup(item.createdAt);
      grouped.putIfAbsent(label, () => []).add(item);
    }
    return grouped;
  }

  Color _circleBgForCategory(String category, String eventType) {
    switch (eventType) {
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      case 'awarded':
        return const Color(0xFFDCFCE7);
      case 'submitted':
        return const Color(0xFFFEF3C7);
    }
    switch (category.toLowerCase()) {
      case 'laundry':
        return const Color(0xFFEDE9FE);
      case 'cleaning':
        return const Color(0xFFFEF3C7);
      case 'kitchen':
      case 'dishes':
        return const Color(0xFFFFEDD5);
      case 'groceries':
      case 'shopping':
        return const Color(0xFFE0F2FE);
      case 'trash':
        return const Color(0xFFD1FAE5);
      case 'maintenance':
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _notifications.where(_isFromOtherUser).toList();
    final hasUnread = visible.any((n) => !n.isRead);
    final grouped = _groupByDate(visible);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF0F172A),
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: FilledButton(
                onPressed: hasUnread ? _handleMarkAllRead : null,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryGreen.withAlpha(120),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              color: primaryGreen,
              backgroundColor: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  if (_notifications.isEmpty)
                    _buildEmptyState()
                  else
                    for (final entry in grouped.entries) ...[
                      _buildDateDivider(entry.key),
                      const SizedBox(height: 14),
                      ...entry.value.map(_buildNotificationCard),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
    );
  }

  Widget _buildDateDivider(String dateLabel) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    final isUnread = !item.isRead;
    final circleBg = _circleBgForCategory(item.category, item.eventType);

    return Container(
      key: ValueKey('notification_card_${item.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _handleMarkAsRead(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Left Circular Icon matching wireframe
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: CategoryIconWidget(
                    category: item.category,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // Event Name & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.eventName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: isUnread
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF475569),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: isUnread
                              ? const Color(0xFF334155)
                              : const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Unread / Read status indicator
                if (isUnread)
                  Container(
                    key: ValueKey('unread_dot_${item.id}'),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const Icon(
                    Icons.done_all_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 42,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'All caught up',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Real-time notifications for posted, claimed, submitted, awarded, and cancelled chores will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
