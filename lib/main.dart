import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:transformfit/bootstrap/app_bootstrap.dart';
import 'package:transformfit/config/runtime_flags.dart';
import 'package:transformfit/dev/visual_smoke_state.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/session/session_snapshot_store.dart';
import 'package:transformfit/navigation/app_router.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/theme/digital_atelier.dart';

SemanticsHandle? _webSemanticsHandle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    _webSemanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
    usePathUrlStrategy();
  }

  await AppBootstrap().initialize();

  final sessionSnapshotStore = SessionSnapshotStore();
  final storedSessionState = transformfitDemoMode
      ? null
      : await sessionSnapshotStore.load();
  final restoredSessionState = initialSessionStateForStartup(
    demoMode: transformfitDemoMode,
    storedState: storedSessionState,
  );
  final sessionController = SessionController(
    initialState: restoredSessionState,
    snapshotWriter: transformfitDemoMode ? null : sessionSnapshotStore.save,
  );

  runApp(
    ProviderScope(
      overrides: [
        sessionSnapshotStoreProvider.overrideWithValue(sessionSnapshotStore),
        sessionControllerProvider.overrideWithValue(sessionController),
        if (transformfitDemoMode) ...[
          authGuardStateProvider.overrideWith((ref) {
            final state = authGuardStateForStartup(demoMode: true);
            ref.onDispose(state.dispose);
            return state;
          }),
          authControllerProvider.overrideWithValue(AuthController.noop()),
        ],
      ],
      child: const TransformFitApp(),
    ),
  );
}

class TransformFitApp extends ConsumerWidget {
  const TransformFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the auth controller alive so the Supabase auth stream drives the
    // route guard (sign-in/sign-out/session-persistence -> redirect).
    ref.watch(authControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TransformFit',
      theme: buildDigitalAtelierTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

@visibleForTesting
SessionState initialSessionStateForStartup({
  required bool demoMode,
  SessionState? storedState,
}) {
  if (demoMode) {
    return buildVisualSmokeSessionState();
  }
  return storedState ?? const SessionState();
}

@visibleForTesting
AuthGuardState authGuardStateForStartup({required bool demoMode}) {
  return AuthGuardState(
    initialStatus: demoMode
        ? AuthGuardStatus.authenticatedWithProfile
        : AuthGuardStatus.loading,
  );
}
