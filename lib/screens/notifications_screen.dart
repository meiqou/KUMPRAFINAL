import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      // Mock API call - replace with real /notifications/list.php when backend ready
      await Future.delayed(const Duration(seconds: 1));
      
      // Empty for real-time (API-ready stub - add /notifications/list.php later)
      final mockNotifications = [];


      setState(() {
        _notifications = mockNotifications;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading notifications: $e';
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    // Mock API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      final notification = _notifications.firstWhere((n) => n['id'] == id);
      notification['is_read'] = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as read'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_chat_read),
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['is_read'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(child: Text(_error, style: GoogleFonts.poppins(color: AppColors.textSecondary)))
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text('No notifications', style: GoogleFonts.poppins(fontSize: 18)),
                            Text('You\'ll see updates here', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final isUnread = !(notification['is_read'] ?? false);
                          return Card(
                            color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : null,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                notification['title'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: isUnread ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notification['subtitle'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['timestamp'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isUnread
                                  ? SizedBox(
                                      width: 80,
                                      child: ElevatedButton(
                                        onPressed: () => _markAsRead(notification['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: const Text(
                                          'Mark Read',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              onTap: isUnread ? () => _markAsRead(notification['id']) : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
