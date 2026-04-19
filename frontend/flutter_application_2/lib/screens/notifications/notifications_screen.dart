import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  String? _error;
  List<AppNotification> _notifications = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadNotifications();
    }
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadNotifications(showRefreshMessage: true);
    }
  }

  Future<void> _loadNotifications({bool showRefreshMessage = false}) async {
    final session = SessionScope.of(context);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await session.api.getNotifications(session.requireToken());
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = items;
        _isLoading = false;
      });

      if (showRefreshMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thong bao da duoc cap nhat'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thong bao'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: [
          const SizedBox(height: 180),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadNotifications,
                  child: const Text('Thu lai'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 150),
          Center(child: Text('Chua co thong bao nao')),
        ],
      );
    }

    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: item.actorAvatar.isEmpty ? null : NetworkImage(item.actorAvatar),
            child: item.actorAvatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(item.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.body.isNotEmpty) Text(item.body),
              const SizedBox(height: 4),
              Text(
                item.timestamp,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          isThreeLine: item.body.isNotEmpty,
        );
      },
    );
  }
}
