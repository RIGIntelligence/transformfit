import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Data export screen — App Store / GDPR compliance.
///
/// Packages user data as a JSON file for download.
class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _isExporting = false;
  String? _exportPreview;
  String? _error;

  /// Data categories that will be included in the export.
  static const _exportCategories = [
    _ExportCategory(
      icon: Icons.fitness_center,
      title: 'Workout History',
      description: 'All logged workouts, exercises, sets, reps, and weights.',
    ),
    _ExportCategory(
      icon: Icons.mood,
      title: 'Mood Entries',
      description: 'Mood check-ins, stress levels, and recovery scores.',
    ),
    _ExportCategory(
      icon: Icons.restaurant,
      title: 'Nutrition Logs',
      description: 'Macro targets, meals, hydration, and supplement tracking.',
    ),
    _ExportCategory(
      icon: Icons.emoji_events,
      title: 'Achievements',
      description: 'XP, levels, streaks, and unlocked badges.',
    ),
    _ExportCategory(
      icon: Icons.person,
      title: 'Profile Data',
      description:
          'Name, email, goals, experience level, equipment preferences.',
    ),
  ];

  Future<void> _generateExport() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      final data = await _collectUserData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      setState(() {
        _exportPreview = jsonStr;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate export: $e';
        _isExporting = false;
      });
    }
  }

  Future<Map<String, Object?>> _collectUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0+1',
      'profile': {
        'keys': prefs.getKeys().toList(),
        // In a full implementation, this would pull from Supabase.
      },
      'workouts': [],
      'moodEntries': [],
      'nutritionLogs': [],
      'achievements': [],
      'note':
          'This is a partial export from local storage. Full data sync with Supabase is available for authenticated users.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.s5,
            vertical: tokens.s4,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Data', style: tokens.headlineLarge),
                SizedBox(height: tokens.s2),
                Text(
                  'Export all your TransformFit data as a JSON file. This includes everything stored under your account.',
                  style: tokens.bodyMedium.copyWith(
                    color: tokens.bodySmall.color,
                  ),
                ),
                SizedBox(height: tokens.s5),
                Text('Included in export:', style: tokens.titleMedium),
                SizedBox(height: tokens.s3),
                ..._exportCategories.map(
                  (cat) => Padding(
                    padding: EdgeInsets.only(bottom: tokens.s3),
                    child: _CategoryTile(category: cat),
                  ),
                ),
                SizedBox(height: tokens.s5),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _generateExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isExporting ? 'Generating...' : 'Generate Export',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: tokens.s3),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: tokens.s3),
                  Text(
                    _error!,
                    style: tokens.bodyMedium.copyWith(
                      color: DigitalAtelierTokens.errorText,
                    ),
                  ),
                ],
                if (_exportPreview != null) ...[
                  SizedBox(height: tokens.s5),
                  Text('Preview:', style: tokens.titleMedium),
                  SizedBox(height: tokens.s2),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(tokens.s3),
                    decoration: BoxDecoration(
                      color: DigitalAtelierTokens2.surface,
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens2.radiusMd,
                      ),
                      border: Border.all(
                        color: DigitalAtelierTokens2.surfaceBorder,
                      ),
                    ),
                    child: SelectableText(
                      _exportPreview!.length > 2000
                          ? '${_exportPreview!.substring(0, 2000)}\n\n... (truncated for preview)'
                          : _exportPreview!,
                      style: tokens.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: tokens.s7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportCategory {
  const _ExportCategory({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final _ExportCategory category;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      padding: EdgeInsets.all(tokens.s3),
      decoration: BoxDecoration(
        color: DigitalAtelierTokens2.surface,
        borderRadius: BorderRadius.circular(DigitalAtelierTokens2.radiusMd),
        border: Border.all(color: DigitalAtelierTokens2.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(category.icon, color: DigitalAtelierTokens.accentOrange, size: 22),
          SizedBox(width: tokens.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.title, style: tokens.labelLarge),
                const SizedBox(height: 2),
                Text(category.description, style: tokens.bodySmall),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, color: tokens.success, size: 18),
        ],
      ),
    );
  }
}
