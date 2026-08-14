import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/utils/currency_formatter.dart';
import 'package:ibuild/features/dashboard/data/models/dashboard_stats_model.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Formats values under 1 Lakh with Indian comma notation', () {
      expect(CurrencyFormatter.formatINR(25000), equals('₹25,000'));
      expect(CurrencyFormatter.formatINR(5400), equals('₹5,400'));
      expect(CurrencyFormatter.formatINR(99999), equals('₹99,999'));
    });

    test('Formats values in Lakhs (L)', () {
      expect(CurrencyFormatter.formatINR(100000), equals('₹1 L'));
      expect(CurrencyFormatter.formatINR(250000), equals('₹2.5 L'));
      expect(CurrencyFormatter.formatINR(1575000), equals('₹15.75 L'));
    });

    test('Formats values in Crores (Cr)', () {
      expect(CurrencyFormatter.formatINR(10000000), equals('₹1 Cr'));
      expect(CurrencyFormatter.formatINR(24500000), equals('₹2.45 Cr'));
      expect(CurrencyFormatter.formatINR(13800000), equals('₹1.38 Cr'));
    });
  });

  group('DashboardStats KPI Getters Tests', () {
    test('atRiskProjects returns delayed count', () {
      final stats = DashboardStats(
        totalProjects: 15,
        activeProjects: 11,
        completedProjects: 3,
        delayedProjects: 1,
        planningProjects: 0,
        employeesPresent: 10,
        totalEmployees: 12,
        totalBudget: 24500000.0,
        totalSpent: 13800000.0,
        monthlyExpense: 50000.0,
        pendingBills: 0.0,
        lowStockItems: 0,
        weeklyProgressCounts: [1, 2, 3, 4, 5, 6, 7],
        recentActivities: [],
        atRiskCount: 1,
        inventoryAlerts: [],
        portfolioProjects: [],
        progressTrends: [],
        attentionAlerts: [],
      );

      expect(stats.totalProjects, equals(15));
      expect(stats.activeProjects, equals(11));
      expect(stats.completedProjects, equals(3));
      expect(stats.atRiskProjects, equals(1));
      expect(stats.totalProjectValue, equals(24500000.0));
      expect(stats.totalSpent, equals(13800000.0));
    });
  });
}
