import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';
import '../../data/models/dashboard_stats_model.dart';

/// Primary BI visualization plotting Physical Progress % vs Budget Used %.
/// Allows owners/admins to visually spot financial variance risks and tap
/// project points for interactive details.
class ProjectPerformanceMatrixWidget extends StatefulWidget {
  final List<PortfolioProjectItem> projects;

  const ProjectPerformanceMatrixWidget({
    super.key,
    required this.projects,
  });

  @override
  State<ProjectPerformanceMatrixWidget> createState() =>
      _ProjectPerformanceMatrixWidgetState();
}

class _ProjectPerformanceMatrixWidgetState
    extends State<ProjectPerformanceMatrixWidget> {
  PortfolioProjectItem? _selectedProject;

  @override
  void initState() {
    super.initState();
    if (widget.projects.isNotEmpty) {
      _selectedProject = widget.projects.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROJECT PERFORMANCE MATRIX',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Physical progress vs budget consumed',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              _buildMatrixLegend(),
            ],
          ),
          const Divider(height: 24),

          if (widget.projects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No portfolio performance matrix data available',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 240,
              child: ScatterChart(
                ScatterChartData(
                  minX: 0,
                  maxX: 100,
                  minY: 0,
                  maxY: 100,
                  scatterSpots: _buildScatterSpots(),
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchCallback: (FlTouchEvent event, ScatterTouchResponse? touchResponse) {
                      if (touchResponse != null && touchResponse.touchedSpot != null) {
                        final spotIndex = touchResponse.touchedSpot!.spotIndex;
                        if (spotIndex >= 0 && spotIndex < widget.projects.length) {
                          setState(() {
                            _selectedProject = widget.projects[spotIndex];
                          });
                        }
                      }
                    },
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'PHYSICAL PROGRESS %',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 25,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}%',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(
                          'BUDGET USED %',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 25,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}%',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.border(context)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (_selectedProject != null) _buildSelectedProjectCard(context, _selectedProject!),
          ],
        ],
      ),
    );
  }

  List<ScatterSpot> _buildScatterSpots() {
    return widget.projects.map((p) {
      final x = p.physicalProgress.clamp(0.0, 100.0);
      final y = p.budgetUtilizationPct.clamp(0.0, 100.0);
      final isSelected = _selectedProject?.id == p.id;
      final spotColor = _getSpotColor(p);

      return ScatterSpot(
        x,
        y,
        dotPainter: FlDotCirclePainter(
          color: spotColor,
          radius: isSelected ? 9.0 : 6.0,
          strokeWidth: isSelected ? 2.0 : 0.0,
          strokeColor: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getSpotColor(PortfolioProjectItem p) {
    if (p.variancePct > 15.0 || p.status == 'delayed' || p.status == 'at_risk') {
      return AppColors.error;
    }
    if (p.physicalProgress >= p.budgetUtilizationPct) {
      return const Color(0xFF2196F3); // Efficient / Positive
    }
    return const Color(0xFF4CAF50); // On Track
  }

  Widget _buildMatrixLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(AppColors.error, 'At Risk'),
        const SizedBox(width: 8),
        _dot(const Color(0xFF4CAF50), 'On Track'),
        const SizedBox(width: 8),
        _dot(const Color(0xFF2196F3), 'Efficient'),
      ],
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSelectedProjectCard(BuildContext context, PortfolioProjectItem p) {
    final variance = p.variancePct;
    final isAhead = variance > 0;
    final varStr = isAhead
        ? '+${variance.toStringAsFixed(0)}%'
        : '${variance.toStringAsFixed(0)}%';
    final varColor = variance > 15.0
        ? AppColors.error
        : (variance < 0 ? const Color(0xFF2196F3) : const Color(0xFF4CAF50));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Physical Progress: ${p.physicalProgress.toStringAsFixed(0)}%  •  Budget Used: ${p.budgetUtilizationPct.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: varColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Variance: $varStr',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: varColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(
                    projectId: p.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
