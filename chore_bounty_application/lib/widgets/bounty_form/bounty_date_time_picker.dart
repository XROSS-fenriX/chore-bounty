import 'package:flutter/material.dart';

class BountyDateTimePicker extends StatelessWidget {
  const BountyDateTimePicker({
    super.key,
    required this.selectedDate,
    required this.onChanged,
    this.requireFuture = true,
    this.errorText,
    this.onInvalidSelection,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChanged;
  final bool requireFuture;
  final String? errorText;
  final ValueChanged<String>? onInvalidSelection;

  static const futureErrorMessage = 'Due date and time must be in the future.';

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateUtils.dateOnly(dt);
    final isToday = target == today;
    final isTomorrow = target == tomorrow;

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $period';

    if (isToday) return 'Today • $timeStr';
    if (isTomorrow) return 'Tomorrow • $timeStr';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $timeStr';
  }

  TimeOfDay _resolveInitialTime(DateTime chosenDate, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final isChosenToday = DateUtils.dateOnly(chosenDate) == today;

    if (selectedDate != null) {
      final candidate = DateTime(
        chosenDate.year,
        chosenDate.month,
        chosenDate.day,
        selectedDate!.hour,
        selectedDate!.minute,
      );
      if (!requireFuture || candidate.isAfter(now)) {
        return TimeOfDay.fromDateTime(selectedDate!);
      }
    }

    if (isChosenToday) {
      final oneHourLater = now.add(const Duration(hours: 1));
      if (DateUtils.dateOnly(oneHourLater) == today) {
        return TimeOfDay.fromDateTime(oneHourLater);
      }
      return const TimeOfDay(hour: 23, minute: 59);
    }

    return TimeOfDay.fromDateTime(now.add(const Duration(hours: 4)));
  }

  Future<void> _pickDateTime(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final lastDate = today.add(const Duration(days: 365));

    DateTime initialDate = selectedDate != null
        ? DateUtils.dateOnly(selectedDate!)
        : DateUtils.dateOnly(now.add(const Duration(hours: 4)));
    if (initialDate.isBefore(today)) initialDate = today;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B8354),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !context.mounted) return;

    final currentNow = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: _resolveInitialTime(date, currentNow),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B8354),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (requireFuture && !picked.isAfter(DateTime.now())) {
      if (onInvalidSelection != null) {
        onInvalidSelection!(futureErrorMessage);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(futureErrorMessage)),
        );
      }
      return;
    }

    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _pickDateTime(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: hasError
                        ? const Color(0xFFDC2626)
                        : (hasDate
                            ? const Color(0xFF1B8354)
                            : const Color(0xFF64748B)),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasDate ? _formatDateTime(selectedDate!) : 'Select date and time',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                        color: hasDate ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  if (hasDate || hasError)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: hasError
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF94A3B8),
                      ),
                      onPressed: () => onChanged(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    )
                  else
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

