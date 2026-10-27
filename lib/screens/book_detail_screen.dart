import 'package:flutter/material.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../widgets/book_form.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book, required this.userId});

  final Book book;
  final String userId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookRepository _repository = BookRepository();

  late Book _book;
  bool _isEditing = false;
  bool _isDeleting = false;
  bool _isTogglingFavorite = false;

  bool get _ownsBook => _book.userId == widget.userId;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  Future<void> _save(BookDraft draft) async {
    await _repository.updateBook(_book, draft);
    if (!mounted) return;

    setState(() {
      _book = Book(
        id: _book.id,
        userId: _book.userId,
        title: draft.title.trim(),
        author: draft.author.trim(),
        genre: draft.genre,
        status: draft.status,
        rating: draft.rating,
        favorite: draft.favorite,
        notes: draft.notes,
        createdAt: _book.createdAt,
      );
      _isEditing = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite || !_ownsBook) return;
    setState(() => _isTogglingFavorite = true);

    try {
      await _repository.toggleFavorite(_book);
      if (!mounted) return;
      setState(() => _book = _book.copyWith(favorite: !_book.favorite));
    } on Object catch (error) {
      if (!mounted) return;
      _showError(_message(error));
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting || !_ownsBook) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete “${_book.title}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);

    try {
      await _repository.deleteBook(_book);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showError(_message(error));
    }
  }

  String _message(Object error) {
    if (error is BookRepositoryException) return error.message;
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Book' : 'Book Details'),
        actions: _isEditing
            ? null
            : [
                IconButton(
                  tooltip: _book.favorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: _isTogglingFavorite || !_ownsBook
                      ? null
                      : _toggleFavorite,
                  icon: _isTogglingFavorite
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _book.favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _book.favorite ? Colors.red : null,
                        ),
                ),
              ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _isEditing ? _buildEditMode() : _buildViewMode(),
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return BookForm(
      initialBook: _book,
      submitLabel: 'Save',
      onSubmit: _save,
      onCancel: () => setState(() => _isEditing = false),
    );
  }

  Widget _buildViewMode() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_ownsBook) ...[
          MaterialBanner(
            content: const Text(
              'You do not have permission to modify this book.',
            ),
            actions: const [SizedBox.shrink()],
          ),
          const SizedBox(height: 16),
        ],
        Icon(
          Icons.menu_book_rounded,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          _book.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'by ${_book.author}',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(label: 'Genre', value: _book.genre),
                _DetailRow(label: 'Status', value: _book.status),
                _DetailRow(
                  label: 'Rating',
                  value: _book.rating == null
                      ? 'Not rated'
                      : '${_book.rating}/5',
                ),
                _DetailRow(
                  label: 'Favorite',
                  value: _book.favorite ? 'Yes' : 'No',
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Notes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_book.notes.isEmpty ? 'No notes' : _book.notes),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isDeleting || !_ownsBook
              ? null
              : () => setState(() => _isEditing = true),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isDeleting || !_ownsBook ? null : _confirmDelete,
          icon: _isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(_isDeleting ? 'Deleting…' : 'Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: Text(value)),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
