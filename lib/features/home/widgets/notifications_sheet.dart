import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

// ── Modèle interne ───────────────────────────────────────────────────────────

class _ReminderItem {
  TimeOfDay time;
  int intervalDays;

  _ReminderItem({required this.time, required this.intervalDays});

  factory _ReminderItem.fromMap(Map<String, dynamic> m) => _ReminderItem(
        time: TimeOfDay(
          hour: m['hour'] as int,
          minute: m['minute'] as int,
        ),
        intervalDays: (m['intervalDays'] as int?) ?? 1,
      );

  factory _ReminderItem.defaultItem() =>
      _ReminderItem(time: const TimeOfDay(hour: 10, minute: 0), intervalDays: 1);

  Map<String, dynamic> toMap() => {
        'hour': time.hour,
        'minute': time.minute,
        'intervalDays': intervalDays,
      };
}

// ── Sheet principale ─────────────────────────────────────────────────────────

class NotificationsSheet extends StatefulWidget {
  final List<Map<String, dynamic>> savedReminders;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;

  const NotificationsSheet({
    super.key,
    required this.savedReminders,
    required this.onSave,
  });

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  late List<_ReminderItem> _reminders;
  bool _saving = false;

  static const List<int> _intervals = [1, 2, 3, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    _reminders = widget.savedReminders.isEmpty
        ? [_ReminderItem.defaultItem()]
        : widget.savedReminders.map(_ReminderItem.fromMap).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _chipLabel(int days) => '${days}j';

  String _intervalDesc(int days) {
    switch (days) {
      case 1:
        return 'Tous les jours';
      case 2:
        return 'Tous les 2 jours';
      case 3:
        return 'Tous les 3 jours';
      case 7:
        return 'Toutes les semaines';
      case 14:
        return 'Toutes les 2 semaines';
      case 30:
        return 'Tous les mois';
      default:
        return 'Tous les $days jours';
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _pickTime(int index) async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminders[index].time,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminders[index].time = picked);
  }

  void _addReminder() {
    HapticFeedback.lightImpact();
    setState(() => _reminders.add(_ReminderItem.defaultItem()));
  }

  void _removeReminder(int index) {
    if (_reminders.length <= 1) return;
    HapticFeedback.lightImpact();
    setState(() => _reminders.removeAt(index));
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final data = _reminders.map((r) => r.toMap()).toList();
    await widget.onSave(data);
    if (mounted) Navigator.pop(context);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: AppColors.cream,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ─────────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 24),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rappels personnalisés',
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Planifie tes moments de pratique à l\'heure qui te convient.',
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Liste des rappels ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (int i = 0; i < _reminders.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _ReminderCard(
                        item: _reminders[i],
                        intervals: _intervals,
                        chipLabel: _chipLabel,
                        intervalDesc: _intervalDesc,
                        canDelete: _reminders.length > 1,
                        onPickTime: () => _pickTime(i),
                        onIntervalChanged: (days) =>
                            setState(() => _reminders[i].intervalDays = days),
                        onDelete: () => _removeReminder(i),
                        primary: primary,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ── Bouton "Ajouter" ─────────────────────────────────────
                    GestureDetector(
                      onTap: _addReminder,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: primary.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Ajouter un rappel',
                              style: GoogleFonts.firaSansCondensed(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bouton "Enregistrer" ─────────────────────────────────────────
            Padding(
              padding:
                  EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _saving ? primary.withValues(alpha: 0.6) : primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _saving
                        ? []
                        : [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_saving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _saving ? 'Enregistrement…' : 'Enregistrer les rappels',
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte rappel ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final _ReminderItem item;
  final List<int> intervals;
  final String Function(int) chipLabel;
  final String Function(int) intervalDesc;
  final bool canDelete;
  final VoidCallback onPickTime;
  final ValueChanged<int> onIntervalChanged;
  final VoidCallback onDelete;
  final Color primary;

  const _ReminderCard({
    required this.item,
    required this.intervals,
    required this.chipLabel,
    required this.intervalDesc,
    required this.canDelete,
    required this.onPickTime,
    required this.onIntervalChanged,
    required this.onDelete,
    required this.primary,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final primaryLight = Color.lerp(primary, Colors.white, 0.85)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne heure + description + suppression ──────────────────────
          Row(
            children: [
              // Bouton heure
              GestureDetector(
                onTap: onPickTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, color: primary, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        _fmt(item.time),
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  intervalDesc(item.intervalDays),
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.close_rounded,
                        color: AppColors.inkSoft, size: 18),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Chips intervalle ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: intervals.map((days) {
                final selected = days == item.intervalDays;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onIntervalChanged(days),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected
                              ? primary
                              : Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        chipLabel(days),
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
