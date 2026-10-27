import '../models/book.dart';

abstract final class BookValidators {
  static const List<String> allowedGenres = <String>[
    'Fiction',
    'Non-Fiction',
    'Academic',
    'Other',
  ];

  static const List<String> allowedStatuses = <String>[
    'To Read',
    'Reading',
    'Finished',
  ];

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Title is required';
    if (text.length > 100) return 'Title must be at most 100 characters';
    return null;
  }

  static String? author(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Author is required';
    if (text.length > 60) return 'Author must be at most 60 characters';
    return null;
  }

  static String? genre(String? value) {
    if (!allowedGenres.contains(value)) return 'Please choose a genre';
    return null;
  }

  static String? status(String? value) {
    if (!allowedStatuses.contains(value)) return 'Please choose a status';
    return null;
  }

  /// Validator for a rating text field. Empty input is valid and represents
  /// `null`; all other input must be an integer from 0 through 5.
  static String? rating(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0 || parsed > 5) {
      return 'Rating must be a whole number from 0 to 5';
    }
    return null;
  }

  static String? ratingValue(int? value) {
    if (value != null && (value < 0 || value > 5)) {
      return 'Rating must be a whole number from 0 to 5';
    }
    return null;
  }

  static String? notes(String? value) {
    if ((value ?? '').length > 300) {
      return 'Notes must be at most 300 characters';
    }
    return null;
  }

  /// Returns field names mapped to the same messages used by the form
  /// validators. An empty map means the draft is valid.
  static Map<String, String> validateDraft(BookDraft draft) {
    final errors = <String, String>{};

    void add(String field, String? error) {
      if (error != null) errors[field] = error;
    }

    add('title', title(draft.title));
    add('author', author(draft.author));
    add('genre', genre(draft.genre));
    add('status', status(draft.status));
    add('rating', ratingValue(draft.rating));
    add('notes', notes(draft.notes));
    return errors;
  }
}
