import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/behavior/behavioral_repair_loop.dart';
import 'package:transformfit/features/coaching/coach_command_center.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/coaching/dai_interface.dart';
import 'package:transformfit/features/emotion/emotional_experience_map.dart';
import 'package:transformfit/features/rig_systems/rig_systems_engineering.dart';
import 'package:transformfit/features/reviews/five_star_experience.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/wearables/health_wearable_adapter.dart';

final coachNoteProvider = Provider<String>((ref) {
  return ref.watch(coachSignalProvider).coachNote;
});

final coachSignalProvider = Provider<CoachSignal>((ref) {
  return buildCoachSignal(ref.watch(sessionStateProvider));
});

final daiInterfaceProvider = Provider<DaiInterface>((ref) {
  return buildDaiInterface(ref.watch(sessionStateProvider));
});

final wearableSyncAdapterProvider = Provider<WearableSyncAdapter>((ref) {
  return HealthWearableAdapter();
});

final behavioralRepairLoopProvider = Provider<BehavioralRepairLoop>((ref) {
  return buildBehavioralRepairLoop(ref.watch(sessionStateProvider));
});

final emotionalExperienceMapProvider = Provider<EmotionalExperienceMap>((ref) {
  return buildEmotionalExperienceMap(ref.watch(sessionStateProvider));
});

final coachCommandCenterProvider = Provider<CoachCommandCenter>((ref) {
  return buildCoachCommandCenter(ref.watch(sessionStateProvider));
});

final rigSystemsEngineeringProvider = Provider<RigSystemsEngineeringSnapshot>((
  ref,
) {
  return buildRigSystemsEngineeringSnapshot(ref.watch(sessionStateProvider));
});

final fiveStarExperienceMomentProvider = Provider<FiveStarExperienceMoment>((
  ref,
) {
  return buildFiveStarExperienceMoment(ref.watch(sessionStateProvider));
});
