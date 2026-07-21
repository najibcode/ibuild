import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PaginatedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final String emptyMessage;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.emptyMessage = 'No items found.',
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: AppColors.mutedText(context))),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    if (!isLoading && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: AppColors.mutedText(context), fontSize: 14)),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore &&
            !isLoading) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
        itemCount: items.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return itemBuilder(context, items[index]);
        },
      ),
    );
  }
}
