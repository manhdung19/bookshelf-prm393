import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book.dart';
import '../utils/book_validators.dart';

class BookRepositoryException implements Exception {
  const BookRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class BookValidationException extends BookRepositoryException {
  BookValidationException(this.errors)
    : super(errors.values.firstOrNull ?? 'The book data is invalid.');

  final Map<String, String> errors;
}

class DuplicateBookException extends BookRepositoryException {
  const DuplicateBookException()
    : super('A book with the same title and author already exists.');
}

class BookRepository {
  BookRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection('books');

  Stream<List<Book>> watchUserBooks(String uid) {
    try {
      _requireSignedInUser(uid);
    } on Object catch (error, stackTrace) {
      return Stream<List<Book>>.error(error, stackTrace);
    }

    return _books
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final books = snapshot.docs.map(Book.fromFirestore).toList();
          books.sort((a, b) {
            final titleComparison = a.title.toLowerCase().compareTo(
              b.title.toLowerCase(),
            );
            if (titleComparison != 0) return titleComparison;

            final authorComparison = a.author.toLowerCase().compareTo(
              b.author.toLowerCase(),
            );
            if (authorComparison != 0) return authorComparison;

            // Document ids are unique and make ordering stable when two
            // records differ only by letter case or are legacy duplicates.
            return a.id.compareTo(b.id);
          });
          return List<Book>.unmodifiable(books);
        })
        .transform(
          StreamTransformer<List<Book>, List<Book>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(_friendlyError('load books', error), stackTrace);
            },
          ),
        );
  }

  Future<void> addBook(String uid, BookDraft draft) async {
    _requireSignedInUser(uid);
    _validateDraft(draft);

    try {
      await _ensureUnique(uid, draft);
      final document = _books.doc();
      await document.set(draft.toFirestore(id: document.id, userId: uid));
    } on BookRepositoryException {
      rethrow;
    } on Object catch (error) {
      throw _friendlyError('add the book', error);
    }
  }

  Future<void> updateBook(Book book, BookDraft draft) async {
    final uid = _requireOwner(book);
    _validateDraft(draft);

    try {
      await _ensureUnique(uid, draft, excludingId: book.id);
      await _firestore.runTransaction((transaction) async {
        final reference = _books.doc(book.id);
        final snapshot = await transaction.get(reference);
        _requireOwnedSnapshot(snapshot, uid);

        transaction.update(reference, <String, Object?>{
          'title': draft.title.trim(),
          'author': draft.author.trim(),
          'genre': draft.genre,
          'status': draft.status,
          'rating': draft.rating,
          'favorite': draft.favorite,
          'notes': draft.notes,
        });
      });
    } on BookRepositoryException {
      rethrow;
    } on Object catch (error) {
      throw _friendlyError('update the book', error);
    }
  }

  Future<void> deleteBook(Book book) async {
    final uid = _requireOwner(book);
    try {
      await _firestore.runTransaction((transaction) async {
        final reference = _books.doc(book.id);
        final snapshot = await transaction.get(reference);
        _requireOwnedSnapshot(snapshot, uid);
        transaction.delete(reference);
      });
    } on BookRepositoryException {
      rethrow;
    } on Object catch (error) {
      throw _friendlyError('delete the book', error);
    }
  }

  Future<void> toggleFavorite(Book book) async {
    final uid = _requireOwner(book);
    try {
      await _firestore.runTransaction((transaction) async {
        final reference = _books.doc(book.id);
        final snapshot = await transaction.get(reference);
        _requireOwnedSnapshot(snapshot, uid);
        final favorite = snapshot.data()?['favorite'];
        if (favorite is! bool) {
          throw const BookRepositoryException(
            'The stored book has an invalid favorite value.',
          );
        }
        transaction.update(reference, <String, Object?>{'favorite': !favorite});
      });
    } on BookRepositoryException {
      rethrow;
    } on Object catch (error) {
      throw _friendlyError('update the favorite', error);
    }
  }

  String _requireSignedInUser(String expectedUid) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const BookRepositoryException(
        'You must be signed in to access books.',
      );
    }
    if (uid != expectedUid) {
      throw const BookRepositoryException(
        'You do not have permission to access these books.',
      );
    }
    return uid;
  }

  String _requireOwner(Book book) {
    final uid = _requireSignedInUser(book.userId);
    if (book.id.isEmpty) {
      throw const BookRepositoryException('The book id is missing.');
    }
    return uid;
  }

  void _requireOwnedSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String uid,
  ) {
    if (!snapshot.exists) {
      throw const BookRepositoryException('The book no longer exists.');
    }
    if (snapshot.data()?['userId'] != uid) {
      throw const BookRepositoryException(
        'You do not have permission to modify this book.',
      );
    }
  }

  void _validateDraft(BookDraft draft) {
    final errors = BookValidators.validateDraft(draft);
    if (errors.isNotEmpty) throw BookValidationException(errors);
  }

  /// Best-effort application-level uniqueness check. Firestore has no unique
  /// constraints, and Security Rules cannot perform collection-wide duplicate
  /// queries. Concurrent or direct writes must not rely on this as a database
  /// constraint.
  Future<void> _ensureUnique(
    String uid,
    BookDraft draft, {
    String? excludingId,
  }) async {
    final wantedTitle = _uniquenessText(draft.title);
    final wantedAuthor = _uniquenessText(draft.author);
    final snapshot = await _books.where('userId', isEqualTo: uid).get();

    for (final document in snapshot.docs) {
      if (document.id == excludingId) continue;
      final data = document.data();
      final title = data['title'];
      final author = data['author'];
      if (title is String &&
          author is String &&
          _uniquenessText(title) == wantedTitle &&
          _uniquenessText(author) == wantedAuthor) {
        throw const DuplicateBookException();
      }
    }
  }

  String _uniquenessText(String value) => value.trim().toLowerCase();

  BookRepositoryException _friendlyError(String action, Object error) {
    if (error is BookRepositoryException) return error;
    if (error is FirebaseException) {
      return BookRepositoryException(
        'Could not $action: ${error.message ?? error.code}.',
        cause: error,
      );
    }
    return BookRepositoryException('Could not $action.', cause: error);
  }
}
