import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bounty_category_icons.dart';

class BountyRewardSelector extends StatelessWidget {
  const BountyRewardSelector({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<int>? onChanged;

  int get _currentValue => int.tryParse(controller.text) ?? 50;

  void _increment(int amount) {
    final current = _currentValue;
    final updated = current + amount;
    controller.text = updated.toString();
    if (onChanged != null) onChanged!(updated);
  }

  void _showQuickSelect(BuildContext context) {
    showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = [10, 20, 25, 50, 75, 100, 150, 200, 250, 500];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Bounty Reward (Coins)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((opt) {
                    final isSel = _currentValue == opt;
                    return ChoiceChip(
                      label: Text(
                        '$opt Coins',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFF1B8354),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (val) {
                        Navigator.pop(ctx, opt);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    ).then((val) {
      if (val != null) {
        controller.text = val.toString();
        if (onChanged != null) onChanged!(val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Reward Box
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Row(
            children: [
              const BountyCoinWidget(size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  cursorColor: const Color(0xFF1B8354),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '50',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  onChanged: (text) {
                    final val = int.tryParse(text);
                    if (val != null && onChanged != null) {
                      onChanged!(val);
                    }
                  },
                ),
              ),
              InkWell(
                onTap: () => _showQuickSelect(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quick Increment Pills: +10, +20, +50, +100
        Row(
          children: [
            _buildIncrementPill(10),
            const SizedBox(width: 8),
            _buildIncrementPill(20),
            const SizedBox(width: 8),
            _buildIncrementPill(50),
            const SizedBox(width: 8),
            _buildIncrementPill(100),
          ],
        ),
      ],
    );
  }

  Widget _buildIncrementPill(int amount) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _increment(amount),
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF1B8354).withAlpha(30),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Text(
              '+$amount',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

