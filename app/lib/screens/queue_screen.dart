import 'package:flutter/material.dart';

import '../api/services_scope.dart';
import '../models/queue_depth.dart';
import '../widgets/async_view.dart';

/// Shows the result of `GET /queue` (number of messages pending).
class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  Future<QueueDepth>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ServicesScope.of(context).whatsapp.queueDepth();
  }

  void _refresh() =>
      setState(() => _future = ServicesScope.of(context).whatsapp.queueDepth());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue depth'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: AsyncView<QueueDepth>(
        future: _future!,
        onRetry: _refresh,
        builder: (context, data) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${data.pending}',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const Text('messages pending'),
            ],
          ),
        ),
      ),
    );
  }
}
