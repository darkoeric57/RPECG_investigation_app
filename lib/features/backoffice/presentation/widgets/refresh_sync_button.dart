import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';

class RefreshSyncButton extends ConsumerStatefulWidget {
  const RefreshSyncButton({super.key});

  @override
  ConsumerState<RefreshSyncButton> createState() => _RefreshSyncButtonState();
}

class _RefreshSyncButtonState extends ConsumerState<RefreshSyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metersAsync = ref.watch(backofficeMetersProvider);
    final isLoading = metersAsync.isLoading;

    if (isLoading) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              ref.invalidate(backofficeMetersProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing data from server...'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE047), // Yellow 300
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (isLoading)
              BoxShadow(
                color: const Color(0xFFFDE047).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: Icon(
                Icons.sync_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isLoading ? 'Syncing...' : 'Refresh Sync',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
