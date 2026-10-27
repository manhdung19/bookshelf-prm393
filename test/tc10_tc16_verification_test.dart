import 'dart:async';

import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/repositories/book_repository.dart';
import 'package:bookshelf/screens/book_list_screen.dart';
import 'package:bookshelf/services/auth_service.dart';
import 'package:bookshelf/widgets/book_list_item.dart';
import 'package:bookshelf/widgets/book_summary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository implementing [BookRepository] for deterministic, isolated testing.
class FakeBookRepository implements BookRepository {
  FakeBookRepository(List<Book> initialBooks)
      : _books = List<Book>.from(initialBooks);

  final List<Book> _books;
  final StreamController<List<Book>> _controller =
      StreamController<List<Book>>.broadcast();

  @override
  Stream<List<Book>> watchUserBooks(String uid) async* {
    yield List<Book>.unmodifiable(_books);
    yield* _controller.stream;
  }

  @override
  Future<void> addBook(String uid, BookDraft draft) async {
    final newBook = Book(
      id: 'book_${_books.length + 1}',
      userId: uid,
      title: draft.title,
      author: draft.author,
      genre: draft.genre,
      status: draft.status,
      rating: draft.rating,
      favorite: draft.favorite,
      notes: draft.notes,
      createdAt: DateTime.now(),
    );
    _books.add(newBook);
    _controller.add(List<Book>.unmodifiable(_books));
  }

  @override
  Future<void> updateBook(Book book, BookDraft draft) async {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      _books[index] = Book(
        id: book.id,
        userId: book.userId,
        title: draft.title,
        author: draft.author,
        genre: draft.genre,
        status: draft.status,
        rating: draft.rating,
        favorite: draft.favorite,
        notes: draft.notes,
        createdAt: book.createdAt,
      );
      _controller.add(List<Book>.unmodifiable(_books));
    }
  }

  @override
  Future<void> deleteBook(Book book) async {
    _books.removeWhere((b) => b.id == book.id);
    _controller.add(List<Book>.unmodifiable(_books));
  }

  @override
  Future<void> toggleFavorite(Book book) async {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      _books[index] = _books[index].copyWith(favorite: !_books[index].favorite);
      _controller.add(List<Book>.unmodifiable(_books));
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Fake AuthService that does not contact Firebase Auth.
class FakeAuthService implements AuthService {
  bool didSignOut = false;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signUp({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }
}

List<Book> createTestBooks() {
  return [
    Book(
      id: '1',
      userId: 'test_user',
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      genre: 'Fiction',
      status: 'To Read',
      rating: 5,
      favorite: true,
      notes: 'Classic fantasy',
      createdAt: DateTime(2026, 1, 1),
    ),
    Book(
      id: '2',
      userId: 'test_user',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      genre: 'Academic',
      status: 'Reading',
      rating: 4,
      favorite: false,
      notes: 'Software craft',
      createdAt: DateTime(2026, 1, 2),
    ),
    Book(
      id: '3',
      userId: 'test_user',
      title: 'Sapiens',
      author: 'Yuval Noah Harari',
      genre: 'Non-Fiction',
      status: 'Finished',
      rating: 5,
      favorite: true,
      notes: 'History of humankind',
      createdAt: DateTime(2026, 1, 3),
    ),
    Book(
      id: '4',
      userId: 'test_user',
      title: 'animal farm',
      author: 'George Orwell',
      genre: 'Fiction',
      status: 'Finished',
      rating: 4,
      favorite: false,
      notes: 'Political satire',
      createdAt: DateTime(2026, 1, 4),
    ),
    Book(
      id: '5',
      userId: 'test_user',
      title: 'Animal Farm',
      author: 'Another Author',
      genre: 'Fiction',
      status: 'To Read',
      rating: 3,
      favorite: false,
      notes: 'Different author',
      createdAt: DateTime(2026, 1, 5),
    ),
  ];
}

Widget createTestApp({
  required FakeBookRepository repository,
  required FakeAuthService authService,
}) {
  return MaterialApp(
    home: BookListScreen(
      userId: 'test_user',
      email: 'tester@example.com',
      repository: repository,
      authService: authService,
    ),
  );
}

void main() {
  group('TC10 — Book List Sorting A–Z', () {
    testWidgets('Sorts books by title ascending, case-insensitively, with author tie-break',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      final displayedBooks = tester
          .widgetList<BookListItem>(find.byType(BookListItem))
          .map((item) => item.book)
          .toList();

      expect(displayedBooks.length, equals(5));

      // Expected sorted order:
      // 1. "Animal Farm" by Another Author
      // 2. "animal farm" by George Orwell
      // 3. "Clean Code" by Robert C. Martin
      // 4. "Sapiens" by Yuval Noah Harari
      // 5. "The Hobbit" by J.R.R. Tolkien
      expect(displayedBooks[0].title, equals('Animal Farm'));
      expect(displayedBooks[0].author, equals('Another Author'));

      expect(displayedBooks[1].title, equals('animal farm'));
      expect(displayedBooks[1].author, equals('George Orwell'));

      expect(displayedBooks[2].title, equals('Clean Code'));
      expect(displayedBooks[2].author, equals('Robert C. Martin'));

      expect(displayedBooks[3].title, equals('Sapiens'));
      expect(displayedBooks[3].author, equals('Yuval Noah Harari'));

      expect(displayedBooks[4].title, equals('The Hobbit'));
      expect(displayedBooks[4].author, equals('J.R.R. Tolkien'));

      repository.dispose();
    });

    testWidgets('Realtime list updates place newly added book in proper alphabetical position',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Add a book starting with "B" -> should appear between Animal Farm and Clean Code
      await repository.addBook(
        'test_user',
        const BookDraft(
          title: 'Brave New World',
          author: 'Aldous Huxley',
          genre: 'Fiction',
          status: 'To Read',
        ),
      );
      await tester.pumpAndSettle();

      final displayedBooks = tester
          .widgetList<BookListItem>(find.byType(BookListItem))
          .map((item) => item.book)
          .toList();

      expect(displayedBooks.length, equals(6));

      final titles = displayedBooks.map((b) => b.title).toList();
      expect(titles.indexOf('Brave New World'), equals(2));
      expect(titles[0], equals('Animal Farm'));
      expect(titles[1], equals('animal farm'));
      expect(titles[2], equals('Brave New World'));
      expect(titles[3], equals('Clean Code'));

      repository.dispose();
    });
  });

  group('TC11 — Summary', () {
    testWidgets('Displays Books: N and Favorites: N based only on currently displayed books',
        (tester) async {
      final books = createTestBooks(); // 5 books, 2 favorites

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BookSummary(books: books)),
      ));

      expect(find.text('Books: 5'), findsOneWidget);
      expect(find.text('Favorites: 2'), findsOneWidget);
    });

    testWidgets('Status breakdown sorted by descending count with tie order: To Read, Reading, Finished',
        (tester) async {
      final books = [
        Book(
          id: '1',
          userId: 'u',
          title: 'A',
          author: 'A',
          genre: 'Fiction',
          status: 'Finished',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
        Book(
          id: '2',
          userId: 'u',
          title: 'B',
          author: 'B',
          genre: 'Fiction',
          status: 'Finished',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
        Book(
          id: '3',
          userId: 'u',
          title: 'C',
          author: 'C',
          genre: 'Fiction',
          status: 'Finished',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
        Book(
          id: '4',
          userId: 'u',
          title: 'D',
          author: 'D',
          genre: 'Fiction',
          status: 'To Read',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
        Book(
          id: '5',
          userId: 'u',
          title: 'E',
          author: 'E',
          genre: 'Fiction',
          status: 'To Read',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
        Book(
          id: '6',
          userId: 'u',
          title: 'F',
          author: 'F',
          genre: 'Fiction',
          status: 'Reading',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
        Book(
          id: '7',
          userId: 'u',
          title: 'G',
          author: 'G',
          genre: 'Fiction',
          status: 'Reading',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BookSummary(books: books)),
      ));

      expect(find.text('Books: 7'), findsOneWidget);
      expect(find.text('Favorites: 0'), findsOneWidget);

      final texts = tester
          .widgetList<Text>(find.descendant(
            of: find.byType(BookSummary),
            matching: find.byType(Text),
          ))
          .map((t) => t.data)
          .toList();

      final finishedIndex = texts.indexOf('Finished: 3');
      final toReadIndex = texts.indexOf('To Read: 2');
      final readingIndex = texts.indexOf('Reading: 2');

      // Descending count: Finished (3) before To Read (2) and Reading (2)
      expect(finishedIndex < toReadIndex, isTrue,
          reason: 'Count 3 comes before Count 2');
      // Tie order: To Read comes before Reading
      expect(toReadIndex < readingIndex, isTrue,
          reason: 'Equal counts must tie-break with To Read before Reading');
    });

    testWidgets('Hides zero-count status rows in summary', (tester) async {
      final books = [
        Book(
          id: '1',
          userId: 'u',
          title: 'A',
          author: 'A',
          genre: 'Fiction',
          status: 'Finished',
          rating: null,
          favorite: false,
          notes: '',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BookSummary(books: books)),
      ));

      expect(find.text('Finished: 1'), findsOneWidget);
      expect(find.text('To Read: 0'), findsNothing);
      expect(find.text('Reading: 0'), findsNothing);
    });
  });

  group('TC12 — Genre Filter', () {
    testWidgets('Filters by Fiction, Non-Fiction, Academic, Other and updates list and summary immediately',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Initially 'All': 5 books
      expect(find.text('Books: 5'), findsOneWidget);

      // Select 'Fiction' (first dropdown is Genre)
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fiction').last);
      await tester.pumpAndSettle();

      // Fiction books: The Hobbit, animal farm, Animal Farm (3 books, 1 favorite)
      expect(find.text('Books: 3'), findsOneWidget);
      expect(find.text('Favorites: 1'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing); // Academic
      expect(find.text('Sapiens'), findsNothing); // Non-Fiction

      // Select 'Academic'
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Academic').last);
      await tester.pumpAndSettle();

      expect(find.text('Books: 1'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('The Hobbit'), findsNothing);

      // Select 'Other' -> 0 books
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();

      expect(find.text('Books: 0'), findsOneWidget);
      expect(find.text('No books found'), findsOneWidget);

      repository.dispose();
    });
  });

  group('TC13 — Status Filter', () {
    testWidgets('Filters by All, To Read, Reading, Finished and updates immediately',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Select 'To Read' (second dropdown is Status)
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('To Read').last);
      await tester.pumpAndSettle();

      // To Read: The Hobbit, Animal Farm (2 books)
      expect(find.text('Books: 2'), findsOneWidget);
      expect(find.text('The Hobbit'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing); // Reading
      expect(find.text('Sapiens'), findsNothing); // Finished

      // Select 'Finished'
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finished').last);
      await tester.pumpAndSettle();

      // Finished: Sapiens, animal farm (2 books)
      expect(find.text('Books: 2'), findsOneWidget);
      expect(find.text('Sapiens'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing);

      repository.dispose();
    });
  });

  group('TC14 — Search', () {
    testWidgets('Matches title or author, case-insensitive, trims whitespace, updates on typing',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // 1. Match author case-insensitively
      await tester.enterText(searchField, 'tolkien');
      await tester.pumpAndSettle();

      expect(find.text('The Hobbit'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing);
      expect(find.text('Books: 1'), findsOneWidget);

      // 2. Match with leading & trailing whitespace
      await tester.enterText(searchField, '   clean   ');
      await tester.pumpAndSettle();

      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('The Hobbit'), findsNothing);
      expect(find.text('Books: 1'), findsOneWidget);

      // 3. Match title substring
      await tester.enterText(searchField, 'animal');
      await tester.pumpAndSettle();

      expect(find.text('Books: 2'), findsOneWidget);
      expect(find.text('Another Author'), findsOneWidget);
      expect(find.text('George Orwell'), findsOneWidget);

      repository.dispose();
    });
  });

  group('TC15 — Combined Filters and Favorites', () {
    testWidgets('Combines all active filters with logical AND', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Genre = Fiction
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fiction').last);
      await tester.pumpAndSettle();

      // Status = Finished
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finished').last);
      await tester.pumpAndSettle();

      // Books in Fiction AND Finished: only "animal farm" by George Orwell
      expect(find.text('Books: 1'), findsOneWidget);
      expect(find.text('George Orwell'), findsOneWidget);

      // Add Search = "Orwell" -> still matches
      await tester.enterText(find.byType(TextField), 'Orwell');
      await tester.pumpAndSettle();
      expect(find.text('Books: 1'), findsOneWidget);

      // Add Favorites-only = true -> Orwell is not favorite -> 0 books
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Books: 0'), findsOneWidget);
      expect(find.text('No books found'), findsOneWidget);

      repository.dispose();
    });

    testWidgets('Removing a favorite under favorites-only mode immediately removes book from list',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Enable favorites-only: initially 2 favorites (The Hobbit, Sapiens)
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Books: 2'), findsOneWidget);
      expect(find.text('The Hobbit'), findsOneWidget);
      expect(find.text('Sapiens'), findsOneWidget);

      // Tap favorite star on "Sapiens" to un-favorite
      final sapiensItem = find.widgetWithText(BookListItem, 'Sapiens');
      final starButton = find.descendant(
        of: sapiensItem,
        matching: find.byType(IconButton),
      );

      await tester.tap(starButton);
      await tester.pumpAndSettle();

      // Sapiens must disappear immediately! Only The Hobbit remains!
      expect(find.text('Books: 1'), findsOneWidget);
      expect(find.text('The Hobbit'), findsOneWidget);
      expect(find.text('Sapiens'), findsNothing);

      repository.dispose();
    });
  });

  group('TC16 — Clear and Empty State', () {
    testWidgets('Clear button resets all 4 filter controls to initial state',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Modify all 4 controls:
      // 1. Search text
      await tester.enterText(find.byType(TextField), 'Hobbit');
      await tester.pumpAndSettle();

      // 2. Genre
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fiction').last);
      await tester.pumpAndSettle();

      // 3. Status
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('To Read').last);
      await tester.pumpAndSettle();

      // 4. Favorites switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Books: 1'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Verify all controls reset:
      // Search is empty
      expect(find.text('Hobbit'), findsNothing);
      // All 5 books are visible again
      expect(find.text('Books: 5'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Sapiens'), findsOneWidget);
      expect(find.text('The Hobbit'), findsOneWidget);

      repository.dispose();
    });

    testWidgets('Unmatched query shows exact "No books found" and Books: 0, Favorites: 0 with no status rows',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = FakeBookRepository(createTestBooks());
      final authService = FakeAuthService();

      await tester.pumpWidget(createTestApp(
        repository: repository,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Search for non-existent book
      await tester.enterText(find.byType(TextField), 'NonExistentBookXYZ123');
      await tester.pumpAndSettle();

      // Exact empty text
      expect(find.text('No books found'), findsOneWidget);

      // Summary shows Books: 0 and Favorites: 0
      expect(find.text('Books: 0'), findsOneWidget);
      expect(find.text('Favorites: 0'), findsOneWidget);

      // No status rows
      expect(find.text('To Read: 0'), findsNothing);
      expect(find.text('Reading: 0'), findsNothing);
      expect(find.text('Finished: 0'), findsNothing);

      repository.dispose();
    });
  });
}
