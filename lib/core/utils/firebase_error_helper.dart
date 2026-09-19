/// Safely extracts a human-readable message from a caught exception,
/// working around a known Flutter Web + Firebase JS-interop bug.
String describeFirebaseError(Object error) {
  try {
    final code = (error as dynamic).code;
    final message = (error as dynamic).message;
    if (code != null) {
      return message != null ? '$code: $message' : '$code';
    }
  } catch (_) {
    // Reading .code/.message itself threw (the interop bug)
  }

  try {
    return error.toString();
  } catch (_) {
    return 'A Firebase error occurred. Check Firebase Console → Authentication and Firestore Rules.';
  }
}