import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';

enum DashboardWidgetType {
  dailyStreak('daily_streak', '🔥 Daily Site Streak', 'Streak counter with flame animation & week check-ins', 'Streaks & Gamification', Icons.local_fire_department_rounded),
  dailyQuests('daily_quests', '🎯 Daily Site Quests', 'Gamified punch-list quests with XP and rewards', 'Streaks & Gamification', Icons.emoji_events_rounded),
  powerActions('power_actions', '⚡ Power Quick Actions', '1-tap tactile 3D buttons for fast site entries', 'Quick Actions', Icons.bolt_rounded),
  safetyShield('safety_shield', '🛡️ Zero-Incident Safety Shield', 'Site safety rating & accident-free days badge', 'Site Operations', Icons.shield_rounded),
  materialRadar('material_radar', '📦 Live Material Radar', 'Live visual stock gauges with 1-tap reorders', 'Inventory & Supplies', Icons.inventory_2_rounded),
  portfolioPulse('portfolio_pulse', '📊 Portfolio Pulse', 'Recent site events and live milestone pulse', 'Analytics & Feed', Icons.timeline_rounded),
  projectHealth('project_health', '🍩 Project Health Gauge', 'Portfolio completion and health breakdown', 'Analytics & Feed', Icons.pie_chart_rounded);

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;

  const DashboardWidgetType(this.id, this.title, this.subtitle, this.category, this.icon);

  static DashboardWidgetType fromId(String id) {
    return DashboardWidgetType.values.firstWhere(
      (w) => w.id == id,
      orElse: () => DashboardWidgetType.dailyStreak,
    );
  }
}

class DashboardWidgetConfig {
  final DashboardWidgetType type;
  final bool isEnabled;
  final int order;

  const DashboardWidgetConfig({
    required this.type,
    required this.isEnabled,
    required this.order,
  });

  DashboardWidgetConfig copyWith({
    DashboardWidgetType? type,
    bool? isEnabled,
    int? order,
  }) {
    return DashboardWidgetConfig(
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'type_id': type.id,
    'is_enabled': isEnabled,
    'order': order,
  };

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      type: DashboardWidgetType.fromId(json['type_id'] as String? ?? 'daily_streak'),
      isEnabled: json['is_enabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }
}

class HomepageWidgetsNotifier extends StateNotifier<List<DashboardWidgetConfig>> {
  static const String _kCacheKey = 'homepage_widgets_config_v1';

  HomepageWidgetsNotifier() : super(_defaultConfigs()) {
    _loadFromCache();
  }

  static List<DashboardWidgetConfig> _defaultConfigs() {
    return [
      const DashboardWidgetConfig(type: DashboardWidgetType.dailyStreak, isEnabled: true, order: 0),
      const DashboardWidgetConfig(type: DashboardWidgetType.dailyQuests, isEnabled: true, order: 1),
      const DashboardWidgetConfig(type: DashboardWidgetType.powerActions, isEnabled: true, order: 2),
      const DashboardWidgetConfig(type: DashboardWidgetType.safetyShield, isEnabled: true, order: 3),
      const DashboardWidgetConfig(type: DashboardWidgetType.materialRadar, isEnabled: true, order: 4),
      const DashboardWidgetConfig(type: DashboardWidgetType.portfolioPulse, isEnabled: true, order: 5),
      const DashboardWidgetConfig(type: DashboardWidgetType.projectHealth, isEnabled: true, order: 6),
    ];
  }

  void _loadFromCache() {
    try {
      final cached = OfflineDataCache().get(_kCacheKey);
      if (cached != null) {
        List<dynamic> list;
        if (cached is String) {
          list = jsonDecode(cached) as List<dynamic>;
        } else if (cached is List) {
          list = cached;
        } else {
          return;
        }

        final loaded = list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return DashboardWidgetConfig.fromJson(map);
        }).toList();

        // Ensure all enum values exist
        final existingTypes = loaded.map((c) => c.type).toSet();
        for (final def in _defaultConfigs()) {
          if (!existingTypes.contains(def.type)) {
            loaded.add(def.copyWith(order: loaded.length));
          }
        }

        loaded.sort((a, b) => a.order.compareTo(b.order));
        state = loaded;
      }
    } catch (_) {}
  }

  Future<void> toggleWidget(DashboardWidgetType type, bool isEnabled) async {
    final updated = state.map((cfg) {
      if (cfg.type == type) {
        return cfg.copyWith(isEnabled: isEnabled);
      }
      return cfg;
    }).toList();

    state = updated;
    _saveToCache();
  }

  Future<void> reorderWidgets(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final list = List<DashboardWidgetConfig>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final reordered = list.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();

    state = reordered;
    _saveToCache();
  }

  Future<void> resetToDefaults() async {
    state = _defaultConfigs();
    _saveToCache();
  }

  void _saveToCache() {
    try {
      final jsonList = state.map((c) => c.toJson()).toList();
      OfflineDataCache().set(_kCacheKey, jsonList);
    } catch (_) {}
  }

  List<DashboardWidgetConfig> get enabledWidgets =>
      state.where((w) => w.isEnabled).toList()..sort((a, b) => a.order.compareTo(b.order));
}

final homepageWidgetsProvider =
    StateNotifierProvider<HomepageWidgetsNotifier, List<DashboardWidgetConfig>>((ref) {
  return HomepageWidgetsNotifier();
});
