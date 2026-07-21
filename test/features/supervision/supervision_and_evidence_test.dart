import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/checklists/data/models/checklist_model.dart';
import 'package:ibuild/features/tickets/data/models/ticket_message_model.dart';
import 'package:ibuild/features/drawings/data/models/site_drawing_model.dart';

void main() {
  group('Supervision, Communication & Evidence Unit Tests', () {
    test('ChecklistItem phase grouping, overdue calculation, and approval statuses', () {
      final item = ChecklistItem(
        id: 'chk-101',
        projectId: 'proj-101',
        title: 'Reinforcement Steel Bar Diameter Inspection',
        category: 'Quality Control',
        phaseGroup: 'Superstructure',
        isCompleted: false,
        dueDate: DateTime.now().subtract(const Duration(days: 2)), // Overdue
        assignedPerson: 'Rajesh Supervisor',
        evidenceImageUrl: 'https://storage.supabase.co/evidence/img1.jpg',
        approvalStatus: 'Submitted',
        createdAt: DateTime.now(),
      );

      expect(item.phaseGroup, equals('Superstructure'));
      expect(item.assignedPerson, equals('Rajesh Supervisor'));
      expect(item.isOverdue, isTrue);
      expect(item.approvalStatus, equals('Submitted'));

      final approved = item.copyWith(approvalStatus: 'Approved', isCompleted: true);
      expect(approved.approvalStatus, equals('Approved'));
      expect(approved.isCompleted, isTrue);
    });

    test('TicketMessage serialization and role classification', () {
      final msg = TicketMessage(
        id: 'msg-1',
        ticketId: 'tix-101',
        senderName: 'Site Supervisor',
        senderRole: 'supervisor',
        messageText: 'Material shortage issue resolved.',
        createdAt: DateTime.now(),
      );

      expect(msg.senderRole, equals('supervisor'));
      expect(msg.messageText, equals('Material shortage issue resolved.'));

      final json = msg.toJson();
      expect(json['ticket_id'], equals('tix-101'));
      expect(json['sender_role'], equals('supervisor'));
    });

    test('SiteDrawing model with archiving and file size', () {
      final dwg = SiteDrawing(
        id: 'dwg-1',
        projectId: 'proj-101',
        title: 'Structural Column Layout Rev 2',
        category: 'Structural',
        version: 'v2.1',
        fileUrl: 'https://storage.supabase.co/drawings/dwg1.pdf',
        isArchived: false,
        fileSizeBytes: 2048576,
        createdAt: DateTime.now(),
      );

      expect(dwg.isArchived, isFalse);
      expect(dwg.fileSizeBytes, equals(2048576));

      final archived = dwg.copyWith(isArchived: true);
      expect(archived.isArchived, isTrue);
    });
  });
}
