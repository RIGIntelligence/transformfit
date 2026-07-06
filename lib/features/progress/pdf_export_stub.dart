library;

/// A chart reference embedded in a progress report.
class ReportChart {
  const ReportChart({
    required this.title,
    required this.description,
    required this.chartType,
  });

  final String title;
  final String description;

  /// Type identifier (e.g. 'volume', 'body_comp', 'strength', 'nutrition').
  final String chartType;
}

/// A recommendation included in the progress report.
class ReportRecommendation {
  const ReportRecommendation({
    required this.title,
    required this.detail,
    required this.priority,
  });

  final String title;
  final String detail;

  /// Priority level: 'high', 'medium', 'low'.
  final String priority;
}

/// A progress report data structure ready for PDF rendering.
class ProgressReport {
  const ProgressReport({
    required this.title,
    required this.dateRange,
    required this.summary,
    required this.charts,
    required this.recommendations,
  });

  /// Report title (e.g. 'TransformFit Progress — Week 12').
  final String title;

  /// Human-readable date range (e.g. 'Jun 1 – Jun 28, 2026').
  final String dateRange;

  /// Executive summary text.
  final String summary;

  /// Charts to be rendered in the PDF.
  final List<ReportChart> charts;

  /// Actionable recommendations.
  final List<ReportRecommendation> recommendations;

  /// Number of charts in the report.
  int get chartCount => charts.length;

  /// Number of high-priority recommendations.
  int get highPriorityCount =>
      recommendations.where((r) => r.priority == 'high').length;
}

/// Status of a PDF export operation.
enum ExportStatus {
  idle,
  generating,
  ready,
  error,
}

/// Stub implementation of a PDF exporter.
///
/// Creates a [ProgressReport] data structure that a real PDF renderer
/// (e.g. pdf package, printing package) can consume.
class PdfExporter {
  PdfExporter();

  ExportStatus _status = ExportStatus.idle;
  ProgressReport? _lastReport;

  /// Current export status.
  ExportStatus get status => _status;

  /// The last generated report, if any.
  ProgressReport? get lastReport => _lastReport;

  /// Generates a [ProgressReport] from the given data.
  ///
  /// In a real implementation, this would aggregate data from various
  /// providers and create chart renderings.
  ProgressReport generateReport({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> workoutData,
    required Map<String, dynamic> nutritionData,
    required Map<String, dynamic> wellnessData,
  }) {
    _status = ExportStatus.generating;

    final dateRange =
        '${_formatDate(startDate)} – ${_formatDate(endDate)}';

    final summary = _buildSummary(workoutData, nutritionData, wellnessData);
    final charts = _buildCharts(workoutData, nutritionData, wellnessData);
    final recommendations =
        _buildRecommendations(workoutData, nutritionData, wellnessData);

    _lastReport = ProgressReport(
      title: title,
      dateRange: dateRange,
      summary: summary,
      charts: charts,
      recommendations: recommendations,
    );

    _status = ExportStatus.ready;
    return _lastReport!;
  }

  /// Stub: exports to a file path. Returns the path on success.
  ///
  /// A real implementation would render the [ProgressReport] to PDF bytes
  /// and write to the file system.
  String? exportToFile(String filePath) {
    if (_lastReport == null) return null;
    _status = ExportStatus.ready;
    // Stub: in production, use pdf/render packages.
    return filePath;
  }

  /// Stub: shares the report. Returns true on success.
  ///
  /// A real implementation would use share_plus or platform channels.
  bool shareReport() {
    if (_lastReport == null) return false;
    // Stub: in production, invoke share intent.
    return true;
  }

  /// Resets the exporter state.
  void reset() {
    _status = ExportStatus.idle;
    _lastReport = null;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers (stub implementations)
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _buildSummary(
    Map<String, dynamic> workouts,
    Map<String, dynamic> nutrition,
    Map<String, dynamic> wellness,
  ) {
    final workoutCount = workouts['totalWorkouts'] ?? 0;
    final totalVolume = workouts['totalVolumeKg'] ?? 0;
    return 'This period included $workoutCount workouts with '
        '${totalVolume}kg total volume. Nutrition and wellness '
        'metrics are included in the charts below.';
  }

  List<ReportChart> _buildCharts(
    Map<String, dynamic> workouts,
    Map<String, dynamic> nutrition,
    Map<String, dynamic> wellness,
  ) {
    return [
      const ReportChart(
        title: 'Training Volume',
        description: 'Weekly volume progression over the period.',
        chartType: 'volume',
      ),
      const ReportChart(
        title: 'Body Composition',
        description: 'Weight, body fat %, and lean mass trends.',
        chartType: 'body_comp',
      ),
      const ReportChart(
        title: 'Strength Progress',
        description: 'Key lift progressions.',
        chartType: 'strength',
      ),
      const ReportChart(
        title: 'Nutrition Adherence',
        description: 'Calorie and macro target adherence.',
        chartType: 'nutrition',
      ),
    ];
  }

  List<ReportRecommendation> _buildRecommendations(
    Map<String, dynamic> workouts,
    Map<String, dynamic> nutrition,
    Map<String, dynamic> wellness,
  ) {
    return [
      const ReportRecommendation(
        title: 'Increase training frequency',
        detail:
            'Aim for 4–5 sessions per week to maximize volume progression.',
        priority: 'high',
      ),
      const ReportRecommendation(
        title: 'Improve protein consistency',
        detail:
            'Hit your protein target on at least 6 of 7 days per week.',
        priority: 'medium',
      ),
      const ReportRecommendation(
        title: 'Monitor recovery',
        detail:
            'Track sleep quality and readiness scores to prevent overtraining.',
        priority: 'low',
      ),
    ];
  }
}
