import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../utils/book_validators.dart';

class BookForm extends StatefulWidget {
  const BookForm({
    super.key,
    this.initialBook,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.onCancel,
  });

  final Book? initialBook;
  final Future<void> Function(BookDraft) onSubmit;
  final String submitLabel;
  final VoidCallback? onCancel;

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _ratingController;
  late final TextEditingController _notesController;

  late String _genre;
  late String _status;
  bool _hasSubmitted = false;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final book = widget.initialBook;
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _ratingController = TextEditingController(
      text: book?.rating?.toString() ?? '',
    );
    _notesController = TextEditingController(text: book?.notes ?? '');
    _genre = BookValidators.allowedGenres.contains(book?.genre)
        ? book!.genre
        : '';
    _status = BookValidators.allowedStatuses.contains(book?.status)
        ? book!.status
        : '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    setState(() {
      _hasSubmitted = true;
      _saveError = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final ratingText = _ratingController.text.trim();
    final draft = BookDraft(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      genre: _genre,
      status: _status,
      rating: ratingText.isEmpty ? null : int.parse(ratingText),
      favorite: widget.initialBook?.favorite ?? false,
      notes: _notesController.text,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(draft);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saveError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is BookRepositoryException) return error.message;
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _hasSubmitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            enabled: !_isSaving,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Enter book title',
              border: OutlineInputBorder(),
            ),
            validator: BookValidators.title,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _authorController,
            enabled: !_isSaving,
            textInputAction: TextInputAction.next,
            maxLength: 60,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            decoration: const InputDecoration(
              labelText: 'Author',
              hintText: 'Enter author name',
              border: OutlineInputBorder(),
            ),
            validator: BookValidators.author,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _genre,
            decoration: const InputDecoration(
              labelText: 'Genre',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem(value: '', child: Text('Choose genre')),
              ...BookValidators.allowedGenres.map(
                (genre) => DropdownMenuItem(value: genre, child: Text(genre)),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (value) => setState(() => _genre = value ?? ''),
            validator: BookValidators.genre,
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem(value: '', child: Text('Choose status')),
              ...BookValidators.allowedStatuses.map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status)),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (value) => setState(() => _status = value ?? ''),
            validator: BookValidators.status,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _ratingController,
            enabled: !_isSaving,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-.0-9]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Rating',
              hintText: 'Optional, 0 to 5',
              border: OutlineInputBorder(),
            ),
            validator: BookValidators.rating,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _notesController,
            enabled: !_isSaving,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional notes',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: BookValidators.notes,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.submitLabel),
                ),
              ),
            ],
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(
              _saveError!,
              key: const ValueKey('book-form-save-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
