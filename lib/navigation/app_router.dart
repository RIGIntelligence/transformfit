import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/screens/today_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'today',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage<void>(
            child: TodayScreen(),
          );
        },
      ),
    ],
  );
}
