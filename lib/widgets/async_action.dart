import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';

/// Runs a Firestore/IO [action], surfacing a localized error dialog if it
/// throws instead of letting the exception escape as an unhandled async error.
///
/// Firestore's offline cache makes the happy path resolve locally, but writes
/// can still reject (permission-denied after a caregiver is removed, rules
/// rejection, quota). Returning a success flag lets callers avoid showing a
/// "done" confirmation when the write actually failed.
Future<bool> runGuarded(
  BuildContext context,
  Future<void> Function() action, {
  String? errorMessage,
}) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (context.mounted) {
      showErrorDialog(context, errorMessage ?? S.of(context).errSave);
    }
    return false;
  }
}

/// Shows a single-button informational error dialog.
void showErrorDialog(BuildContext context, String message) {
  showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(S.of(ctx).ok),
        ),
      ],
    ),
  );
}
