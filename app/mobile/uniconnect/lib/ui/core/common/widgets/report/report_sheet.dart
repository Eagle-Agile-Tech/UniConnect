import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../utils/enums.dart';
import '../../../../../utils/helper_functions.dart';
import '../../../../../utils/result.dart';

typedef ReportSubmitCallback =
    Future<Result<void>> Function(ReportReason reason, String? message);

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({super.key, required this.title, required this.onSubmit});

  final String title;
  final ReportSubmitCallback onSubmit;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final TextEditingController _messageController = TextEditingController();
  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReportReason>(
            initialValue: _selectedReason,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select category'),
            items: ReportReason.values
                .map(
                  (reason) => DropdownMenuItem(
                    value: reason,
                    child: Text(reason.label),
                  ),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _selectedReason = value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            enabled: !_isSubmitting,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Message (optional)',
              hintText: 'Add more details...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await widget.onSubmit(
      _selectedReason!,
      _messageController.text,
    );

    if (!mounted) return;

    result.fold(
      (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report submitted')));
      },
      (error, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(UCHelperFunctions.getErrorMessage(error))),
        );
      },
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
