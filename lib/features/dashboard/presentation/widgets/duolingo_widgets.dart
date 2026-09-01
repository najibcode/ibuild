import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/theme/app_colors.dart';
import 'package:ibuild/features/dashboard/data/models/dashboard_stats_model.dart';

// ── DUOLINGO DESIGN TOKENS ──────────────────────────────────
class DuoColors {
  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF46A302);
  static const fireOrange = Color(0xFFFF9600);
  static const fireDark = Color(0xFFCC7800);
  static const gemBlue = Color(0xFF1CB0F6);
  static const gemDark = Color(0xFF1899D6);
  static const crownGold = Color(0xFFFFC800);
  static const goldDark = Color(0xFFCCA000);
  static const heartRed = Color(0xFFFF4B4B);
  static const heartDark = Color(0xFFD63B3B);
  static const purple = Color(0xFFCE82FF);
  static const purpleDark = Color(0xFFA568CC);
  static const slateDark = Color(0xFF1E293B);
}

// ── 3D TACTILE CARD WRAPPER ─────────────────────────────────
class DuoTactileCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color bottomShadowColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const DuoTactileCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE2E8F0),
    this.bottomShadowColor = const Color(0xFFCBD5E1),
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : backgroundColor;
    final border = isDark ? const Color(0xFF334155) : borderColor;
    final bottomShadow = isDark ? const Color(0xFF0F172A) : bottomShadowColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: bottomShadow,
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── 1. DAILY SITE STREAK WIDGET ─────────────────────────────
class DuolingoStreakWidget extends StatelessWidget {
  final int streakDays;
  final VoidCallback? onTap;

  const DuolingoStreakWidget({
    super.key,
    this.streakDays = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayWeekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun

    return DuoTactileCard(
      onTap: onTap,
      borderColor: DuoColors.fireOrange.withValues(alpha: 0.3),
      bottomShadowColor: DuoColors.fireDark.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DuoColors.fireOrange, Color(0xFFFF5722)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: DuoColors.fireDark.withValues(alpha: 0.5),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '$streakDays',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY SITE STREAK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: DuoColors.fireOrange,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'You are on fire! Site active for $streakDays days',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DuoColors.crownGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('⚡', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekly Check-in Circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final isChecked = dayNum <= todayWeekday;
              final isToday = dayNum == todayWeekday;

              return Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isChecked
                          ? DuoColors.fireOrange
                          : AppColors.cardBg(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday
                            ? DuoColors.fireDark
                            : (isChecked ? DuoColors.fireOrange : AppColors.border(context)),
                        width: isToday ? 2.5 : 1.5,
                      ),
                      boxShadow: isChecked
                          ? [
                              BoxShadow(
                                color: DuoColors.fireDark.withValues(alpha: 0.4),
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isChecked
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : Text(
                              days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      color: isToday ? DuoColors.fireOrange : AppColors.mutedText(context),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── 2. DAILY SITE QUESTS & MILESTONES ─────────────────────────
class DuolingoDailyQuestsWidget extends StatefulWidget {
  final VoidCallback? onCompleteQuests;

  const DuolingoDailyQuestsWidget({super.key, this.onCompleteQuests});

  @override
  State<DuolingoDailyQuestsWidget> createState() => _DuolingoDailyQuestsWidgetState();
}

class _DuolingoDailyQuestsWidgetState extends State<DuolingoDailyQuestsWidget> {
  final List<Map<String, dynamic>> _quests = [
    {'title': 'Mark Morning Attendance', 'xp': 20, 'done': true, 'icon': Icons.how_to_reg_rounded},
    {'title': 'Upload Daily Progress Photo', 'xp': 30, 'done': true, 'icon': Icons.camera_alt_rounded},
    {'title': 'Complete 1 Safety Inspection', 'xp': 50, 'done': false, 'icon': Icons.checklist_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final completedCount = _quests.where((q) => q['done'] == true).length;
    final totalCount = _quests.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final totalXp = _quests.where((q) => q['done'] == true).fold<int>(0, (sum, q) => sum + (q['xp'] as int));

    return DuoTactileCard(
      borderColor: DuoColors.green.withValues(alpha: 0.35),
      bottomShadowColor: DuoColors.greenDark.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DuoColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: DuoColors.green, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DAILY SITE QUESTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: DuoColors.greenDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '$completedCount of $totalCount Completed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DuoColors.crownGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DuoColors.crownGold, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '+$totalXp XP',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duolingo Style Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  color: AppColors.border(context),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DuoColors.green, Color(0xFF4ADE80)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quest Items
          ..._quests.map((q) {
            final isDone = q['done'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDone
                    ? DuoColors.green.withValues(alpha: 0.08)
                    : AppColors.bg(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone
                      ? DuoColors.green.withValues(alpha: 0.3)
                      : AppColors.border(context),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        q['done'] = !isDone;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone ? DuoColors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDone ? DuoColors.greenDark : AppColors.mutedText(context),
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? AppColors.mutedText(context)
                            : AppColors.text(context),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DuoColors.crownGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${q['xp']} XP',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── 3. 1-TAP POWER ACTION LAUNCHER ───────────────────────────
class DuolingoPowerActionsWidget extends StatelessWidget {
  final VoidCallback? onAttendance;
  final VoidCallback? onDailyProgress;
  final VoidCallback? onSnags;
  final VoidCallback? onExpenses;

  const DuolingoPowerActionsWidget({
    super.key,
    this.onAttendance,
    this.onDailyProgress,
    this.onSnags,
    this.onExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'FAST ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: DuoColors.gemDark,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                title: '+ Attendance',
                icon: Icons.how_to_reg_rounded,
                color: DuoColors.green,
                shadowColor: DuoColors.greenDark,
                onTap: onAttendance,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                context,
                title: '+ Daily DPR',
                icon: Icons.camera_alt_rounded,
                color: DuoColors.gemBlue,
                shadowColor: DuoColors.gemDark,
                onTap: onDailyProgress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                title: '+ Site Snag',
                icon: Icons.warning_amber_rounded,
                color: DuoColors.fireOrange,
                shadowColor: DuoColors.fireDark,
                onTap: onSnags,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                context,
                title: '+ Expense',
                icon: Icons.payments_rounded,
                color: DuoColors.purple,
                shadowColor: DuoColors.purpleDark,
                onTap: onExpenses,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color shadowColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 3.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 4. ZERO INCIDENT SAFETY SHIELD ───────────────────────────
class DuolingoSafetyShieldWidget extends StatelessWidget {
  final int safeDays;
  final double safetyScore;
  final VoidCallback? onTap;

  const DuolingoSafetyShieldWidget({
    super.key,
    this.safeDays = 64,
    this.safetyScore = 98.8,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DuoTactileCard(
      onTap: onTap,
      borderColor: DuoColors.gemBlue.withValues(alpha: 0.3),
      bottomShadowColor: DuoColors.gemDark.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DuoColors.gemBlue, Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: DuoColors.gemDark.withValues(alpha: 0.5),
                  offset: const Offset(0, 2.5),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'ZERO INCIDENT SHIELD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: DuoColors.gemDark,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: DuoColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'GRADE A+',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: DuoColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$safeDays Days Without Incidents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                Text(
                  'Safety Score: ${safetyScore.toStringAsFixed(1)}% • 100% PPE compliant',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. LIVE MATERIAL RADAR ───────────────────────────────────
class DuolingoMaterialRadarWidget extends StatelessWidget {
  final VoidCallback? onRestockTap;

  const DuolingoMaterialRadarWidget({super.key, this.onRestockTap});

  @override
  Widget build(BuildContext context) {
    final materials = [
      {'name': 'Cement (OPC 53)', 'level': 0.82, 'unit': '410 / 500 bags', 'status': 'Optimal', 'color': DuoColors.green},
      {'name': 'TMT Rebar (12mm)', 'level': 0.35, 'unit': '3.5 / 10 Tons', 'status': 'Low Stock', 'color': DuoColors.fireOrange},
      {'name': 'River Sand', 'level': 0.65, 'unit': '650 / 1000 cft', 'status': 'Optimal', 'color': DuoColors.gemBlue},
    ];

    return DuoTactileCard(
      borderColor: DuoColors.crownGold.withValues(alpha: 0.3),
      bottomShadowColor: DuoColors.goldDark.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📦', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE MATERIAL RADAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD97706),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (onRestockTap != null)
                InkWell(
                  onTap: onRestockTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DuoColors.fireOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reorder +',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DuoColors.fireDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...materials.map((m) {
            final level = m['level'] as double;
            final color = m['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      Text(
                        m['unit'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 8, color: AppColors.border(context)),
                        FractionallySizedBox(
                          widthFactor: level,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
