import 'package:flutter/material.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../services/auth_service.dart';
import '../widgets/book_filters.dart';
import '../widgets/book_form.dart';
import '../widgets/book_list_item.dart';
import '../widgets/book_summary.dart';
import 'book_detail_screen.dart';

/// The protected Book List screen displaying real-time books, search, filters,
/// summary statistics, favorite toggling, and add-book actions.
class BookListScreen extends StatefulWidget {
  const BookListScreen({
    super.key,
    required this.userId,
    required this.email,
    this.repository,
    this.authService,
  });

  final String userId;
  final String email;
  final BookRepository? repository;
  final AuthService? authService;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  late final BookRepository _repository;
  late final AuthService _authService;
  final TextEditingController _searchController = TextEditingController();

  String _selectedGenre = 'All';
  String _selectedStatus = 'All';
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BookRepository();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleClearFilters() {
    setState(() {
      _selectedGenre = 'All';
      _selectedStatus = 'All';
      _favoritesOnly = false;
      _searchController.clear();
    });
  }

  List<Book> _filterAndSortBooks(List<Book> allBooks) {
    final cleanSearch = _searchController.text.trim().toLowerCase();

    final filtered = allBooks.where((book) {
      // 1. Genre filter
      if (_selectedGenre != 'All' && book.genre != _selectedGenre) {
        return false;
      }

      // 2. Status filter
      if (_selectedStatus != 'All' && book.status != _selectedStatus) {
        return false;
      }

      // 3. Favorites-only switch
      if (_favoritesOnly && !book.favorite) {
        return false;
      }

      // 4. Search filter by title or author (case-insensitive, trimmed)
      if (cleanSearch.isNotEmpty) {
        final titleMatch = book.title.toLowerCase().contains(cleanSearch);
        final authorMatch = book.author.toLowerCase().contains(cleanSearch);
        if (!titleMatch && !authorMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by title alphabetically, case-insensitively.
    // For equal normalized titles, sort by author case-insensitively.
    filtered.sort((a, b) {
      final titleA = a.title.trim().toLowerCase();
      final titleB = b.title.trim().toLowerCase();
      final titleComp = titleA.compareTo(titleB);
      if (titleComp != 0) {
        return titleComp;
      }
      final authorA = a.author.trim().toLowerCase();
      final authorB = b.author.trim().toLowerCase();
      return authorA.compareTo(authorB);
    });

    return filtered;
  }

  Future<void> _handleToggleFavorite(Book book) async {
    try {
      await _repository.toggleFavorite(book);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update favorite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openAddBookModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: BookForm(
              submitLabel: 'Save',
              onCancel: () => Navigator.of(sheetContext).pop(),
              onSubmit: (draft) async {
                // 1. Call BookRepository.addBook(userId, draft).
                // 2. Wait for the successful Firestore write.
                await _repository.addBook(widget.userId, draft);

                if (!sheetContext.mounted) return;
                // 3. Close the form.
                Navigator.of(sheetContext).pop();

                if (!mounted) return;
                // 4. Display the exact message `Book added`.
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Book added'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookShelf'),
        automaticallyImplyLeading: false, // Prevents navigating back
        actions: [
          IconButton(
            tooltip: 'Add Book',
            icon: const Icon(Icons.add),
            onPressed: () => _openAddBookModal(context),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Book',
        onPressed: () => _openAddBookModal(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Authenticated user email banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer.withAlpha(50),
              child: Row(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.email.isNotEmpty ? widget.email : widget.userId,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Combined Filters Control
            BookFilters(
              searchController: _searchController,
              selectedGenre: _selectedGenre,
              selectedStatus: _selectedStatus,
              favoritesOnly: _favoritesOnly,
              onSearchChanged: (_) => setState(() {}),
              onGenreChanged: (val) {
                if (val != null) setState(() => _selectedGenre = val);
              },
              onStatusChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
              onFavoritesOnlyChanged: (val) {
                setState(() => _favoritesOnly = val);
              },
              onClear: _handleClearFilters,
            ),

            // Stream of real-time user books
            Expanded(
              child: StreamBuilder<List<Book>>(
                stream: _repository.watchUserBooks(widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          '${snapshot.error}',
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final allBooks = snapshot.data ?? const <Book>[];
                  final filteredBooks = _filterAndSortBooks(allBooks);

                  return Column(
                    children: [
                      // Summary describing ONLY currently displayed books after filtering
                      BookSummary(books: filteredBooks),

                      // Filtered Books List or exact empty message
                      Expanded(
                        child: filteredBooks.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'No books found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: filteredBooks.length,
                                itemBuilder: (context, index) {
                                  final book = filteredBooks[index];
                                  return BookListItem(
                                    book: book,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BookDetailScreen(
                                            book: book,
                                            userId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    onToggleFavorite: () =>
                                        _handleToggleFavorite(book),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
