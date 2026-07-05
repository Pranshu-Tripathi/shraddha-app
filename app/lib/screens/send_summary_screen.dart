import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exception.dart';
import '../api/services_scope.dart';
import '../models/send_summary_request.dart';
import '../router/app_routes.dart';

/// Form that posts to `POST /send_summary`. Items are entered one per line.
class SendSummaryScreen extends StatefulWidget {
  const SendSummaryScreen({super.key});

  @override
  State<SendSummaryScreen> createState() => _SendSummaryScreenState();
}

class _SendSummaryScreenState extends State<SendSummaryScreen> {
  final _titleController = TextEditingController();
  final _itemsController = TextEditingController();
  final _groupController = TextEditingController();
  bool _includeTimestamp = true;
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _itemsController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final items = _itemsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (title.isEmpty || items.isEmpty) {
      _snack('Title and at least one item are required');
      return;
    }
    setState(() => _sending = true);
    try {
      final res = await ServicesScope.of(context).whatsapp.sendSummary(
            SendSummaryRequest(
              title: title,
              items: items,
              groupId: _groupController.text.trim(),
              includeTimestamp: _includeTimestamp,
            ),
          );
      if (!mounted) return;
      _snack('Queued (ticket ${res.ticketId})');
      context.push(AppRoutes.statusPath(res.ticketId));
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _itemsController,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Items (one per line)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _groupController,
            decoration: const InputDecoration(
              labelText: 'Group ID (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            value: _includeTimestamp,
            onChanged: (v) => setState(() => _includeTimestamp = v),
            title: const Text('Include timestamp'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_sending ? 'Sending…' : 'Send summary'),
          ),
        ],
      ),
    );
  }
}
