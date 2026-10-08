import 'package:flutter/material.dart';

import 'admin_exception.dart';
import 'admin_theme.dart';

void _show(ScaffoldMessengerState messenger, String message, bool error) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: ts(13, color: Colors.white)),
      backgroundColor: error ? AdminColors.red : AdminColors.green,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 4 : 2),
    ));
}

void showAdminSnack(BuildContext context, String message,
    {bool error = false}) {
  _show(ScaffoldMessenger.of(context), message, error);
}

/// Runs [action] behind a blocking CircularProgressIndicator and reports the
/// result with a SnackBar. Returns true on success.
Future<bool> runAdminAction(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
  bool showLoader = true,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  if (showLoader) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
  try {
    await action();
    if (showLoader) navigator.pop();
    _show(messenger, success, false);
    return true;
  } on AdminException catch (e) {
    if (showLoader) navigator.pop();
    _show(messenger, e.message, true);
    return false;
  } catch (_) {
    if (showLoader) navigator.pop();
    _show(messenger, 'Something went wrong. Please try again.', true);
    return false;
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title, style: ts(17, w: FontWeight.w700)),
      content: Text(message, style: ts(13.5, color: AdminColors.grey)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AdminColors.red)
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Dialog with a single validated text field. Returns trimmed text or null.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String hint,
  String? message,
  String confirmLabel = 'Submit',
  bool required = true,
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      hint: hint,
      message: message,
      confirmLabel: confirmLabel,
      required: required,
      initial: initial,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.required,
    this.message,
    this.initial,
  });
  final String title, hint, confirmLabel;
  final String? message, initial;
  final bool required;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: ts(17, w: FontWeight.w700)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(widget.message!,
                    style: ts(13, color: AdminColors.grey)),
              ),
            TextFormField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (widget.required && t.isEmpty) return 'This field is required';
                if (widget.required && t.length < 3) return 'Please add a bit more detail';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
