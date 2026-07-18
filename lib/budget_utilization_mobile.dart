import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

class BudgetUtilizationMobile extends StatelessWidget {
  final VoidCallback onBack;

  const BudgetUtilizationMobile({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: onBack,
        ),
        title: const Text(
          'IBUILD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headline
            const Text(
              'Skyline Apartments: Budget',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const Text(
              'Q4 2024 Financial Overview',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Budget Chart Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    offset: Offset(0, 4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Donut Chart
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: DonutChartPainter(
                              segments: [
                                ChartSegment(
                                  0.45,
                                  AppColors.primaryContainer,
                                ), // Labor
                                ChartSegment(
                                  0.25,
                                  AppColors.secondary,
                                ), // Materials
                                ChartSegment(
                                  0.20,
                                  AppColors.warning,
                                ), // Equipment
                                ChartSegment(
                                  0.10,
                                  AppColors.borderSubtle,
                                ), // Others
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹2.4Cr',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMain,
                                    ),
                              ),
                              const Text(
                                'TOTAL UTILIZATION',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Legend
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 8,
                    children: [
                      _buildLegendItem('Labor', AppColors.primaryContainer),
                      _buildLegendItem('Materials', AppColors.secondary),
                      _buildLegendItem('Equipment', AppColors.warning),
                      _buildLegendItem('Others', AppColors.borderSubtle),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Budget Breakdown
            const Text(
              'BUDGET BREAKDOWN',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildBreakdownItem(
                    icon: Icons.groups,
                    iconColor: AppColors.primary,
                    title: 'Labor',
                    amount: '₹10,80,000',
                    percent: 0.45,
                    progressBarColor: AppColors.primary,
                    showDivider: true,
                  ),
                  _buildBreakdownItem(
                    icon: Icons.inventory_2,
                    iconColor: AppColors.secondary,
                    title: 'Materials',
                    amount: '₹6,00,000',
                    percent: 0.25,
                    progressBarColor: AppColors.secondary,
                    showDivider: true,
                  ),
                  _buildBreakdownItem(
                    icon: Icons.precision_manufacturing,
                    iconColor: AppColors.warning,
                    title: 'Equipment',
                    amount: '₹4,80,000',
                    percent: 0.20,
                    progressBarColor: AppColors.warning,
                    showDivider: true,
                  ),
                  _buildBreakdownItem(
                    icon: Icons.description,
                    iconColor: AppColors.outline,
                    title: 'Permits',
                    amount: '₹1,20,000',
                    percent: 0.05,
                    progressBarColor: AppColors.outline,
                    showDivider: true,
                  ),
                  _buildBreakdownItem(
                    icon: Icons.local_shipping,
                    iconColor: AppColors.outline,
                    title: 'Logistics',
                    amount: '₹1,20,000',
                    percent: 0.05,
                    progressBarColor: AppColors.outline,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // CTA Button
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Full Report',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textMain),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required double percent,
    required Color progressBarColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        '${(percent * 100).toInt()}% of total',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            color: AppColors.borderSubtle,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class ChartSegment {
  final double sweepPercentage;
  final Color color;

  ChartSegment(this.sweepPercentage, this.color);
}

class DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;

  DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.12;
    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint backgroundPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    double startAngle = -pi / 2;

    for (var segment in segments) {
      final Paint segmentPaint = Paint()
        ..color = segment.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      final double sweepAngle = segment.sweepPercentage * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
