import 'package:flutter/material.dart';

/// Filter and search controls for the book list.
class BookFilters extends StatelessWidget {
  const BookFilters({
    super.key,
    required this.searchController,
    required this.selectedGenre,
    required this.selectedStatus,
    required this.favoritesOnly,
    required this.onSearchChanged,
    required this.onGenreChanged,
    required this.onStatusChanged,
    required this.onFavoritesOnlyChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String selectedGenre;
  final String selectedStatus;
  final bool favoritesOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onGenreChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<bool> onFavoritesOnlyChanged;
  final VoidCallback onClear;

  static const List<String> genreOptions = [
    'All',
    'Fiction',
    'Non-Fiction',
    'Academic',
    'Other',
  ];

  static const List<String> statusOptions = [
    'All',
    'To Read',
    'Reading',
    'Finished',
  ];

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'Search by title or author',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),

            // Dropdowns for Genre & Status
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Genre',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedGenre,
                        items: genreOptions.map((genre) {
                          return DropdownMenuItem<String>(
                            value: genre,
                            child: Text(
                              genre,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: onGenreChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedStatus,
                        items: statusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: onStatusChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Favorites Only Switch & Clear Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Favorites only',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: favoritesOnly,
                      onChanged: onFavoritesOnlyChanged,
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Clear'),
                  onPressed: onClear,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
