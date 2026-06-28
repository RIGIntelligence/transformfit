import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/navigation/app_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';

SemanticsHandle? _webSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    _webSemanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
  }

  runApp(
    const ProviderScope(
      child: TransformFitApp(),
    ),
  );
}

class TransformFitApp extends StatelessWidget {
  const TransformFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TransformFit',
      theme: buildDigitalAtelierTheme(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
