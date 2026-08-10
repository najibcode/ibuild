import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/dashboard_stats_model.dart';

/// Project Health widget rendering a donut chart (`fl_chart` PieChart) of project
/// status distribution with total project count in the center and detailed legend.
class ProjectHealthWidget extends StatelessWidget {
  final List<PortfolioProjectItem> projects;

  const ProjectHealthWidget({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final counts = _calculateStatusCounts();
    final total = projects.length;

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
          Text(
            'PROJECT HEALTH',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Portfolio status distribution',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const Divider(height: 20),

          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No active project status data',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 45,
                      startDegreeOffset: -90,
                      sections: _buildChartSections(counts, total),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PROJECTS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category Legend List
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _legendItem('On Track', counts['on_track'] ?? 0, const Color(0xFF2196F3)),
                _legendItem('At Risk', counts['at_risk'] ?? 0, AppColors.error),
                _legendItem('Delayed', counts['delayed'] ?? 0, Colors.orange),
                _legendItem('Completed', counts['completed'] ?? 0, const Color(0xFF4CAF50)),
                _legendItem('Planning', counts['planning'] ?? 0, Colors.purple),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Map<String, int> _calculateStatusCounts() {
    int onTrack = 0, atRisk = 0, delayed = 0, completed = 0, planning = 0;
    for (final p in projects) {
      if (p.status == 'completed') {
        completed++;
      } else if (p.status == 'delayed') {
        delayed++;
      } else if (p.status == 'at_risk' || p.variancePct > 15.0) {
        atRisk++;
      } else if (p.status == 'planning') {
        planning++;
      } else {
        onTrack++;
      }
    }
    return {
      'on_track': onTrack,
      'at_risk': atRisk,
      'delayed': delayed,
      'completed': completed,
      'planning': planning,
    };
  }

  List<PieChartSectionData> _buildChartSections(Map<String, int> counts, int total) {
    if (total == 0) return [];
    final List<PieChartSectionData> list = [];

    void addSection(String key, Color color) {
      final val = counts[key] ?? 0;
      if (val > 0) {
        list.add(
          PieChartSectionData(
            color: color,
            value: val.toDouble(),
            title: '',
            radius: 16,
          ),
        );
      }
    }

    addSection('on_track', const Color(0xFF2196F3));
    addSection('at_risk', AppColors.error);
    addSection('delayed', Colors.orange);
    addSection('completed', const Color(0xFF4CAF50));
    addSection('planning', Colors.purple);

    return list;
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
