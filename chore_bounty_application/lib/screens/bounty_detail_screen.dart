import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../services/bounty_service.dart';
import '../widgets/avatar/user_avatar_widget.dart';
import '../widgets/bounty_detail/bounty_info_card.dart';
import '../widgets/bounty_detail/bounty_proof_gallery.dart';
import '../widgets/bounty_detail/bounty_proof_input_card.dart';
import '../widgets/bounty_detail/creator_action_bar.dart';
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
    this.pickProofImage,
  });

  final Bounty bounty;
  final AppUser currentUser;
  final BountyService service;
  final Map<String, String> memberAvatars;
  final bool refreshOnOpen;
  final Future<void> Function()? onRefresh;
  final BountyUserTapCallback? onUserTap;
  final ProofImagePicker? pickProofImage;

  @override
  State<BountyDetailScreen> createState() => _BountyDetailScreenState();
}

class _BountyDetailScreenState extends State<BountyDetailScreen> {
  late TextEditingController _proofController;
  late Bounty _bounty;
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _selectedProofImages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _proofValidationError;

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
      (_bounty.creatorId.isNotEmpty &&
          _bounty.creatorId == widget.currentUser.id.toString()) ||
      (_bounty.creatorId.isEmpty &&
          _bounty.creator.trim().toLowerCase() ==
              widget.currentUser.name.trim().toLowerCase());

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
    final proofImages = _bounty.submissionImages;
    final hasProofImages = proofImages.isNotEmpty;
    final showProof =
        (proofText.isNotEmpty || hasProofImages) &&
        !(_bounty.isClaimed && _isAssignee);
    final hasValidAssigneeId =
        (int.tryParse((_bounty.assigneeId ?? '').trim()) ?? 0) > 0;
    final assigneeAvatar = _resolveAvatar(
      isCurrentUser: _isAssignee,
      bountyAvatar: _bounty.assigneeAvatar,
      userId: _bounty.assigneeId,
    );

    void openAssigneeProfile() => _handleProfileTap(
          rawUserId: _bounty.assigneeId,
          name: rawAssigneeName,
          avatarId: assigneeAvatar,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Text(
                _bounty.isCompleted ? 'Completed by' : 'Claimed by',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              if (timeAgo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    timeAgo,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: hasValidAssigneeId ? openAssigneeProfile : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  UserAvatarWidget(
                    avatarId: assigneeAvatar,
                    userName: rawAssigneeName,
                    size: 38,
                    onTap: hasValidAssigneeId ? openAssigneeProfile : null,
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
                  if (hasValidAssigneeId)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                ],
              ),
            ),
          ),
          if (showProof) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Proof Submitted',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (hasProofImages) ...[
                    const SizedBox(height: 8),
                    BountyProofGallery(imageUrls: proofImages),
                  ],
                  if (proofText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      proofText,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
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
        const SnackBar(content: Text('Chore claimed successfully!')),
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

  Future<void> _handlePickProofImage(ImageSource source) async {
    if (_selectedProofImages.length >= 3) return;
    try {
      String? pickedPath;
      if (widget.pickProofImage != null) {
        pickedPath = await widget.pickProofImage!(source);
      } else {
        final picked = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 80,
        );
        pickedPath = picked?.path;
      }

      if (!mounted || pickedPath == null || pickedPath.trim().isEmpty) return;
      setState(() {
        if (_selectedProofImages.length < 3) {
          _selectedProofImages.add(pickedPath!.trim());
        }
        _proofValidationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to open camera or gallery: $e';
      });
    }
  }

  void _handleRemoveProofImage(int index) {
    if (index < 0 || index >= _selectedProofImages.length) return;
    setState(() {
      _selectedProofImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedProofImages.isEmpty) {
      setState(() {
        _proofValidationError =
            'Please take at least one photo as proof before submitting.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _proofValidationError = null;
    });

    try {
      final proof = _proofController.text.trim();
      await widget.service.submit(
        _bounty.id,
        proof: proof.isEmpty ? 'Photo proof submitted' : proof,
        imagePaths: List<String>.from(_selectedProofImages),
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
        const SnackBar(content: Text('Chore released.')),
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.service.verify(_bounty.id);
      if (widget.onRefresh != null) await widget.onRefresh!();
      if (!mounted) return;
      setState(() => _isLoading = false);

      final tokenAmount = _bounty.points > 0
          ? _bounty.points
          : (_bounty.rewardValue?.toInt() ?? 50);
      final assigneeName =
          (_bounty.assignee != null && _bounty.assignee!.trim().isNotEmpty)
              ? _bounty.assignee!.trim()
              : 'Roommate';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF1B8354),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chore Approved!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You approved "${_bounty.title}" completed by $assigneeName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BountyCoinWidget(size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+$tokenAmount Tokens Awarded',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8354),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.service.error(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReject() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const PromptInputDialog(
        title: 'Request Redo',
        subtitle:
            'Return this chore to in-progress so the roommate can resubmit completion proof.',
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
      successMessage: 'Returned chore to in-progress.',
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
        const SnackBar(content: Text('Chore updated successfully!')),
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

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Chore'),
        content: Text(
          _bounty.isTaken
              ? 'Cancel this chore? The roommate who claimed it will be released and notified.'
              : 'Cancel this chore?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Chore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runAction(
      request: () => widget.service.cancel(_bounty.id),
      successMessage: 'Chore cancelled.',
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Chore'),
        content: const Text('Delete this chore permanently? This cannot be undone.'),
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
      successMessage: 'Chore deleted.',
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
    final creatorAvatar = _resolveAvatar(
      isCurrentUser: _isCreator,
      bountyAvatar: _bounty.creatorAvatar,
      userId: _bounty.creatorId,
    );

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
          'Chore Details',
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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

                      // TOP CARD: Minimalist Chore Overview, Description & Metadata
                      BountyInfoCard(
                        bounty: _bounty,
                        formattedCategory: _formattedCategory,
                        tokenAmount: tokenAmount,
                        posterName: posterName,
                        creatorAvatar: creatorAvatar,
                        onCreatorTap: () => _handleProfileTap(
                          rawUserId: _bounty.creatorId,
                          name: posterName,
                          avatarId: creatorAvatar,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // SUBMISSION INPUT SECTION (active claim by current user)
                      if (_bounty.isClaimed && _isAssignee) ...[
                        BountyProofInputCard(
                          controller: _proofController,
                          imagePaths: _selectedProofImages,
                          onPickImage: _handlePickProofImage,
                          onRemoveImage: _handleRemoveProofImage,
                          validationError: _proofValidationError,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // CLAIMED / COMPLETED & PROOF SECTION
                      if (_bounty.isClaimed || _bounty.isSubmitted || _bounty.isCompleted) ...[
                        _buildClaimantSection(),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
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
            'Claim This Chore',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    // 2. Creator actions by state (Available: Edit + Delete, Taken: Edit + Cancel, Cancelled/Expired: Delete)
    if (_isCreator &&
        (_bounty.canEdit || _bounty.canCancel || _bounty.canDelete)) {
      return CreatorActionBar(
        bounty: _bounty,
        onEdit: _handleEdit,
        onCancel: _handleCancel,
        onDelete: _handleDelete,
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

    // 8. Taken or submitted chore awaiting review
    if (_bounty.isSubmitted) {
      return _buildStatusBanner(
        label: 'Awaiting Review',
        icon: Icons.hourglass_top_rounded,
        bgColor: const Color(0xFFEEF2FF),
        fgColor: const Color(0xFF4338CA),
        borderColor: const Color(0xFFC7D2FE),
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
