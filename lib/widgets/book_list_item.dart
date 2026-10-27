import 'package:flutter/material.dart';

import '../models/book.dart';

/// Single book list item displaying title, author, genre, status, and favorite toggle.
class BookListItem extends StatelessWidget {
  const BookListItem({
    super.key,
    required this.book,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        title: Text(
          book.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              book.author,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Text(
                    book.genre,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.indigo.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Text(
                    book.status,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: book.favorite ? 'Remove favorite' : 'Mark as favorite',
          icon: Icon(
            book.favorite ? Icons.star : Icons.star_border,
            color: book.favorite ? Colors.amber.shade700 : Colors.grey,
          ),
          onPressed: onToggleFavorite,
        ),
      ),
    );
  }
}
