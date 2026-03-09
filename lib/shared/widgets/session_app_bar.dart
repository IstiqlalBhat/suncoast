import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SessionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback? onEndSession;
  final List<Widget>? actions;

  const SessionAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.accentColor = AppColors.primary,
    this.onEndSession,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () {
          if (onEndSession != null) {
            _showEndSessionDialog(context);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      actions: [
        ...?actions,
        if (onEndSession != null)
          TextButton(
            onPressed: () => _showEndSessionDialog(context),
            child: const Text(
              'End',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  void _showEndSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('This will stop recording and generate a summary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onEndSession?.call();
            },
            child: const Text(
              'End Session',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
