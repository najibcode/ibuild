import 'package:flutter/material.dart';
import 'theme.dart';

class ProjectListMobile extends StatelessWidget {
  final Function(String projectId) onSelectProject;

  const ProjectListMobile({super.key, required this.onSelectProject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 2,
                ),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCjGlUbKqeg_BmBgnY5cPh6RC-7z7kRbgL4bJIEag2VD9D-nPu4BGsUPD71HpfpA1wL7tf0UTV89VGB85FKGYl1ijs6UC8rzGp6RLVJ1YzxBmYoX4gz9ssp6veuczexuKCizzlQ4j5Z7BO5WulxSpd3IKgI4t5ynAqGFwD0i-ovCVuvvsZlTSmc-UI-vzEJo31r9x-W188SycoyEP7yg3gfliKWaL3nU2FNpVPzw8Z0KpUMejqlKvaKUSEwHeLSB55sm5Nb_Fha5F4',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            const Text(
              'Projects',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.containerMargin),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: AppColors.primary,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      hintStyle: TextStyle(color: Color(0x8F757684)),
                      prefixIcon: Icon(Icons.search, color: AppColors.outline),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                // Horizontal Filters
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Status', true),
                      _buildFilterChip('Supervisor', false),
                      _buildFilterChip('Client', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Projects List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
              ),
              children: [
                _buildProjectCard(
                  context: context,
                  id: 'projects/6661804967842142645',
                  category: 'Commercial',
                  title: 'Skyline Apartments',
                  progress: 0.72,
                  progressColor: AppColors.primary,
                  budget: '₹2.4Cr / ₹3.1Cr',
                  deadline: 'Oct 24, 2024',
                  supervisorName: 'James Wilson',
                  supervisorAvatar:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDAcPj4ZtoWmKUNjOWl25J_1Wfe9en21yRIFqthk2ZqJRFfXWaaoaE9FceYBpLE-BDvVJFkrNvOOFqRWLeh6PpNM5jiKrGBGVuH2QBrYUSmXZDn0XsWCEI7TF8UyjehuvhAvluxkOZiBhR4qUhWZeqrhUIb7yUkORMyVjYF1ddlKJpaTQQtpjiSBUql3DXeSfviAHXXehKCrZj6wsKLe2ceEuMlUcE7Bh519zywqldOKI1exM_esk7wgEAzgErQI_C885bbf46NF_A',
                  statusText: 'On Track',
                  statusColor: AppColors.secondary,
                  statusBgColor: const Color(0x1F10B981),
                ),
                const SizedBox(height: AppSpacing.gutter),
                _buildProjectCard(
                  context: context,
                  id: 'metro_logistics_hub',
                  category: 'Industrial',
                  title: 'Metro Logistics Hub',
                  progress: 0.45,
                  progressColor: AppColors.error,
                  budget: '₹85L / ₹90L',
                  deadline: 'Aug 12, 2024',
                  supervisorName: 'Sarah Chen',
                  supervisorAvatar:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuC4-XEoqpzfc-WgrvLeDiLfN4A-bU8K-fYtsifjmhk0NtI1yyxQOmoqqE7qgZD180z33uzmLS7gxp6I6bUdYHMpfB5vAjhnxGHQ8JtrhXhXog-q07QF2gFpxa71DV4Y1LfsAjBllUHGmfG6uTVy5mEjq1KNF5hozvQeh_mP3JAZGidaHiTYk_q_Dx-Til_i119_O1GNoivAnFZJUYIMoDWnwL2Ekb5FQOeIB4ms8gEGKbOd5rv2h5lb2gZznolIWk_gg3tqeIrTdhQ',
                  statusText: 'Delayed',
                  statusColor: AppColors.error,
                  statusBgColor: const Color(0x1FBA1A1A),
                ),
                const SizedBox(height: AppSpacing.gutter),
                _buildProjectCard(
                  context: context,
                  id: 'north_bridge_upgrade',
                  category: 'Infrastructure',
                  title: 'North Bridge Upgrade',
                  progress: 0.12,
                  progressColor: AppColors.outline,
                  budget: '₹12Cr / ₹15Cr',
                  deadline: 'Dec 15, 2025',
                  supervisorName: 'Marcus Thorne',
                  supervisorAvatar:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCmRZkqgnCFty4YqRl8bkj_wkHShY2JnraSqMPhpgWnzIBbEbQc3Tc7vV9SyATWNmR9lR7I1sOUJS0UX-S7k8XKTWAjfZPgVGewkxwlj4KrunUoZVzGWNZKjG62CHQlwGGDWkUqAz6mO8GdVQFqJoWMrtcQd719LRiRwJ-Fr5dZVwK-xve4UCtdz-7vplXEGy2FZ0WKAC51c_L_jkoOXhf1cgXNNinOLWNLXUDniG29RLzrvncQAsXBB4RzGXiet19pSRluHccoK18',
                  statusText: 'Planning',
                  statusColor: AppColors.textMuted,
                  statusBgColor: AppColors.borderSubtle,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.stackSm),
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive
              ? AppColors.primary
              : AppColors.surfaceWhite,
          side: BorderSide(
            color: isActive ? AppColors.primary : AppColors.borderSubtle,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMain,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isActive ? Colors.white : AppColors.textMain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard({
    required BuildContext context,
    required String id,
    required String category,
    required String title,
    required double progress,
    required Color progressColor,
    required String budget,
    required String deadline,
    required String supervisorName,
    required String supervisorAvatar,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => onSelectProject(id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            color: progressColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Metrics
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0x1FE2E8F0)),
                      bottom: BorderSide(color: Color(0x1FE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: const Icon(
                                Icons.payments,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BUDGET',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  Text(
                                    budget,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMain,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: const Icon(
                                Icons.event,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DEADLINE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  Text(
                                    deadline,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMain,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(supervisorAvatar),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Supervisor',
                              style: TextStyle(
                                fontSize: 8,
                                color: AppColors.outline,
                              ),
                            ),
                            Text(
                              supervisorName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => onSelectProject(id),
                      child: const Row(
                        children: [
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
