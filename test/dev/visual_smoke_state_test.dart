import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/dev/visual_smoke_state.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  test('visual smoke state is a valid authenticated product snapshot', () {
    final state = buildVisualSmokeSessionState();
    final restored = SessionState.fromJson(state.toJson());

    expect(restored.readinessEntry, isNotNull);
    expect(restored.activeSession, isNotNull);
    expect(restored.activeSessionPlan, hasLength(3));
    expect(restored.activeSession!.loggedSets, hasLength(2));
    expect(restored.history, hasLength(2));
    expect(restored.lastDebrief?.painNotes, isNull);
    expect(restored.lastDebrief?.nextSessionFocus, contains('third squat set'));
  });
}
