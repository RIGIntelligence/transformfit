import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/services/crashlytics/crashlytics_service.dart';
import 'package:transformfit/services/analytics/analytics_backend.dart';
import 'package:transformfit/services/analytics/analytics_events.dart';
import 'package:transformfit/services/notifications/notification_service.dart';
import 'package:transformfit/services/notifications/notification_scheduler.dart';
import 'package:transformfit/config/feature_flags.dart';

void main() {
  group('CrashReportingService', () {
    test('LocalCrashReportingService records errors and breadcrumbs', () {
      final crash = LocalCrashReportingService();
      crash.setUserId('u1');
      crash.setCustomKey('plan', 'pro');
      crash.log('test breadcrumb');
      crash.recordError(Exception('test'), StackTrace.current, fatal: false);
      // No exceptions = pass
    });

    test('SentryCrashReportingService is a no-op stub', () {
      final sentry = SentryCrashReportingService();
      sentry.recordError(Exception('stub'), null);
      sentry.setUserId('u1');
      sentry.setCustomKey('k', 'v');
      sentry.log('stub log');
      sentry.flush();
      // No exceptions = pass
    });

    test('createCrashReportingService returns LocalCrashReportingService', () {
      final service = createCrashReportingService();
      expect(service, isA<LocalCrashReportingService>());
    });
  });

  group('AnalyticsBackend', () {
    test('tracks events and drains queue', () {
      final backend = AnalyticsBackend(sessionId: 's1', platform: 'test', appVersion: '1.0');
      backend.setUserId('u1');
      backend.trackSimple('test_event', EventCategory.engagement, {'key': 'val'});
      expect(backend.queueLength, 1);
      backend.track(AnalyticsEvents.workoutStart(workoutId: 'w1', workoutName: 'Push'));
      expect(backend.queueLength, 2);
      final json = backend.drainQueueAsJson();
      expect(json.length, 2);
      expect(json[0]['name'], 'test_event');
    });

    test('all 13 event factories create valid events', () {
      final events = [
        AnalyticsEvents.appOpen(),
        AnalyticsEvents.screenView(screenName: 'home'),
        AnalyticsEvents.workoutStart(workoutId: 'w1'),
        AnalyticsEvents.workoutComplete(workoutId: 'w1', durationSeconds: 3600, totalSets: 20, totalExercises: 6),
        AnalyticsEvents.setLogged(exerciseId: 'e1', exerciseName: 'Squat', weight: 100, reps: 5),
        AnalyticsEvents.coachInteraction(interactionType: 'chat'),
        AnalyticsEvents.moodLogged(moodScore: 4),
        AnalyticsEvents.nutritionLogged(calories: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 60),
        AnalyticsEvents.achievementUnlocked(achievementId: 'a1', achievementName: 'First Workout'),
        AnalyticsEvents.streakMilestone(streakDays: 7, milestone: '7'),
        AnalyticsEvents.featureUsed(featureName: 'timer'),
        AnalyticsEvents.errorOccurred(errorCode: 'E001', errorMessage: 'test'),
        AnalyticsEvents.performanceMetric(metricName: 'load_time', value: 1.2, unit: 's'),
      ];
      expect(events.length, 13);
      for (final e in events) {
        expect(e.name, isNotEmpty);
        expect(e.toJson(), isA<Map>());
      }
    });

    test('OfflineEventStore FIFO drain', () {
      final store = OfflineEventStore(maxEvents: 100);
      for (var i = 0; i < 5; i++) {
        store.add(AnalyticsEvent(name: 'e$i', category: EventCategory.engagement, properties: {}));
      }
      expect(store.count, 5);
      final drained = store.drain(3);
      expect(drained.length, 3);
      expect(store.count, 2);
    });
  });

  group('NotificationService', () {
    test('LocalNotificationService schedules and cancels', () async {
      final notif = LocalNotificationService();
      expect(notif.pendingCount, 0);
      expect(await notif.requestPermission(), isTrue);
      await notif.scheduleDaily(hour: 9, minute: 0);
      expect(notif.pendingCount, 1);
      await notif.scheduleWorkoutReminder(hour: 18, minute: 0, weekdays: [1, 3, 5]);
      expect(notif.pendingCount, 2);
      await notif.scheduleMoodCheckIn(hour: 14, minute: 30);
      await notif.scheduleStreakRisk(streakDays: 7, hour: 20, minute: 0);
      await notif.scheduleAchievement(achievementName: 'Test');
      expect(notif.pendingCount, 5);
      // achievement is immediate (now), so it sorts first
      expect(notif.pendingNotifications.first.type, NotificationType.achievement);
      final daily = notif.pendingNotifications.firstWhere((n) => n.type == NotificationType.dailyCheckin);
      expect(daily.recurring, isTrue);
      await notif.cancel(notif.pendingNotifications.first.id);
      expect(notif.pendingCount, 4);
      await notif.cancelAll();
      expect(notif.pendingCount, 0);
    });
  });

  group('NotificationScheduler', () {
    test('caps at 3 notifications per day', () async {
      final scheduler = NotificationScheduler(LocalNotificationService());
      final count = await scheduler.scheduleForDay(UserBehaviorSignals(
        trainingWeekdays: [DateTime.now().weekday],
        moodLoggedToday: false,
        streakAtRisk: true,
        currentStreak: 10,
      ));
      expect(count, 3);
    });

    test('only daily when mood logged, not training day, no streak risk', () async {
      final scheduler = NotificationScheduler(LocalNotificationService());
      final count = await scheduler.scheduleForDay(UserBehaviorSignals(
        trainingWeekdays: [(DateTime.now().weekday % 7) + 1], // tomorrow
        moodLoggedToday: true,
        streakAtRisk: false,
      ));
      expect(count, 1);
    });
  });

  group('FeatureFlags', () {
    test('FlagNames constants match expected values', () {
      expect(FlagNames.llmCoach, 'enableLlmCoach');
      expect(FlagNames.pushNotifications, 'enablePushNotifications');
      expect(FlagNames.crashReporting, 'enableCrashReporting');
      expect(FlagNames.analytics, 'enableAnalytics');
      expect(FlagNames.social, 'enableSocial');
      expect(FlagNames.cameraFormCheck, 'enableCameraFormCheck');
    });

    test('FeatureFlagOverrides set/clear/clearAll', () {
      final overrides = FeatureFlagOverrides();
      final resolver = FeatureFlagResolver(overrides: overrides);
      expect(resolver.isEnabled(FlagNames.crashReporting), isFalse);
      expect(resolver.isEnabled(FlagNames.analytics), isFalse);
      overrides.setFlag(FlagNames.analytics, true);
      expect(resolver.isEnabled(FlagNames.analytics), isTrue);
      overrides.clearFlag(FlagNames.analytics);
      expect(resolver.isEnabled(FlagNames.analytics), isFalse);
      overrides.setFlag(FlagNames.crashReporting, true);
      overrides.clearAll();
      expect(resolver.isEnabled(FlagNames.crashReporting), isFalse);
    });

    test('compile-time defaults: only llmCoach is true', () {
      expect(FeatureFlags.enableLlmCoach, isTrue);
      expect(FeatureFlags.enablePushNotifications, isFalse);
      expect(FeatureFlags.enableCrashReporting, isFalse);
      expect(FeatureFlags.enableAnalytics, isFalse);
      expect(FeatureFlags.enableSocial, isFalse);
      expect(FeatureFlags.enableCameraFormCheck, isFalse);
    });
  });
}
