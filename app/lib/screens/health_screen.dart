import 'package:flutter/material.dart';

import '../api/services_scope.dart';
import '../models/health_status.dart';
import '../widgets/async_view.dart';

/// Shows the result of `GET /health`.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  Future<HealthStatus>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ServicesScope.of(context).health.check();
  }

  void _refresh() =>
      setState(() => _future = ServicesScope.of(context).health.check());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health check'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: AsyncView<HealthStatus>(
        future: _future!,
        onRetry: _refresh,
        builder: (context, data) {
          final ok = data.status.toLowerCase() == 'ok';
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ok ? Icons.check_circle : Icons.error,
                  size: 64,
                  color: ok ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  'status: ${data.status}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
