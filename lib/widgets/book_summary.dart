import 'package:flutter/material.dart';

import '../models/book.dart';

/// Displays the summary statistics of the currently displayed books.
class BookSummary extends StatelessWidget {
  const BookSummary({
    super.key,
    required this.books,
  });

  final List<Book> books;

  static int _statusTiePriority(String status) {
    switch (status) {
      case 'To Read':
        return 1;
      case 'Reading':
        return 2;
      case 'Finished':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBooks = books.length;
    final totalFavorites = books.where((book) => book.favorite).length;

    // Count appearances per status in currently displayed books
    final statusCounts = <String, int>{};
    for (final book in books) {
      statusCounts[book.status] = (statusCounts[book.status] ?? 0) + 1;
    }

    // Filter out zero-count rows and sort by descending count, then tie order
    final statusEntries = statusCounts.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) {
          return countComparison;
        }
        return _statusTiePriority(a.key).compareTo(_statusTiePriority(b.key));
      });

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Books: $totalBooks',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Favorites: $totalFavorites',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (statusEntries.isNotEmpty) ...[
              const Divider(height: 16),
              ...statusEntries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
