import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Progress photo screen — camera/gallery integration, before/after
/// comparison slider, monthly grid, and side-by-side view.
///
/// Route: /progress-photos
///
/// Note: Camera/gallery integration requires the `image_picker` package.
/// This implementation uses placeholder data for the photo grid.
/// Add `image_picker` to pubspec.yaml and uncomment the camera/gallery
/// integration when ready for production.
class ProgressPhotoScreen extends StatefulWidget {
  const ProgressPhotoScreen({super.key});

  @override
  State<ProgressPhotoScreen> createState() => _ProgressPhotoScreenState();
}

class _ProgressPhotoScreenState extends State<ProgressPhotoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Demo data — in production, load from persistence / image_picker.
  final List<_ProgressPhoto> _photos = _demoPhotos;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        title: Text('Progress Photos', style: t.textTheme.h2),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: t.accentPrimary,
          labelColor: t.textPrimary,
          unselectedLabelColor: t.textMuted,
          tabs: const [
            Tab(text: 'Gallery'),
            Tab(text: 'Compare'),
            Tab(text: 'Timeline'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt, color: t.accentPrimary),
            onPressed: _showCameraPlaceholder,
            tooltip: 'Take Photo',
          ),
          IconButton(
            icon: Icon(Icons.photo_library, color: t.accentSecondary),
            onPressed: _showGalleryPlaceholder,
            tooltip: 'Choose from Gallery',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GalleryTab(photos: _photos),
          _CompareTab(photos: _photos),
          _TimelineTab(photos: _photos),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPhotoSheet,
        backgroundColor: t.accentPrimary,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  void _showCameraPlaceholder() {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Camera integration — add image_picker to pubspec.yaml',
          style: t.textTheme.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: t.surface,
      ),
    );
  }

  void _showGalleryPlaceholder() {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gallery integration — add image_picker to pubspec.yaml',
          style: t.textTheme.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: t.surface,
      ),
    );
  }

  void _showAddPhotoSheet() {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(t.spaceXl),
        decoration: t.modalDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Progress Photo', style: t.textTheme.h3),
            SizedBox(height: t.spaceLg),
            ListTile(
              leading: Icon(Icons.camera_alt, color: t.accentPrimary),
              title: Text('Take Photo', style: t.textTheme.body),
              subtitle: Text(
                'Requires image_picker package',
                style: t.textTheme.caption,
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: t.accentSecondary),
              title: Text('Choose from Gallery', style: t.textTheme.body),
              subtitle: Text(
                'Requires image_picker package',
                style: t.textTheme.caption,
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gallery Tab — monthly grid
// ---------------------------------------------------------------------------

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({required this.photos});
  final List<_ProgressPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    if (photos.isEmpty) {
      return _EmptyState(
        icon: Icons.photo_camera_outlined,
        message: 'No photos yet.\nTap + to add your first progress photo!',
      );
    }

    // Group by month
    final grouped = <String, List<_ProgressPhoto>>{};
    for (final photo in photos) {
      final key =
          '${photo.date.year}-${photo.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(photo);
    }

    return ListView.builder(
      padding: EdgeInsets.all(t.spaceLg),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: t.spaceSm),
              child: Text(
                _formatMonth(entry.key),
                style: t.textTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, i) {
                return _PhotoThumbnail(photo: entry.value[i]);
              },
            ),
            SizedBox(height: t.spaceMd),
          ],
        );
      },
    );
  }

  String _formatMonth(String key) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final parts = key.split('-');
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }
}

// ---------------------------------------------------------------------------
// Compare Tab — before/after slider
// ---------------------------------------------------------------------------

class _CompareTab extends StatefulWidget {
  const _CompareTab({required this.photos});
  final List<_ProgressPhoto> photos;

  @override
  State<_CompareTab> createState() => _CompareTabState();
}

class _CompareTabState extends State<_CompareTab> {
  _ProgressPhoto? _before;
  _ProgressPhoto? _after;
  double _sliderPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    if (widget.photos.length < 2) {
      return _EmptyState(
        icon: Icons.compare,
        message: 'Add at least 2 photos\nto start comparing.',
      );
    }

    return Column(
      children: [
        // Photo selectors
        Padding(
          padding: EdgeInsets.all(t.spaceLg),
          child: Row(
            children: [
              Expanded(
                child: _PhotoSelector(
                  label: 'Before',
                  photo: _before,
                  onTap: () => _selectPhoto(isBefore: true),
                  accentColor: t.accentPrimary,
                ),
              ),
              SizedBox(width: t.spaceMd),
              Expanded(
                child: _PhotoSelector(
                  label: 'After',
                  photo: _after,
                  onTap: () => _selectPhoto(isBefore: false),
                  accentColor: t.accentSecondary,
                ),
              ),
            ],
          ),
        ),

        // Comparison slider
        if (_before != null && _after != null)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
              child: _ComparisonSlider(
                beforePhoto: _before!,
                afterPhoto: _after!,
                sliderPosition: _sliderPosition,
                onChanged: (v) => setState(() => _sliderPosition = v),
              ),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text(
                'Select before & after photos',
                style: t.textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }

  void _selectPhoto({required bool isBefore}) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(t.spaceXl),
        decoration: t.modalDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBefore ? 'Select Before Photo' : 'Select After Photo',
              style: t.textTheme.h3,
            ),
            SizedBox(height: t.spaceMd),
            ...widget.photos.map(
              (p) => ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(t.radiusSm),
                  ),
                  child: Icon(p.icon, color: p.color, size: 24),
                ),
                title: Text(p.label, style: t.textTheme.body),
                subtitle: Text(
                  '${p.date.month}/${p.date.day}/${p.date.year}',
                  style: t.textTheme.caption,
                ),
                onTap: () {
                  setState(() {
                    if (isBefore) {
                      _before = p;
                    } else {
                      _after = p;
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Tab — chronological view
// ---------------------------------------------------------------------------

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.photos});
  final List<_ProgressPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    if (photos.isEmpty) {
      return _EmptyState(
        icon: Icons.timeline,
        message: 'Your progress timeline\nwill appear here.',
      );
    }

    final sorted = List<_ProgressPhoto>.from(photos)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: EdgeInsets.all(t.spaceLg),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final photo = sorted[index];
        return Padding(
          padding: EdgeInsets.only(bottom: t.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 ? t.accentPrimary : t.surfaceBorder,
                    ),
                  ),
                  if (index < sorted.length - 1)
                    Container(
                      width: 2,
                      height: 80,
                      color: t.surfaceBorder,
                    ),
                ],
              ),
              SizedBox(width: t.spaceMd),
              // Photo card
              Expanded(
                child: Container(
                  decoration: t.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder photo area
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: photo.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(t.radiusMd),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(photo.icon, color: photo.color, size: 48),
                              SizedBox(height: t.spaceXs),
                              Text(
                                photo.angle,
                                style: t.textTheme.caption.copyWith(
                                  color: photo.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(t.spaceSm),
                        child: Row(
                          children: [
                            Text(
                              photo.label,
                              style: t.textTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(photo.date),
                              style: t.textTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo});
  final _ProgressPhoto photo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return Container(
      decoration: BoxDecoration(
        color: photo.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(t.radiusSm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(photo.icon, color: photo.color, size: 28),
          SizedBox(height: t.spaceXs),
          Text(
            photo.angle,
            style: t.textTheme.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _PhotoSelector extends StatelessWidget {
  const _PhotoSelector({
    required this.label,
    required this.photo,
    required this.onTap,
    required this.accentColor,
  });

  final String label;
  final _ProgressPhoto? photo;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: t.cardDecoration,
        child: photo != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(photo!.icon, color: photo!.color, size: 32),
                  SizedBox(height: t.spaceXs),
                  Text(photo!.label, style: t.textTheme.caption),
                  Container(
                    margin: EdgeInsets.only(top: t.spaceXs),
                    padding: EdgeInsets.symmetric(
                      horizontal: t.spaceSm,
                      vertical: t.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(t.radiusPill),
                    ),
                    child: Text(
                      label,
                      style: t.textTheme.caption.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      color: t.textMuted, size: 32),
                  SizedBox(height: t.spaceXs),
                  Text(label, style: t.textTheme.caption),
                ],
              ),
      ),
    );
  }
}

class _ComparisonSlider extends StatelessWidget {
  const _ComparisonSlider({
    required this.beforePhoto,
    required this.afterPhoto,
    required this.sliderPosition,
    required this.onChanged,
  });

  final _ProgressPhoto beforePhoto;
  final _ProgressPhoto afterPhoto;
  final double sliderPosition;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            onChanged((details.localPosition.dx / w).clamp(0.0, 1.0));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(t.radiusMd),
            child: Stack(
              children: [
                // After (full)
                _PhotoPlaceholder(
                  photo: afterPhoto,
                  width: w,
                  height: constraints.maxHeight,
                ),
                // Before (clipped)
                ClipRect(
                  clipper: _SliderClipper(sliderPosition),
                  child: _PhotoPlaceholder(
                    photo: beforePhoto,
                    width: w,
                    height: constraints.maxHeight,
                  ),
                ),
                // Divider line
                Positioned(
                  left: w * sliderPosition - 1.5,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3, color: Colors.white),
                ),
                // Handle
                Positioned(
                  left: w * sliderPosition - 16,
                  top: constraints.maxHeight / 2 - 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
                // Labels
                Positioned(
                  left: 8,
                  top: 8,
                  child: _ComparisonLabel(text: 'Before'),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _ComparisonLabel(text: 'After'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    required this.photo,
    required this.width,
    required this.height,
  });

  final _ProgressPhoto photo;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return Container(
      width: width,
      height: height,
      color: photo.color.withValues(alpha: 0.12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(photo.icon, color: photo.color, size: 64),
            SizedBox(height: t.spaceSm),
            Text(
              photo.label,
              style: t.textTheme.h3.copyWith(color: photo.color),
            ),
            SizedBox(height: t.spaceXs),
            Text(
              photo.angle,
              style: t.textTheme.caption.copyWith(color: photo.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonLabel extends StatelessWidget {
  const _ComparisonLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  const _SliderClipper(this.position);
  final double position;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(_SliderClipper old) => position != old.position;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: t.textMuted),
          SizedBox(height: t.spaceLg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: t.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model — uses placeholders until image_picker is wired up
// ---------------------------------------------------------------------------

class _ProgressPhoto {
  const _ProgressPhoto({
    required this.label,
    required this.angle,
    required this.date,
    required this.icon,
    required this.color,
  });

  final String label;
  final String angle;
  final DateTime date;
  final IconData icon;
  final Color color;
}

/// Demo photos — placeholder data for the photo grid.
/// Replace with real image paths once image_picker is integrated.
final List<_ProgressPhoto> _demoPhotos = [
  _ProgressPhoto(
    label: 'Week 1',
    angle: 'Front',
    date: DateTime(2026, 6, 1),
    icon: Icons.person,
    color: const Color(0xFFF97316),
  ),
  _ProgressPhoto(
    label: 'Week 1',
    angle: 'Side',
    date: DateTime(2026, 6, 1),
    icon: Icons.accessibility_new,
    color: const Color(0xFFF59E0B),
  ),
  _ProgressPhoto(
    label: 'Week 2',
    angle: 'Front',
    date: DateTime(2026, 6, 8),
    icon: Icons.person,
    color: const Color(0xFF8B5CF6),
  ),
  _ProgressPhoto(
    label: 'Week 2',
    angle: 'Side',
    date: DateTime(2026, 6, 8),
    icon: Icons.accessibility_new,
    color: const Color(0xFF6366F1),
  ),
  _ProgressPhoto(
    label: 'Week 3',
    angle: 'Front',
    date: DateTime(2026, 6, 15),
    icon: Icons.person,
    color: const Color(0xFF10B981),
  ),
  _ProgressPhoto(
    label: 'Week 4',
    angle: 'Front',
    date: DateTime(2026, 6, 22),
    icon: Icons.person,
    color: const Color(0xFF3B82F6),
  ),
];
