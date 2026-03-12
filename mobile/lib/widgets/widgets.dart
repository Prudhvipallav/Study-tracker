import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';

/// Shared reusable widgets for StudentTrack Pro Mobile

// ── XP Bar ────────────────────────────────────────────────────────────────
class XpBarWidget extends StatelessWidget {
  final int xp;
  final int level;
  const XpBarWidget({super.key, required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    final progress = (xp % 500) / 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level $level', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$xp XP', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: ThemeManager.surface2,
            valueColor: AlwaysStoppedAnimation(ThemeManager.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text('${(progress * 100).toInt()}% to Level ${level + 1}',
            style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const StatCard({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeManager.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ThemeManager.border),
        boxShadow: [BoxShadow(color: ThemeManager.primary.withAlpha(20), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: TextStyle(color: ThemeManager.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Stream Badge ──────────────────────────────────────────────────────────
class StreamBadge extends StatelessWidget {
  final String stream;
  const StreamBadge({super.key, required this.stream});

  static const _icons = {
    'engineering': '🔧',
    'medical': '🩺',
    'law': '⚖️',
    'competitive': '📖',
  };
  static const _names = {
    'engineering': 'Engineering',
    'medical': 'Medical',
    'law': 'Law',
    'competitive': 'Competitive',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeManager.primary.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeManager.primary.withAlpha(102)),
      ),
      child: Text(
        '${_icons[stream] ?? '🎓'} ${_names[stream] ?? stream}',
        style: TextStyle(color: ThemeManager.primary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Mood Picker ───────────────────────────────────────────────────────────
class MoodPicker extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelect;
  const MoodPicker({super.key, required this.selected, required this.onSelect});

  static const moods = ['😞', '😕', '😐', '😊', '😄'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final mood = i + 1;
        final isSelected = selected == mood;
        return GestureDetector(
          onTap: () => onSelect(mood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? ThemeManager.primary.withAlpha(51) : ThemeManager.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isSelected ? ThemeManager.primary : ThemeManager.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(moods[i], style: TextStyle(fontSize: isSelected ? 28 : 22)),
            ),
          ),
        );
      }),
    );
  }
}

// ── Goal Progress Card ───────────────────────────────────────────────────
class GoalProgressCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback? onTap;
  const GoalProgressCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = ((goal['progress_percent'] as int?) ?? 0) / 100.0;
    final deadline = goal['deadline'] as String?;
    String daysLeft = '';
    if (deadline != null) {
      final d = DateTime.tryParse(deadline);
      if (d != null) {
        final diff = d.difference(DateTime.now()).inDays;
        daysLeft = diff >= 0 ? '$diff days left' : 'Overdue';
      }
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ThemeManager.card,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: ThemeManager.primary, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(goal['title'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                if (daysLeft.isNotEmpty)
                  Text(daysLeft, style: TextStyle(color: daysLeft == 'Overdue' ? ThemeManager.danger : ThemeManager.textSecondary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: ThemeManager.surface2,
              valueColor: AlwaysStoppedAnimation(ThemeManager.primary),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).toInt()}% complete', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Badge Card ────────────────────────────────────────────────────────────
class BadgeCard extends StatelessWidget {
  final String icon;
  final String name;
  final bool earned;
  final String? earnedAt;
  final VoidCallback? onTap;
  const BadgeCard({super.key, required this.icon, required this.name, required this.earned, this.earnedAt, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: earned ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeManager.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: earned ? ThemeManager.primary.withAlpha(128) : ThemeManager.border),
            boxShadow: earned ? [BoxShadow(color: ThemeManager.primary.withAlpha(38), blurRadius: 8)] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(earned ? icon : '🔒', style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                earned ? name : '???',
                style: TextStyle(color: ThemeManager.textColor, fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Countdown Card ───────────────────────────────────────────────────────
class CountdownCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback? onDelete;
  const CountdownCard({super.key, required this.exam, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final examDate = DateTime.tryParse(exam['exam_date'] as String? ?? '');
    int days = examDate != null ? examDate.difference(DateTime.now()).inDays : 0;
    Color borderColor = days > 30 ? ThemeManager.success : days > 7 ? ThemeManager.warning : ThemeManager.danger;
    String tag = days > 30 ? '📅 Plan ahead!' : days > 7 ? '⚡ Getting close!' : days > 0 ? '🔥 Final stretch!' : '😱 Today!';

    return Dismissible(
      key: Key('countdown_${exam['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: ThemeManager.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeManager.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text('$days', style: TextStyle(color: borderColor, fontSize: 40, fontWeight: FontWeight.bold)),
                Text('days', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam['title'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                  if (exam['subject'] != null && (exam['subject'] as String).isNotEmpty)
                    Chip(label: Text(exam['subject'] as String, style: const TextStyle(fontSize: 11)), backgroundColor: ThemeManager.surface2),
                  Text(tag, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
