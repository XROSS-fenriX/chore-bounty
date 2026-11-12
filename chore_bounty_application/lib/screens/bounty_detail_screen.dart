import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../services/bounty_service.dart';
import '../widgets/avatar/user_avatar_widget.dart';
import '../widgets/bounty_form/bounty_category_icons.dart';
import '../widgets/ui.dart';
import 'create_bounty_screen.dart';
import 'user_detail_screen.dart';

typedef BountyUserTapCallback = void Function({
  required int userId,
  required String name,
  String? avatarId,
});

class BountyDetailScreen extends StatefulWidget {
  const BountyDetailScreen({
    super.key,
    required this.bounty,
    required this.currentUser,
    required this.service,
    this.memberAvatars = const {},
    this.refreshOnOpen = false,
    this.onRefresh,
    this.onUserTap,
  });

  final Bounty bounty;
  final AppUser currentUser;
  final BountyService service;
  final Map<String, String> memberAvatars;
  final bool refreshOnOpen;
  final Future<void> Function()? onRefresh;
  final BountyUserTapCallback? onUserTap;

  @override
  State<BountyDetailScreen> createState() => _BountyDetailScreenState();
}

class _BountyDetailScreenState extends State<BountyDetailScreen> {
  late TextEditingController _proofController;
  late Bounty _bounty;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bounty = widget.bounty;
    _proofController = TextEditingController(text: _bounty.submissionProof ?? '');
    if (widget.refreshOnOpen) {
      _loadFreshBounty();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (widget.refreshOnOpen) {
      _loadFreshBounty();
    }
  }

  @override
  void didUpdateWidget(covariant BountyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bounty != widget.bounty) {
      _bounty = widget.bounty;
      _proofController.text = _bounty.submissionProof ?? '';
      if (widget.refreshOnOpen) {
        _loadFreshBounty();
      }
    }
  }

  Future<void> _loadFreshBounty() async {
    if (_bounty.id.isEmpty) return;
    try {
      final fresh = await widget.service.show(_bounty.id);
      if (!mounted) return;
      setState(() {
        _bounty = fresh;
        if (_proofController.text.isEmpty &&
            (fresh.submissionProof?.isNotEmpty ?? false)) {
          _proofController.text = fresh.submissionProof!;
        }
      });
    } catch (_) {
      // Retain existing bounty details when refresh cannot complete.
    }
  }

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  bool get _isAssignee =>
      _bounty.assigneeId != null &&
      _bounty.assigneeId == widget.currentUser.id.toString();

  bool get _isCreator =>
      _bounty.creatorId.isNotEmpty &&
      _bounty.creatorId == widget.currentUser.id.toString();

  String? _resolveAvatar({
    required bool isCurrentUser,
    required String? bountyAvatar,
    required String? userId,
  }) {
    if (isCurrentUser && (widget.currentUser.avatar?.isNotEmpty ?? false)) {
      return widget.currentUser.avatar;
    }
    if (bountyAvatar != null && bountyAvatar.isNotEmpty) {
      return bountyAvatar;
    }
    if (userId != null && userId.isNotEmpty) {
      final fromMap = widget.memberAvatars[userId];
      if (fromMap != null && fromMap.isNotEmpty) {
        return fromMap;
      }
    }
    return null;
  }

  void _handleProfileTap({
    required String? rawUserId,
    required String name,
    String? avatarId,
  }) {
    final parsedId = int.tryParse((rawUserId ?? '').trim());
    if (parsedId == null || parsedId <= 0) return;

    if (widget.onUserTap != null) {
      widget.onUserTap!(
        userId: parsedId,
        name: name,
        avatarId: avatarId,
      );
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          currentUser: widget.currentUser,
          userId: parsedId,
          name: name,
          avatarId: avatarId,
          bountyService: widget.service,
          memberAvatars: widget.memberAvatars,
          onRefresh: widget.onRefresh,
        ),
      ),
    );
  }

  String get _formattedCategory {
    return Bounty.inferCategory(
      _bounty.category,
      _bounty.title,
      _bounty.description,
    );
  }

  String _formatScheduleDate(DateTime? due) {
    if (due == null) return 'No due date';

    final now = DateTime.now();
    final isToday =
        due.year == now.year && due.month == now.month && due.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = due.year == tomorrow.year &&
        due.month == tomorrow.month &&
        due.day == tomorrow.day;

    final hour = due.hour % 12 == 0 ? 12 : due.hour % 12;
    final period = due.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = due.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $period';

    if (isToday) return 'Due today, $timeStr';
    if (isTomorrow) return 'Due tomorrow, $timeStr';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthStr =
        (due.month >= 1 && due.month <= 12) ? months[due.month - 1] : '';

    if (due.isBefore(now)) {
      return 'Past due ($monthStr ${due.day}, $timeStr)';
    }

    if (due.year == now.year) {
      return 'Due $monthStr ${due.day}, $timeStr';
    }

    return 'Due $monthStr ${due.day}, ${due.year}, $timeStr';
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Widget _buildClaimantSection() {
    final rawAssigneeName = (_bounty.assignee != null &&
            _bounty.assignee!.trim().isNotEmpty &&
            _bounty.assignee!.toLowerCase() != 'you')
        ? _bounty.assignee!.trim()
        : (_isAssignee ? widget.currentUser.name : 'Roommate');
    final assigneeDisplayName =
        _isAssignee ? '$rawAssigneeName (You)' : rawAssigneeName;

    final relevantTime = _bounty.isCompleted
        ? (_bounty.completedAt ?? _bounty.submittedAt ?? _bounty.claimedAt)
        : (_bounty.claimedAt ?? _bounty.submittedAt);
    final timeAgo = _formatTimeAgo(relevantTime);

    final proofText = _bounty.submissionProof?.trim() ?? '';
    final showProof = proofText.isNotEmpty && !(_bounty.isClaimed && _isAssignee);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _bounty.isCompleted ? 'Completed by' : 'Claimed by',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Builder(
                builder: (context) {
                  final assigneeAvatar = _resolveAvatar(
                    isCurrentUser: _isAssignee,
                    bountyAvatar: _bounty.assigneeAvatar,
                    userId: _bounty.assigneeId,
                  );
                  return UserAvatarWidget(
                    avatarId: assigneeAvatar,
                    userName: rawAssigneeName,
                    size: 40,
                    onTap: () => _handleProfileTap(
                      rawUserId: _bounty.assigneeId,
                      name: rawAssigneeName,
                      avatarId: assigneeAvatar,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  assigneeDisplayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (timeAgo.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
          if (showProof) ...[
            const SizedBox(height: 14),
            const Divider(
              color: Color(0xFFE2E8F0),
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 14),
            const Text(
              'Proof Submitted',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              proofText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (_bounty.isCancelled) {
      label = 'Cancelled';
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFDC2626);
      borderColor = const Color(0xFFFCA5A5);
    } else if (_bounty.isCompleted) {
      label = 'Completed';
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF15803D);
      borderColor = const Color(0xFF86EFAC);
    } else if (_bounty.isSubmitted) {
      label = 'Pending Review';
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
      borderColor = const Color(0xFFFDE68A);
    } else if (_bounty.isClaimed) {
      label = 'Taken';
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
      borderColor = const Color(0xFFFDE68A);
    } else if (_bounty.isPastDue) {
      label = 'Past Due';
      bgColor = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFC2410C);
      borderColor = const Color(0xFFFDBA74);
    } else {
      label = 'Available';
      bgColor = const Color(0xFF1B8354);
      textColor = Colors.white;
      borderColor = const Color(0xFF1B8354);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Future<void> _handleClaim() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.service.claim(_bounty.id);
      if (widget.onRefresh != null) await widget.onRefresh!();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bounty claimed successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.service.error(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final proof = _proofController.text.trim();
      await widget.service.submit(
        _bounty.id,
        proof: proof.isEmpty ? 'Chore finished' : proof,
      );
      if (widget.onRefresh != null) await widget.onRefresh!();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted for roommate verification!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.service.error(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAbandon() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.service.unclaim(_bounty.id);
      if (widget.onRefresh != null) await widget.onRefresh!();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bounty released.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.service.error(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerify() async {
    await _runAction(
      request: () => widget.service.verify(_bounty.id),
      successMessage: 'Bounty approved! Tokens disbursed.',
    );
  }

  Future<void> _handleReject() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const PromptInputDialog(
        title: 'Request Redo',
        subtitle:
            'Return this bounty to in-progress so the roommate can resubmit completion proof.',
        hintText: 'Optional note for the roommate...',
        confirmLabel: 'Request Redo',
        maxLines: 2,
        confirmOutlined: true,
      ),
    );

    if (result == null || !mounted) return;
    final feedback = result.trim();

    await _runAction(
      request: () => widget.service.reject(
        _bounty.id,
        feedback: feedback.isEmpty ? null : feedback,
      ),
      successMessage: 'Returned bounty to in-progress.',
    );
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBounty(
          service: widget.service,
          bountyToEdit: _bounty,
        ),
      ),
    );

    if (updated == true) {
      if (widget.onRefresh != null) await widget.onRefresh!();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bounty updated successfully!')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _runAction({
    required Future<void> Function() request,
    required String successMessage,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await request();
      if (widget.onRefresh != null) await widget.onRefresh!();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.service.error(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancel() => _runAction(
        request: () => widget.service.cancel(_bounty.id),
        successMessage: 'Bounty cancelled.',
      );

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Bounty'),
        content: const Text('Delete this bounty permanently? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runAction(
      request: () => widget.service.delete(_bounty.id),
      successMessage: 'Bounty deleted.',
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    const bgLight = Color(0xFFFAF8F5);

    final tokenAmount = _bounty.points > 0
        ? _bounty.points
        : (_bounty.rewardValue?.toInt() ?? 50);

    final posterName = (_bounty.creator.isNotEmpty && _bounty.creator.toLowerCase() != 'you')
        ? _bounty.creator
        : widget.currentUser.name;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF0F172A),
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bounty Details',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // TOP SECTION: Left Square Image/Icon + Right Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Category Icon Square Box
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: CategoryIconWidget(
                            category: _formattedCategory,
                            size: 72,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Right: Title, Token Reward Amount, Poster
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title & Status Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _bounty.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Token Reward Amount Row
                              Row(
                                children: [
                                  const BountyCoinWidget(size: 20),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '$tokenAmount Tokens',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // User (Poster of the chore) Row
                              Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final creatorAvatar = _resolveAvatar(
                                        isCurrentUser: _isCreator,
                                        bountyAvatar: _bounty.creatorAvatar,
                                        userId: _bounty.creatorId,
                                      );
                                      return UserAvatarWidget(
                                        avatarId: creatorAvatar,
                                        userName: posterName,
                                        size: 20,
                                        onTap: () => _handleProfileTap(
                                          rawUserId: _bounty.creatorId,
                                          name: posterName,
                                          avatarId: creatorAvatar,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      posterName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // MIDDLE SECTION: Description Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _bounty.description.isEmpty
                              ? 'No special instructions.'
                              : _bounty.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // SUBMISSION INPUT SECTION (active claim by current user)
                  if (_bounty.isClaimed && _isAssignee) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Submission Note / Proof',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _proofController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'e.g. Wiped the counter, took recycling out',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // DETAILS SECTION: Schedule Due Date & Category
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Row 1: Due Date with Calendar Icon
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                size: 17,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formatScheduleDate(_bounty.dueAt),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Row 2: Category with Tag Icon
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_offer_outlined,
                                size: 17,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formattedCategory,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // CLAIMED / COMPLETED & PROOF SECTION
                  if (_bounty.isClaimed || _bounty.isSubmitted || _bounty.isCompleted) ...[
                    _buildClaimantSection(),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),

            // BOTTOM ACTION BUTTON SECTION
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              color: Colors.transparent,
              child: _buildActionButton(primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Color primaryGreen) {
    if (_isLoading) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    // 1. Available chore - not creator -> "Claim This Bounty"
    if (_bounty.isAvailable && !_isCreator) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _handleClaim,
          child: const Text(
            'Claim This Bounty',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    // 2. Open chore - creator -> Single row: Edit, Cancel, Delete
    if (_bounty.isOpen && _isCreator) {
      return Row(
        children: [
          _buildCreatorActionButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            bgColor: primaryGreen,
            fgColor: Colors.white,
            onPressed: _handleEdit,
          ),
          const SizedBox(width: 8),
          _buildCreatorActionButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            bgColor: const Color(0xFFF8FAFC),
            fgColor: const Color(0xFF475569),
            borderColor: const Color(0xFFCBD5E1),
            onPressed: _handleCancel,
          ),
          const SizedBox(width: 8),
          _buildCreatorActionButton(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            bgColor: const Color(0xFFFEF2F2),
            fgColor: const Color(0xFFDC2626),
            borderColor: const Color(0xFFFCA5A5),
            onPressed: _handleDelete,
          ),
        ],
      );
    }

    // 3. Claimed chore - assignee -> "Submit for Review" + "Abandon Quest"
    if (_bounty.isClaimed && _isAssignee) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _handleSubmit,
              icon: const Icon(Icons.send_rounded, size: 20),
              label: const Text(
                'Submit for Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _handleAbandon,
            child: const Text(
              'Abandon Quest',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    // 4. Submitted chore - creator -> "Approve & Disburse Reward" + "Request Redo"
    if (_bounty.isSubmitted && _isCreator) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _handleVerify,
              icon: const Icon(Icons.verified_rounded, size: 20),
              label: const Text(
                'Approve & Disburse Reward',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                backgroundColor: const Color(0xFFFFFBEB),
                side: const BorderSide(color: Color(0xFFFDE68A), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _handleReject,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text(
                'Request Redo',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    // 5. Completed chore
    if (_bounty.isCompleted) {
      return _buildStatusBanner(
        label: 'Completed',
        icon: Icons.check_circle_rounded,
        bgColor: const Color(0xFFDCFCE7),
        fgColor: const Color(0xFF15803D),
        borderColor: const Color(0xFF86EFAC),
      );
    }

    // 6. Cancelled chore
    if (_bounty.isCancelled) {
      return _buildStatusBanner(
        label: 'Cancelled',
        icon: Icons.cancel_outlined,
        bgColor: const Color(0xFFFEF2F2),
        fgColor: const Color(0xFFDC2626),
        borderColor: const Color(0xFFFCA5A5),
      );
    }

    // 7. Past due chore (unclaimed and past its due date)
    if (_bounty.isPastDue) {
      return _buildStatusBanner(
        label: 'Past Due',
        icon: Icons.event_busy_rounded,
        bgColor: const Color(0xFFFFF7ED),
        fgColor: const Color(0xFFC2410C),
        borderColor: const Color(0xFFFDBA74),
      );
    }

    // 8. Taken or submitted chore waiting review
    if (_bounty.isSubmitted) {
      return _buildStatusBanner(
        label: 'Awaiting Review',
        icon: Icons.hourglass_top_rounded,
        bgColor: const Color(0xFFFEF3C7),
        fgColor: const Color(0xFFB45309),
        borderColor: const Color(0xFFFDE68A),
      );
    }

    if (_bounty.isClaimed) {
      return _buildStatusBanner(
        label: 'Taken',
        icon: Icons.hourglass_bottom_rounded,
        bgColor: const Color(0xFFFEF3C7),
        fgColor: const Color(0xFFB45309),
        borderColor: const Color(0xFFFDE68A),
      );
    }

    // Default: Other status
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Status: ${_bounty.status.toUpperCase()}',
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCreatorActionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const padding = EdgeInsets.symmetric(horizontal: 8);
    final child = Text(
      label,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Expanded(
      child: SizedBox(
        height: 48,
        child: borderColor != null
            ? OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: fgColor,
                  backgroundColor: bgColor,
                  side: BorderSide(color: borderColor, width: 1.2),
                  padding: padding,
                  shape: shape,
                ),
                onPressed: onPressed,
                icon: Icon(icon, size: 17),
                label: child,
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: fgColor,
                  elevation: 0,
                  padding: padding,
                  shape: shape,
                ),
                onPressed: onPressed,
                icon: Icon(icon, size: 17),
                label: child,
              ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required Color borderColor,
  }) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fgColor, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
