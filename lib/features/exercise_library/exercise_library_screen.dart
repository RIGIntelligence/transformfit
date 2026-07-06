import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/exercise_library/exercise_database.dart';
import 'package:transformfit/features/exercise_library/exercise_model.dart';
import 'package:transformfit/features/exercise_library/exercise_search.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/hero_background.dart';

// ---------------------------------------------------------------------------
// Exercise library screen — search, filter, browse 110 exercises.
// ---------------------------------------------------------------------------

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  List<Exercise> _filteredExercises = ExerciseDatabase.exercises;
  MuscleGroup? _selectedMuscle;
  ExerciseType? _selectedType;
  DifficultyLevel? _selectedDifficulty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      var results = _searchController.text.trim().isEmpty
          ? ExerciseDatabase.exercises
          : ExerciseSearch.searchByName(_searchController.text);

      if (_selectedMuscle != null) {
        results = results
            .where((e) => e.primaryMuscles.contains(_selectedMuscle))
            .toList();
      }
      if (_selectedType != null) {
        results = results.where((e) => e.type == _selectedType).toList();
      }
      if (_selectedDifficulty != null) {
        results =
            results.where((e) => e.difficulty == _selectedDifficulty).toList();
      }

      _filteredExercises = results;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedMuscle = null;
      _selectedType = null;
      _selectedDifficulty = null;
      _filteredExercises = ExerciseDatabase.exercises;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Exercise library screen',
      child: Scaffold(
        backgroundColor: DigitalAtelierTokens.background,
        appBar: AppBar(
          backgroundColor: DigitalAtelierTokens.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: DigitalAtelierTokens.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
          ),
          title: Text(
            'Exercise Library',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
              color: DigitalAtelierTokens.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_selectedMuscle != null ||
                _selectedType != null ||
                _selectedDifficulty != null)
              Semantics(
                label: 'Clear all filters',
                button: true,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: DigitalAtelierTokens.accentOrange,
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search bar.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Semantics(
                  label: 'Search exercises',
                  textField: true,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    style: TextStyle(
                      color: DigitalAtelierTokens.textPrimary,
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search exercises...',
                      hintStyle: TextStyle(
                        color: DigitalAtelierTokens.textPrimary
                            .withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(Icons.search,
                          color: DigitalAtelierTokens.textPrimary
                              .withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: DigitalAtelierTokens2.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            DigitalAtelierTokens.cornerRadius * 2),
                        borderSide: BorderSide(
                            color: DigitalAtelierTokens2.surfaceBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            DigitalAtelierTokens.cornerRadius * 2),
                        borderSide: BorderSide(
                            color: DigitalAtelierTokens2.surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            DigitalAtelierTokens.cornerRadius * 2),
                        borderSide: BorderSide(
                            color: DigitalAtelierTokens.accentOrange
                                .withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Filter chips.
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  children: [
                    _FilterChipGroup<MuscleGroup>(
                      label: 'Muscle',
                      options: MuscleGroup.values,
                      selected: _selectedMuscle,
                      labelBuilder: (m) => m.name,
                      onSelected: (v) {
                        setState(() => _selectedMuscle = v);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChipGroup<ExerciseType>(
                      label: 'Equipment',
                      options: ExerciseType.values,
                      selected: _selectedType,
                      labelBuilder: (t) => t.name,
                      onSelected: (v) {
                        setState(() => _selectedType = v);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChipGroup<DifficultyLevel>(
                      label: 'Difficulty',
                      options: DifficultyLevel.values,
                      selected: _selectedDifficulty,
                      labelBuilder: (d) => d.name,
                      onSelected: (v) {
                        setState(() => _selectedDifficulty = v);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),

              // Results count.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${_filteredExercises.length} exercises',
                      style: TextStyle(
                        color: DigitalAtelierTokens.textPrimary
                            .withValues(alpha: 0.5),
                        fontFamily: DigitalAtelierTokens.dataFontFamily,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Exercise list.
              Expanded(
                child: _filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                color: DigitalAtelierTokens.textPrimary
                                    .withValues(alpha: 0.3),
                                size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No exercises found',
                              style: TextStyle(
                                color: DigitalAtelierTokens.textPrimary
                                    .withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          return _ExerciseCard(
                            exercise: _filteredExercises[index],
                            onTap: () => _showExerciseDetail(
                                context, _filteredExercises[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseDetail(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DigitalAtelierTokens2.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) {
          return _ExerciseDetailSheet(
            exercise: exercise,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip group — dropdown-style filter
// ---------------------------------------------------------------------------

class _FilterChipGroup<T> extends StatelessWidget {
  const _FilterChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String label;
  final List<T> options;
  final T? selected;
  final String Function(T) labelBuilder;
  final void Function(T?) onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filter by $label',
      button: true,
      child: FilterChip(
        label: Text(
          selected != null ? labelBuilder(selected as T) : label,
          style: TextStyle(
            color: selected != null
                ? DigitalAtelierTokens.background
                : DigitalAtelierTokens.textPrimary.withValues(alpha: 0.7),
            fontFamily: DigitalAtelierTokens.dataFontFamily,
            fontSize: 13,
          ),
        ),
        selected: selected != null,
        onSelected: (_) {
          if (selected != null) {
            onSelected(null);
          } else {
            _showPicker(context);
          }
        },
        selectedColor: DigitalAtelierTokens.accentOrange,
        backgroundColor: DigitalAtelierTokens2.surface,
        side: BorderSide(
          color: selected != null
              ? DigitalAtelierTokens.accentOrange
              : DigitalAtelierTokens2.surfaceBorder,
        ),
        showCheckmark: false,
        avatar: selected != null
            ? null
            : Icon(Icons.arrow_drop_down,
                color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
                size: 18),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DigitalAtelierTokens2.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Semantics(
        label: 'Select $label filter',
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Filter by $label',
                  style: TextStyle(
                    color: DigitalAtelierTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (ctx, index) {
                    final option = options[index];
                    return Semantics(
                      label: labelBuilder(option),
                      button: true,
                      child: ListTile(
                        title: Text(
                          labelBuilder(option),
                          style: TextStyle(
                            color: DigitalAtelierTokens.textPrimary,
                            fontFamily: DigitalAtelierTokens.dataFontFamily,
                          ),
                        ),
                        trailing: selected == option
                            ? Icon(Icons.check,
                                color: DigitalAtelierTokens.accentOrange)
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          onSelected(option);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, this.onTap});

  final Exercise exercise;
  final VoidCallback? onTap;

  String _muscleLabel(List<MuscleGroup> muscles) {
    return muscles.map((m) => m.name).join(', ');
  }

  Color _difficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return const Color(0xFF10B981);
      case DifficultyLevel.intermediate:
        return const Color(0xFFF59E0B);
      case DifficultyLevel.advanced:
        return const Color(0xFFEF4444);
    }
  }

  /// Resolve the image asset for this exercise.
  /// Checks the exercise's imageAsset field first, then the ID-based map,
  /// then falls back to a muscle-group placeholder.
  String _resolveImage() {
    if (exercise.imageAsset != null) return exercise.imageAsset!;
    return exerciseImageAsset(exercise.id) ??
        muscleGroupPlaceholder(exercise.primaryMuscles.first.name);
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(exercise.difficulty);
    final imageAsset = _resolveImage();

    return Semantics(
      label:
          '${exercise.name}, ${exercise.type.name}, ${_muscleLabel(exercise.primaryMuscles)}',
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    DigitalAtelierTokens.cornerRadius * 2),
                border: Border.all(
                  color: DigitalAtelierTokens2.surfaceBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      imageAsset,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      cacheWidth: 128,
                      cacheHeight: 128,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(
                            color: DigitalAtelierTokens.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${exercise.type.name} · ${_muscleLabel(exercise.primaryMuscles)}',
                          style: TextStyle(
                            color: DigitalAtelierTokens.textPrimary
                                .withValues(alpha: 0.5),
                            fontSize: 12,
                            fontFamily: DigitalAtelierTokens.dataFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.difficulty.name,
                      style: TextStyle(
                        color: diffColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: DigitalAtelierTokens.dataFontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    color: DigitalAtelierTokens.textPrimary
                        .withValues(alpha: 0.3),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise detail sheet
// ---------------------------------------------------------------------------

class _ExerciseDetailSheet extends StatelessWidget {
  const _ExerciseDetailSheet({
    required this.exercise,
    required this.scrollController,
  });

  final Exercise exercise;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${exercise.name} details',
      child: Container(
        decoration: const BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle bar.
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DigitalAtelierTokens.textPrimary
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title.
            Text(
              exercise.name,
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: DigitalAtelierTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Tags.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Tag(label: exercise.type.name),
                _Tag(label: exercise.difficulty.name),
                if (exercise.isCompound) const _Tag(label: 'Compound'),
              ],
            ),
            const SizedBox(height: 8),

            // Muscles.
            Text(
              'Primary: ${exercise.primaryMuscles.map((m) => m.name).join(', ')}',
              style: TextStyle(
                color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                fontSize: 14,
                fontFamily: DigitalAtelierTokens.dataFontFamily,
              ),
            ),
            if (exercise.secondaryMuscles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Secondary: ${exercise.secondaryMuscles.map((m) => m.name).join(', ')}',
                  style: TextStyle(
                    color: DigitalAtelierTokens.textPrimary
                        .withValues(alpha: 0.4),
                    fontSize: 13,
                    fontFamily: DigitalAtelierTokens.dataFontFamily,
                  ),
                ),
              ),

            if (exercise.equipment != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Equipment: ${exercise.equipment}',
                  style: TextStyle(
                    color: DigitalAtelierTokens.textPrimary
                        .withValues(alpha: 0.4),
                    fontSize: 13,
                    fontFamily: DigitalAtelierTokens.dataFontFamily,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Instructions.
            _DetailSection(
              title: 'Instructions',
              items: exercise.instructions,
              icon: Icons.list_alt_outlined,
            ),

            // Form cues.
            _DetailSection(
              title: 'Form Cues',
              items: exercise.formCues,
              icon: Icons.tips_and_updates_outlined,
            ),

            // Common mistakes.
            _DetailSection(
              title: 'Common Mistakes',
              items: exercise.commonMistakes,
              icon: Icons.warning_amber_outlined,
              isWarning: true,
            ),

            const SizedBox(height: 24),

            // Close button.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DigitalAtelierTokens.accentOrange,
                  foregroundColor: DigitalAtelierTokens.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens.cornerRadius),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: DigitalAtelierTokens.accentOrange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: DigitalAtelierTokens.dataFontFamily,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.items,
    required this.icon,
    this.isWarning = false,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final accentColor = isWarning
        ? const Color(0xFFF59E0B)
        : DigitalAtelierTokens.accentOrange;

    return Semantics(
      label: '$title section with ${items.length} items',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: DigitalAtelierTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...items.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: DigitalAtelierTokens.dataFontFamily,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: DigitalAtelierTokens.textPrimary
                                  .withValues(alpha: 0.75),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
