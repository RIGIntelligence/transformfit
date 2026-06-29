import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:transformfit/bootstrap/app_bootstrap.dart';
import 'package:transformfit/navigation/app_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';

SemanticsHandle? _webSemanticsHandle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    _webSemanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
    usePathUrlStrategy();
  }

  await AppBootstrap().initialize();

  runApp(const ProviderScope(child: TransformFitApp()));
}

class TransformFitApp extends ConsumerWidget {
  const TransformFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TransformFit',
      theme: buildDigitalAtelierTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
