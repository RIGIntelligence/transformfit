import 'package:flutter/foundation.dart';

const bool transformfitVisualSmokeMode = bool.fromEnvironment(
  'TRANSFORMFIT_VISUAL_SMOKE',
);

const bool transformfitLocalDemoMode = bool.fromEnvironment(
  'TRANSFORMFIT_LOCAL_DEMO',
);

const bool transformfitDemoMode =
    transformfitLocalDemoMode || transformfitVisualSmokeMode;

const bool transformfitAuthScreenDemoEntryEnabled =
    transformfitDemoMode || !kReleaseMode;
