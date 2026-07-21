import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../models/site_ticket_model.dart';
import '../models/ticket_message_model.dart';
import '../repositories/supabase_ticket_message_repository.dart';

final ticketMessagesProvider = FutureProvider.family<List<TicketMessage>, String>((ref, ticketId) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseTicketMessageRepository(client).fetchMessagesForTicket(ticketId);
});

class TicketThreadDialog extends ConsumerStatefulWidget {
  final SiteTicket ticket;
  const TicketThreadDialog({super.key, required this.ticket});

  @override
  ConsumerState<TicketThreadDialog> createState() => _TicketThreadDialogState();
}

class _TicketThreadDialogState extends ConsumerState<TicketThreadDialog> {
  final _messageCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _postMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = SupabaseTicketMessageRepository(client);

      final msg = TicketMessage(
        id: '',
        ticketId: widget.ticket.id,
        senderName: 'Admin/Supervisor',
        senderRole: 'admin',
        messageText: text,
        createdAt: DateTime.now(),
      );

      await repo.postMessage(msg);
      _messageCtrl.clear();
      ref.invalidate(ticketMessagesProvider(widget.ticket.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticket.id));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Container(
        width: 550,
        height: 600,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ticket #${widget.ticket.ticketNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      Text(widget.ticket.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    ],
                  ),
                ),
                Chip(
                  label: Text(widget.ticket.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: widget.ticket.status == 'Open' ? AppColors.warning : AppColors.secondary,
                ),
              ],
            ),
            const Divider(height: 24),

            // Conversation Thread Messages
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text('No replies yet. Type a message to reply.', style: TextStyle(color: AppColors.mutedText(context))),
                    );
                  }
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final isAdmin = m.senderRole == 'admin';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppColors.primaryContainer.withValues(alpha: 0.1) : AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${m.senderName} (${m.senderRole.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(m.createdAt.toIso8601String().split('T').first, style: TextStyle(fontSize: 10, color: AppColors.mutedText(context))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(m.messageText, style: TextStyle(fontSize: 13, color: AppColors.text(context))),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading thread: $e')),
              ),
            ),
            const SizedBox(height: 12),

            // Reply Box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply to client/supervisor...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _isSending ? null : _postMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
