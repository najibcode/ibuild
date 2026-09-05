import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/offline/offline_data_cache.dart';
import '../models/subcontractor_model.dart';

class SupabaseSubcontractorRepository {
  final SupabaseClient _client;

  SupabaseSubcontractorRepository(this._client);

  /// Fetch subcontractors, optionally filtered by project ID
  Future<List<Subcontractor>> fetchSubcontractors({String? projectId}) async {
    final cache = OfflineDataCache();
    Map<String, String> projectNames = {};
    try {
      final pResp = await _client.from('projects').select('id, name');
      for (final p in (pResp as List)) {
        final pid = p['id']?.toString();
        final pname = p['name']?.toString();
        if (pid != null && pname != null) {
          projectNames[pid] = pname;
        }
      }
    } catch (_) {
      // Use cached projects if available
      final cachedProj = cache.getCachedProjects() ?? [];
      for (final p in cachedProj) {
        final pid = p['id']?.toString();
        final pname = p['name']?.toString();
        if (pid != null && pname != null) {
          projectNames[pid] = pname;
        }
      }
    }

    try {
      var query = _client.from('subcontractors').select('*, projects(name)');

      if (projectId != null && projectId.isNotEmpty) {
        query = query.eq('project_id', projectId);
      }

      final response = await query.order('name', ascending: true);
      final subs = (response as List).map((json) {
        final map = Map<String, dynamic>.from(json);
        final subId = map['id']?.toString() ?? '';
        final localAssign = cache.getSubcontractorSiteAssignment(subId);
        final pId = map['project_id']?.toString();
        final effectiveProjectId = (pId != null && pId.isNotEmpty) ? pId : localAssign?['project_id'];
        
        String? effectiveSiteName = map['site_name']?.toString();
        if (effectiveSiteName == null || effectiveSiteName == 'Unassigned') {
          if (effectiveProjectId != null && projectNames.containsKey(effectiveProjectId)) {
            effectiveSiteName = projectNames[effectiveProjectId];
          } else if (localAssign?['site_name'] != null && localAssign!['site_name']!.isNotEmpty) {
            effectiveSiteName = localAssign['site_name'];
          }
        }

        map['project_id'] = effectiveProjectId;
        map['site_name'] = effectiveSiteName;
        return Subcontractor.fromJson(map);
      }).toList();

      cache.cacheSubcontractors(subs.map((s) => s.toMap()).toList());
      return subs;
    } catch (e) {
      debugPrint('Error fetching with project join, trying plain select: $e');
      try {
        var query = _client.from('subcontractors').select();
        if (projectId != null && projectId.isNotEmpty) {
          try {
            query = query.eq('project_id', projectId);
          } catch (_) {}
        }
        final response = await query.order('name', ascending: true);
        final subs = (response as List).map((json) {
          final map = Map<String, dynamic>.from(json);
          final subId = map['id']?.toString() ?? '';
          final localAssign = cache.getSubcontractorSiteAssignment(subId);
          final pId = map['project_id']?.toString();
          final effectiveProjectId = (pId != null && pId.isNotEmpty) ? pId : localAssign?['project_id'];

          String? effectiveSiteName = map['site_name']?.toString();
          if (effectiveSiteName == null || effectiveSiteName == 'Unassigned') {
            if (effectiveProjectId != null && projectNames.containsKey(effectiveProjectId)) {
              effectiveSiteName = projectNames[effectiveProjectId];
            } else if (localAssign?['site_name'] != null && localAssign!['site_name']!.isNotEmpty) {
              effectiveSiteName = localAssign['site_name'];
            }
          }

          map['project_id'] = effectiveProjectId;
          map['site_name'] = effectiveSiteName;
          return Subcontractor.fromJson(map);
        }).toList();

        cache.cacheSubcontractors(subs.map((s) => s.toMap()).toList());
        return subs;
      } catch (e2) {
        debugPrint('Fallback to offline cached subcontractors: $e2');
        final cached = cache.getCachedSubcontractors();
        if (cached != null && cached.isNotEmpty) {
          return cached.map((m) => Subcontractor.fromJson(m)).toList();
        }
        return [];
      }
    }
  }

  /// Create a new subcontractor with schema fallback resilience
  Future<Subcontractor> createSubcontractor(Subcontractor sub) async {
    final payload = sub.toDbJson();
    Subcontractor created;
    try {
      final response = await _client.from('subcontractors').insert(payload).select().single();
      created = Subcontractor.fromJson(Map<String, dynamic>.from(response)).copyWith(
        companyNameProp: sub.companyNameProp,
        contactPersonProp: sub.contactPersonProp,
        siteNameProp: sub.siteNameProp,
        projectId: sub.projectId,
      );
    } catch (e) {
      debugPrint('Insert failed with extended columns ($e), attempting legacy fallback payload');
      final fallbackPayload = <String, dynamic>{
        'name': sub.companyName,
        'specialization': sub.tradeSpecialization,
        'phone': sub.phone,
        'email': sub.email,
        'address': sub.address,
        'project_id': (sub.projectId != null && sub.projectId!.isNotEmpty) ? sub.projectId : null,
        'gst_number': sub.gstNumber,
        'contract_value': sub.contractValue,
        'paid_amount': sub.paidAmount,
        'status': sub.status,
        'is_archived': sub.isArchived,
      };
      try {
        final response = await _client.from('subcontractors').insert(fallbackPayload).select().single();
        created = Subcontractor.fromJson(Map<String, dynamic>.from(response)).copyWith(
          companyNameProp: sub.companyNameProp,
          contactPersonProp: sub.contactPersonProp,
          siteNameProp: sub.siteNameProp,
          projectId: sub.projectId,
        );
      } catch (_) {
        final minPayload = <String, dynamic>{
          'name': sub.companyName,
          'specialization': sub.tradeSpecialization,
          'phone': sub.phone,
          'email': sub.email,
          'contract_value': sub.contractValue,
          'paid_amount': sub.paidAmount,
          'status': sub.status,
        };
        final response = await _client.from('subcontractors').insert(minPayload).select().single();
        created = Subcontractor.fromJson(Map<String, dynamic>.from(response)).copyWith(
          companyNameProp: sub.companyNameProp,
          contactPersonProp: sub.contactPersonProp,
          siteNameProp: sub.siteNameProp,
          projectId: sub.projectId,
        );
      }
    }

    final cache = OfflineDataCache();
    if (created.projectId != null && created.projectId!.isNotEmpty && created.siteNameProp != null) {
      cache.cacheSubcontractorSiteAssignment(created.id, created.projectId!, created.siteNameProp!);
    }
    final existing = cache.getCachedSubcontractors() ?? [];
    existing.add(created.toMap());
    cache.cacheSubcontractors(existing);

    // If initial paidAmount > 0 and assigned to a project, sync to Project Expenses & Spent
    if (sub.paidAmount > 0 && sub.projectId != null && sub.projectId!.isNotEmpty) {
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final desc = 'Initial Trade Contract Disbursement: ${sub.companyName} (${sub.tradeSpecialization})';
      try {
        await _client.from('expenses').insert({
          'project_id': sub.projectId,
          'expense_date': dateStr,
          'category': 'Subcontractor',
          'amount': sub.paidAmount,
          'payment_mode': 'bank',
          'notes': desc,
          'vendor_name': sub.companyName,
        });
      } catch (expErr) {
        debugPrint('Expense auto-sync notice: $expErr');
      }

      try {
        final projectData = await _client
            .from('projects')
            .select('spent')
            .eq('id', sub.projectId!)
            .maybeSingle();

        if (projectData != null) {
          final currentSpent = (projectData['spent'] as num?)?.toDouble() ?? 0.0;
          await _client.from('projects').update({
            'spent': currentSpent + sub.paidAmount,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', sub.projectId!);
        }
      } catch (pErr) {
        debugPrint('Project spent update notice: $pErr');
      }
    }

    return created;
  }

  /// Assign or change the project site for a subcontractor
  Future<bool> assignProjectToSubcontractor({
    required Subcontractor subcontractor,
    required String projectId,
    required String siteName,
  }) async {
    try {
      final cache = OfflineDataCache();
      cache.cacheSubcontractorSiteAssignment(subcontractor.id, projectId, siteName);

      final updatedSub = subcontractor.copyWith(
        projectId: projectId,
        siteNameProp: siteName,
      );

      final existing = cache.getCachedSubcontractors() ?? [];
      final idx = existing.indexWhere((s) => s['id'] == subcontractor.id);
      if (idx != -1) {
        existing[idx] = updatedSub.toMap();
      } else {
        existing.add(updatedSub.toMap());
      }
      cache.cacheSubcontractors(existing);

      await updateSubcontractor(updatedSub);

      // If the subcontractor already has a paidAmount, ensure it's logged in project expenses & spent
      if (subcontractor.paidAmount > 0) {
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        final desc = 'Trade Partner Contract: ${subcontractor.companyName} (${subcontractor.tradeSpecialization})';
        try {
          await _client.from('expenses').insert({
            'project_id': projectId,
            'expense_date': dateStr,
            'category': 'Subcontractor',
            'amount': subcontractor.paidAmount,
            'payment_mode': 'bank',
            'notes': desc,
            'vendor_name': subcontractor.companyName,
          });
        } catch (_) {}

        try {
          final projectData = await _client
              .from('projects')
              .select('spent')
              .eq('id', projectId)
              .maybeSingle();

          if (projectData != null) {
            final currentSpent = (projectData['spent'] as num?)?.toDouble() ?? 0.0;
            await _client.from('projects').update({
              'spent': currentSpent + subcontractor.paidAmount,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', projectId);
          }
        } catch (_) {}
      }

      return true;
    } catch (e) {
      debugPrint('Error assigning project to subcontractor: $e');
      return true; // Return true as local cache is successfully preserved
    }
  }

  /// Update an existing subcontractor
  Future<void> updateSubcontractor(Subcontractor sub) async {
    final cache = OfflineDataCache();
    if (sub.projectId != null && sub.projectId!.isNotEmpty && sub.siteNameProp != null) {
      cache.cacheSubcontractorSiteAssignment(sub.id, sub.projectId!, sub.siteNameProp!);
    }
    final existing = cache.getCachedSubcontractors() ?? [];
    final idx = existing.indexWhere((s) => s['id'] == sub.id);
    if (idx != -1) {
      existing[idx] = sub.toMap();
    } else {
      existing.add(sub.toMap());
    }
    cache.cacheSubcontractors(existing);

    final payload = sub.toDbJson();
    try {
      await _client.from('subcontractors').update(payload).eq('id', sub.id);
    } catch (e) {
      debugPrint('Update failed with extended columns ($e), attempting fallback update');
      final fallbackPayload = <String, dynamic>{
        'name': sub.companyName,
        'specialization': sub.tradeSpecialization,
        'phone': sub.phone,
        'email': sub.email,
        'address': sub.address,
        'project_id': (sub.projectId != null && sub.projectId!.isNotEmpty) ? sub.projectId : null,
        'gst_number': sub.gstNumber,
        'contract_value': sub.contractValue,
        'paid_amount': sub.paidAmount,
        'status': sub.status,
        'is_archived': sub.isArchived,
      };
      try {
        await _client.from('subcontractors').update(fallbackPayload).eq('id', sub.id);
      } catch (e2) {
        final minPayload = <String, dynamic>{
          'name': sub.companyName,
          'specialization': sub.tradeSpecialization,
          'phone': sub.phone,
          'email': sub.email,
          'contract_value': sub.contractValue,
          'paid_amount': sub.paidAmount,
          'status': sub.status,
        };
        await _client.from('subcontractors').update(minPayload).eq('id', sub.id);
      }
    }
  }

  /// Record a payment / disbursement to a subcontractor and sync with Project Expenses
  Future<bool> recordSubcontractorPayment({
    required Subcontractor subcontractor,
    required double paymentAmount,
    required String paymentMode,
    String? referenceNumber,
    String? remarks,
  }) async {
    try {
      final newPaidAmount = subcontractor.paidAmount + paymentAmount;
      final updatedSub = subcontractor.copyWith(paidAmount: newPaidAmount);

      // 1. Update Subcontractor paid amount
      await updateSubcontractor(updatedSub);

      final projectId = subcontractor.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        final desc = 'Trade Partner Payment: ${subcontractor.companyName} (${subcontractor.tradeSpecialization})${remarks != null && remarks.isNotEmpty ? " - $remarks" : ""}';

        // 2. Insert into expenses table
        try {
          await _client.from('expenses').insert({
            'project_id': projectId,
            'expense_date': dateStr,
            'category': 'Subcontractor',
            'amount': paymentAmount,
            'payment_mode': paymentMode.toLowerCase(),
            'notes': desc,
            'vendor_name': subcontractor.companyName,
          });
        } catch (expErr) {
          debugPrint('Note: Expense table insert fallback ($expErr)');
        }

        // 3. Increment spent amount on the project table
        try {
          final projectData = await _client
              .from('projects')
              .select('spent')
              .eq('id', projectId)
              .maybeSingle();

          if (projectData != null) {
            final currentSpent = (projectData['spent'] as num?)?.toDouble() ?? 0.0;
            await _client.from('projects').update({
              'spent': currentSpent + paymentAmount,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', projectId);
          }
        } catch (pErr) {
          debugPrint('Note: Project spent update fallback ($pErr)');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error recording subcontractor payment & project sync: $e');
      return false;
    }
  }

  /// Delete a subcontractor
  Future<void> deleteSubcontractor(String id) async {
    await _client.from('subcontractors').delete().eq('id', id);
    try {
      final cache = OfflineDataCache();
      final existing = cache.getCachedSubcontractors() ?? [];
      existing.removeWhere((s) => s['id']?.toString() == id);
      cache.cacheSubcontractors(existing);
    } catch (_) {}
  }
}
