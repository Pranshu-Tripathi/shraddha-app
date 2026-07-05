import 'package:flutter/material.dart';

import '../api/services_scope.dart';
import '../models/ticket_status.dart';
import '../widgets/async_view.dart';

/// Shows `GET /status/<ticketId>` for a ticket id passed via the route.
class TicketStatusScreen extends StatefulWidget {
  const TicketStatusScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<TicketStatusScreen> createState() => _TicketStatusScreenState();
}

class _TicketStatusScreenState extends State<TicketStatusScreen> {
  Future<TicketStatus>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ServicesScope.of(context).whatsapp.status(widget.ticketId);
  }

  void _refresh() => setState(
        () => _future = ServicesScope.of(context).whatsapp.status(widget.ticketId),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket status'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: AsyncView<TicketStatus>(
        future: _future!,
        onRetry: _refresh,
        builder: (context, data) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Ticket', data.ticketId),
              _row('Status', data.status),
              if (data.error != null && data.error!.isNotEmpty)
                _row('Error', data.error!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}
