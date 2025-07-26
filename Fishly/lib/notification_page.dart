import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  Future<void> _markAllAsRead(
    BuildContext context,
    DatabaseReference notificationsRef,
  ) async {
    try {
      final snapshot = await notificationsRef.get();
      if (snapshot.value == null) return;
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final Map<String, Object?> updates = {};
      for (final entry in data.entries) {
        final n = Map<String, dynamic>.from(entry.value);
        if (n['status'] != 'read') {
          updates['${entry.key}/status'] = 'read';
        }
      }
      if (updates.isNotEmpty) {
        await notificationsRef.update(updates);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark all as read: $e')));
    }
  }

  Future<void> _dismissAll(
    BuildContext context,
    DatabaseReference notificationsRef,
  ) async {
    try {
      await notificationsRef.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications dismissed.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to dismiss all: $e')));
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.amber;
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsRef = FirebaseDatabase.instance.ref('notifications');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                'B',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        iconTheme: theme.iconTheme,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Filter/Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search notifications...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    const PopupMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                    const PopupMenuItem(
                      value: 'warning',
                      child: Text('Warning'),
                    ),
                    const PopupMenuItem(value: 'info', child: Text('Info')),
                    const PopupMenuItem(
                      value: 'success',
                      child: Text('Success'),
                    ),
                  ],
                  onSelected: (value) {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.done_all),
                    label: const Text('Mark all as read'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _markAllAsRead(context, notificationsRef),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Dismiss all'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _dismissAll(context, notificationsRef),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: notificationsRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text(
                      'No recent information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );
                // Sort notifications by timestamp descending
                final notifications = data.entries
                    .map((e) {
                      final n = Map<String, dynamic>.from(e.value);
                      return {
                        'key': e.key,
                        'title': n['title'] ?? '',
                        'description': n['description'] ?? '',
                        'timestamp': n['timestamp'] ?? '',
                        'type': n['type'] ?? 'info',
                        'status': n['status'] ?? 'unread',
                      };
                    })
                    // Filter out notifications with empty title and description
                    .where(
                      (n) =>
                          (n['title'] as String).trim().isNotEmpty ||
                          (n['description'] as String).trim().isNotEmpty,
                    )
                    .toList();
                notifications.sort(
                  (a, b) => (b['timestamp'] as String).compareTo(
                    a['timestamp'] as String,
                  ),
                );
                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recent information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final icon = _iconForType(n['type']);
                    final color = _colorForType(n['type']);
                    final borderColor = color.withOpacity(0.5);
                    final rawTime = n['timestamp'].toString().replaceAll(
                      'T',
                      ' ',
                    );
                    final time = rawTime.length >= 16
                        ? rawTime.substring(0, 16)
                        : (rawTime.isNotEmpty ? rawTime : '--');
                    return NotificationCard(
                      icon: icon,
                      iconColor: color,
                      borderColor: borderColor,
                      title: n['title'],
                      description: n['description'],
                      time: time,
                      actions: [
                        if (n['status'] == 'unread')
                          NotificationAction(
                            label: 'Mark as Read',
                            color: Colors.blue,
                            onPressed: () {
                              notificationsRef.child(n['key']).update({
                                'status': 'read',
                              });
                            },
                          ),
                        NotificationAction(
                          label: 'Dismiss',
                          color: Colors.grey[300]!,
                          textColor: Colors.black54,
                          onPressed: () {
                            notificationsRef.child(n['key']).remove();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String title;
  final String description;
  final String time;
  final List<NotificationAction>? actions;

  const NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.title,
    required this.description,
    required this.time,
    this.actions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Text(time, style: theme.textTheme.bodySmall),
              ],
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: actions!
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: a.color,
                            foregroundColor: a.textColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: a.onPressed,
                          child: Text(
                            a.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationAction {
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onPressed;

  NotificationAction({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onPressed,
  });
}
