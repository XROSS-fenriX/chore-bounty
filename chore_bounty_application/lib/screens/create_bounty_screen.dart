import 'package:flutter/material.dart';
import '../services/bounty_service.dart';
import '../widgets/bounty_form/bounty_category_grid.dart';
import '../widgets/bounty_form/bounty_date_time_picker.dart';
import '../widgets/bounty_form/bounty_field_label.dart';
import '../widgets/bounty_form/bounty_reward_selector.dart';
import '../widgets/bounty_form/bounty_text_input.dart';

class CreateBounty extends StatefulWidget {
  const CreateBounty({
    super.key,
    required this.service,
    this.currentHouseholdId,
  });

  final BountyService service;
  final int? currentHouseholdId;

  @override
  State<CreateBounty> createState() => _CreateBountyState();
}

class _CreateBountyState extends State<CreateBounty> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController(text: '50');

  String _selectedCategory = 'Cleaning';
  DateTime? _dueDate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  String get _difficulty {
    switch (_selectedCategory.toLowerCase()) {
      case 'kitchen':
      case 'maintenance':
        return 'hard';
      case 'cleaning':
      case 'laundry':
        return 'medium';
      case 'groceries':
      case 'other':
      default:
        return 'easy';
    }
  }

  int get _xpReward {
    switch (_difficulty) {
      case 'epic':
        return 250;
      case 'hard':
        return 200;
      case 'medium':
        return 100;
      case 'easy':
      default:
        return 50;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rewardValue = double.tryParse(_rewardController.text.trim()) ?? 50.0;
    if (rewardValue <= 0) {
      setState(() => _error = 'Please enter a valid reward amount');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'difficulty': _difficulty,
        'xp_reward': _xpReward,
        'reward_value': rewardValue,
        'reward_description': '${rewardValue.toInt()} Coins',
      };

      if (_dueDate != null) {
        payload['due_at'] = _dueDate!.toIso8601String();
      }

      if (widget.currentHouseholdId != null) {
        payload['household_id'] = widget.currentHouseholdId;
      }

      await widget.service.create(payload);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = widget.service.error(e));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFAF8F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF1E293B),
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Bounty',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Title Field
              const BountyFieldLabel(label: 'Title', isRequired: true),
              BountyTextInput(
                controller: _titleController,
                hintText: 'e.g, Take out the trash',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a chore title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              const BountyFieldLabel(label: 'Description'),
              BountyTextInput(
                controller: _descriptionController,
                hintText: 'Add details or instructions...',
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 20),

              // Reward Field
              const BountyFieldLabel(label: 'Reward', isRequired: true),
              BountyRewardSelector(
                controller: _rewardController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Category Grid
              const BountyFieldLabel(label: 'Category', isRequired: true),
              BountyCategoryGrid(
                selectedCategory: _selectedCategory,
                onSelect: (cat) {
                  setState(() => _selectedCategory = cat);
                },
              ),
              const SizedBox(height: 20),

              // Due Date Field
              const BountyFieldLabel(label: 'Due Date'),
              BountyDateTimePicker(
                selectedDate: _dueDate,
                onChanged: (dt) {
                  setState(() => _dueDate = dt);
                },
              ),
              const SizedBox(height: 24),

              // Error banner if any
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Post Bounty Button
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8354),
                    disabledBackgroundColor: const Color(0xFF86EFAC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post Bounty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

