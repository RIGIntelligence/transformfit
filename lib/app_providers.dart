import 'package:flutter_riverpod/flutter_riverpod.dart';

final coachNoteProvider = Provider<String>((ref) {
  return 'Coach note: You are building consistency, one deliberate day at a time.';
});
