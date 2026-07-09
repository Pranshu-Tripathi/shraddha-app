import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exception.dart';
import '../api/services_scope.dart';
import '../models/send_request.dart';
import '../router/app_routes.dart';

/// Form that posts to `POST /send` and routes to the ticket status on success.
class SendMessageScreen extends StatefulWidget {
  const SendMessageScreen({super.key});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _textController = TextEditingController();
  final _groupController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _snack('Message text is required');
      return;
    }
    setState(() => _sending = true);
    try {
      final res = await ServicesScope.of(context).whatsapp.send(
        SendRequest(text: text, groupId: _groupController.text.trim()),
      );
      if (!mounted) return;
      _snack('Queued (ticket ${res.ticketId}, status ${res.status})');
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
      appBar: AppBar(title: const Text('Send message')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Message text',
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
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_sending ? 'Sending…' : 'Send'),
          ),
        ],
      ),
    );
  }
}
