import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';

/// Web project detail screen — content only.
/// The sidebar and header are provided by the MainRouterScreen shell.
class ProjectDetailWeb extends StatefulWidget {
  const ProjectDetailWeb({super.key});

  @override
  State<ProjectDetailWeb> createState() => _ProjectDetailWebState();
}

class _ProjectDetailWebState extends State<ProjectDetailWeb> {
  int _activeTab = 0; // 0: Details, 1: Timeline, 2: Documents, 3: Reports

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation Tabs
            Container(
              height: 48,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  _buildTabButton('Details', 0),
                  const SizedBox(width: 32),
                  _buildTabButton('Timeline', 1),
                  const SizedBox(width: 32),
                  _buildTabButton('Documents', 2),
                  const SizedBox(width: 32),
                  _buildTabButton('Reports', 3),
                ],
              ),
            ),

            // Bento Grid & Split Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Area: Hero + Progress Bento
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildHeroCard(context),
                      const SizedBox(height: 24),
                      _buildBentoGrid(context),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right Area: Map + Activity
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildMapCard(context),
                      const SizedBox(height: 24),
                      _buildTimelineCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final bool isActive = _activeTab == index;
    return TextButton(
      onPressed: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skyline Apartments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Luxury residential development featuring 45 units with sustainable building certifications. Currently in the structural steel and utility roughed-in phase.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildHeroActionBtn(Icons.edit, 'Edit Project'),
                    const SizedBox(width: 12),
                    _buildHeroActionBtn(Icons.ios_share, 'Export Report'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActionBtn(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 14, color: AppColors.textMain),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMain,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return Column(
      children: [
        // Top full-width progress card
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROJECT OVERVIEW',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '64%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+12% this week',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  value: 0.64,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Two columns grid below
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.task_alt,
                iconColor: AppColors.primary,
                bgColor: AppColors.primary.withOpacity(0.05),
                title: 'Tasks',
                value: '10/25',
                subtitle: '4 milestones reached',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.group,
                iconColor: AppColors.secondary,
                bgColor: AppColors.secondary.withOpacity(0.05),
                title: 'Attendance',
                value: '12 Present',
                subtitle: '100% capacity',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Materials Pending Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Materials Pending',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Structural Steel, Ready-mix',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Text(
                  '2 pending',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SITE LOCATION',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View Map', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDs5oEkwzxXPuVQDNHj5vC2T2nFhfn4FiR448WH1JN357HpKdImty0oEcWGEyj4TPSZGcoL_mRnt665nnzCLfxULUYUgvLaotkhgT-Qmkc1AhSLrcr89ubG-Nd2yRjUCYvMRKXVrX6xMdIyw35fI6tc00Mwy10DqKt1PKgBUxDG4KZ_YktKG_q2ddwnyvQlAQaD5RpR93r9DVddToltKNPVn7DV9DGfD8fEbLPeBMmxS05SGPTrhOIgnLmsdieA5BOg2nrhzLnLLKc',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT ACTIVITY',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            Icons.check,
            AppColors.secondary,
            'Foundation Inspection Passed',
            '2 hours ago by Sarah Miller',
            false,
          ),
          _buildActivityItem(
            Icons.edit,
            AppColors.primary,
            'Daily Log Updated',
            '5 hours ago by Admin',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            if (!isLast)
              Container(width: 1.5, height: 32, color: AppColors.borderSubtle),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
