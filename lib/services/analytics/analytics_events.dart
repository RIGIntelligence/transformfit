/// Pre-defined analytics event constants with typed properties.
///
/// Every trackable event in the app has a constant here. Import this file
/// and call [AnalyticsBackend.track] with the factory constructors below.
library;

import 'package:transformfit/services/analytics/analytics_backend.dart';

/// Factory constructors for all app events.
///
/// Usage:
/// ```dart
/// analytics.track(AnalyticsEvents.workoutStart(
///   workoutId: 'abc',
///   workoutName: 'Push Day',
/// ));
/// ```
abstract final class AnalyticsEvents {
  // -----------------------------------------------------------------------
  // App lifecycle
  // -----------------------------------------------------------------------

  static AnalyticsEvent appOpen({
    String? referrer,
  }) =>
      AnalyticsEvent(
        name: 'app_open',
        category: EventCategory.engagement,
        properties: {
          if (referrer != null) 'referrer': referrer,
        },
      );

  static AnalyticsEvent screenView({
    required String screenName,
    String? previousScreen,
  }) =>
      AnalyticsEvent(
        name: 'screen_view',
        category: EventCategory.engagement,
        properties: {
          'screen': screenName,
          if (previousScreen != null) 'previous_screen': previousScreen,
        },
      );

  // -----------------------------------------------------------------------
  // Workout events
  // -----------------------------------------------------------------------

  static AnalyticsEvent workoutStart({
    required String workoutId,
    String? workoutName,
    String? templateId,
  }) =>
      AnalyticsEvent(
        name: 'workout_start',
        category: EventCategory.engagement,
        properties: {
          'workout_id': workoutId,
          if (workoutName != null) 'workout_name': workoutName,
          if (templateId != null) 'template_id': templateId,
        },
      );

  static AnalyticsEvent workoutComplete({
    required String workoutId,
    required int durationSeconds,
    required int totalSets,
    required int totalExercises,
    double? totalVolumeKg,
  }) =>
      AnalyticsEvent(
        name: 'workout_complete',
        category: EventCategory.engagement,
        properties: {
          'workout_id': workoutId,
          'duration_seconds': durationSeconds,
          'total_sets': totalSets,
          'total_exercises': totalExercises,
          if (totalVolumeKg != null) 'total_volume_kg': totalVolumeKg,
        },
      );

  static AnalyticsEvent setLogged({
    required String exerciseId,
    required String exerciseName,
    required double weight,
    required int reps,
    int? rpe,
    bool isPersonalRecord = false,
  }) =>
      AnalyticsEvent(
        name: 'set_logged',
        category: EventCategory.engagement,
        properties: {
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'weight': weight,
          'reps': reps,
          if (rpe != null) 'rpe': rpe,
          'is_pr': isPersonalRecord,
        },
      );

  // -----------------------------------------------------------------------
  // Coaching events
  // -----------------------------------------------------------------------

  static AnalyticsEvent coachInteraction({
    required String interactionType, // 'chat', 'voice', 'suggestion'
    int? messageLength,
    String? coachPersona,
  }) =>
      AnalyticsEvent(
        name: 'coach_interaction',
        category: EventCategory.engagement,
        properties: {
          'interaction_type': interactionType,
          if (messageLength != null) 'message_length': messageLength,
          if (coachPersona != null) 'coach_persona': coachPersona,
        },
      );

  // -----------------------------------------------------------------------
  // Wellness events
  // -----------------------------------------------------------------------

  static AnalyticsEvent moodLogged({
    required int moodScore, // 1-5
    String? note,
  }) =>
      AnalyticsEvent(
        name: 'mood_logged',
        category: EventCategory.retention,
        properties: {
          'mood_score': moodScore,
          if (note != null) 'note': note,
        },
      );

  static AnalyticsEvent nutritionLogged({
    required int calories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
    String? mealType, // 'breakfast', 'lunch', 'dinner', 'snack'
  }) =>
      AnalyticsEvent(
        name: 'nutrition_logged',
        category: EventCategory.engagement,
        properties: {
          'calories': calories,
          'protein_g': proteinGrams,
          'carbs_g': carbsGrams,
          'fat_g': fatGrams,
          if (mealType != null) 'meal_type': mealType,
        },
      );

  // -----------------------------------------------------------------------
  // Gamification events
  // -----------------------------------------------------------------------

  static AnalyticsEvent achievementUnlocked({
    required String achievementId,
    required String achievementName,
    int? xpEarned,
  }) =>
      AnalyticsEvent(
        name: 'achievement_unlocked',
        category: EventCategory.retention,
        properties: {
          'achievement_id': achievementId,
          'achievement_name': achievementName,
          if (xpEarned != null) 'xp_earned': xpEarned,
        },
      );

  static AnalyticsEvent streakMilestone({
    required int streakDays,
    required String milestone, // '7', '30', '100', etc.
  }) =>
      AnalyticsEvent(
        name: 'streak_milestone',
        category: EventCategory.retention,
        properties: {
          'streak_days': streakDays,
          'milestone': milestone,
        },
      );

  // -----------------------------------------------------------------------
  // Generic events
  // -----------------------------------------------------------------------

  static AnalyticsEvent featureUsed({
    required String featureName,
    String? variant,
  }) =>
      AnalyticsEvent(
        name: 'feature_used',
        category: EventCategory.engagement,
        properties: {
          'feature': featureName,
          if (variant != null) 'variant': variant,
        },
      );

  static AnalyticsEvent errorOccurred({
    required String errorCode,
    required String errorMessage,
    String? screen,
    bool fatal = false,
  }) =>
      AnalyticsEvent(
        name: 'error_occurred',
        category: EventCategory.error,
        properties: {
          'error_code': errorCode,
          'error_message': errorMessage,
          if (screen != null) 'screen': screen,
          'fatal': fatal,
        },
      );

  static AnalyticsEvent performanceMetric({
    required String metricName,
    required double value,
    String? unit,
  }) =>
      AnalyticsEvent(
        name: 'performance_metric',
        category: EventCategory.performance,
        properties: {
          'metric': metricName,
          'value': value,
          if (unit != null) 'unit': unit,
        },
      );
}
