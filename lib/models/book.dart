import 'package:cloud_firestore/cloud_firestore.dart';

/// A persisted book in the top-level `books` Firestore collection.
class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.rating,
    required this.favorite,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final DateTime createdAt;

  factory Book.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw FormatException('Book ${snapshot.id} has no data.');
    }

    final storedId = data['id'];
    if (storedId is! String || storedId != snapshot.id) {
      throw FormatException('Book ${snapshot.id} has an invalid id.');
    }

    return Book(
      id: storedId,
      userId: _requiredString(data, 'userId', snapshot.id),
      title: _requiredString(data, 'title', snapshot.id),
      author: _requiredString(data, 'author', snapshot.id),
      genre: _requiredString(data, 'genre', snapshot.id),
      status: _requiredString(data, 'status', snapshot.id),
      rating: _optionalRating(data['rating'], snapshot.id),
      favorite: _optionalBool(data['favorite'], fallback: false),
      notes: _optionalString(data['notes']),
      // A server timestamp is temporarily null in a local pending-write
      // snapshot. The estimate keeps the realtime stream usable until the
      // committed Timestamp arrives from Firestore.
      createdAt: _dateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  /// Serializes a fully persisted book. New writes should use
  /// [BookDraft.toFirestore] so Firestore can assign the server timestamp.
  Map<String, Object?> toFirestore() => <String, Object?>{
    'id': id,
    'userId': userId,
    'title': title,
    'author': author,
    'genre': genre,
    'status': status,
    'rating': rating,
    'favorite': favorite,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Book copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? genre,
    String? status,
    int? rating,
    bool clearRating = false,
    bool? favorite,
    String? notes,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      rating: clearRating ? null : rating ?? this.rating,
      favorite: favorite ?? this.favorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Editable book values used by both Add and Edit forms.
class BookDraft {
  const BookDraft({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.favorite = false,
    this.notes = '',
  });

  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;

  factory BookDraft.fromBook(Book book) => BookDraft(
    title: book.title,
    author: book.author,
    genre: book.genre,
    status: book.status,
    rating: book.rating,
    favorite: book.favorite,
    notes: book.notes,
  );

  /// Produces the exact document shape required by the Firestore schema.
  Map<String, Object?> toFirestore({
    required String id,
    required String userId,
    Object? createdAt,
  }) => <String, Object?>{
    'id': id,
    'userId': userId,
    'title': title.trim(),
    'author': author.trim(),
    'genre': genre,
    'status': status,
    'rating': rating,
    'favorite': favorite,
    'notes': notes,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };
}

String _requiredString(
  Map<String, dynamic> data,
  String field,
  String documentId,
) {
  final value = data[field];
  if (value is String) return value;
  throw FormatException('Book $documentId has an invalid $field.');
}

String _optionalString(Object? value) => value is String ? value : '';

bool _optionalBool(Object? value, {required bool fallback}) =>
    value is bool ? value : fallback;

int? _optionalRating(Object? value, String documentId) {
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('Book $documentId has an invalid rating.');
}

DateTime? _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  return null;
}
