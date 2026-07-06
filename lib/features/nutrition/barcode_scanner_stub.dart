/// M5: Barcode scanner integration model.
///
/// Stub implementation for barcode scanning with mock data.
/// Ready for real scanner integration (e.g., flutter_barcode_scanner).
/// Pure Dart, deterministic.
library;

import 'package:transformfit/features/nutrition/macro_model.dart';

// ── Barcode Result ───────────────────────────────────────────────────────

/// Result of a barcode scan/lookup.
class BarcodeResult {
  const BarcodeResult({
    required this.barcode,
    required this.productName,
    required this.macros,
    required this.source,
    this.brand,
    this.servingSize,
    this.servingUnit,
    this.imageUrl,
  });

  /// The scanned barcode string.
  final String barcode;

  /// Product name from the database.
  final String productName;

  /// Macros per serving.
  final Macros macros;

  /// Data source (e.g., 'openfoodfacts', 'manual', 'stub').
  final String source;

  /// Brand name (optional).
  final String? brand;

  /// Serving size used for the macro calculation.
  final double? servingSize;

  /// Serving unit (e.g., 'g', 'ml', 'piece').
  final String? servingUnit;

  /// Product image URL (optional).
  final String? imageUrl;

  Map<String, Object?> toJson() => {
        'barcode': barcode,
        'productName': productName,
        'macros': macros.toJson(),
        'source': source,
        'brand': brand,
        'servingSize': servingSize,
        'servingUnit': servingUnit,
        'imageUrl': imageUrl,
      };

  factory BarcodeResult.fromJson(Map<String, Object?> json) => BarcodeResult(
        barcode: json['barcode'] as String,
        productName: json['productName'] as String,
        macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
        source: json['source'] as String,
        brand: json['brand'] as String?,
        servingSize: (json['servingSize'] as num?)?.toDouble(),
        servingUnit: json['servingUnit'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );

  @override
  String toString() => 'BarcodeResult($barcode, $productName, ${macros.calories.toStringAsFixed(0)}kcal)';
}

// ── Scan Status ──────────────────────────────────────────────────────────

/// Status of a barcode scan operation.
enum ScanStatus {
  /// Scan completed successfully.
  success,

  /// Product not found in database.
  notFound,

  /// Camera/scanner permission denied.
  permissionDenied,

  /// Network error during lookup.
  networkError,

  /// Invalid barcode format.
  invalidBarcode;

  String get message => switch (this) {
        ScanStatus.success => 'Product found',
        ScanStatus.notFound => 'Product not in database. Try entering manually.',
        ScanStatus.permissionDenied => 'Camera permission required for scanning.',
        ScanStatus.networkError => 'Network error. Check your connection.',
        ScanStatus.invalidBarcode => 'Invalid barcode. Try scanning again.',
      };
}

// ── Scan Result ──────────────────────────────────────────────────────────

/// Complete result of a scan operation including status.
class ScanResult {
  const ScanResult({
    required this.status,
    this.product,
    this.errorMessage,
  });

  final ScanStatus status;
  final BarcodeResult? product;
  final String? errorMessage;

  bool get isSuccess => status == ScanStatus.success && product != null;

  factory ScanResult.success(BarcodeResult product) =>
      ScanResult(status: ScanStatus.success, product: product);

  factory ScanResult.notFound(String barcode) => ScanResult(
        status: ScanStatus.notFound,
        errorMessage: 'Barcode $barcode not found',
      );

  factory ScanResult.error(ScanStatus status, String message) =>
      ScanResult(status: status, errorMessage: message);
}

// ── Barcode Scanner ─────────────────────────────────────────────────────

/// Barcode scanner with stub implementation.
///
/// Current implementation returns mock data for development/testing.
/// Replace [_mockProducts] with real API calls for production.
class BarcodeScanner {
  const BarcodeScanner();

  /// Simulate a barcode scan. Returns a [ScanResult].
  ///
  /// In production, this would open the camera and use ML Kit or similar.
  /// For now, returns mock data if the barcode is in the stub database.
  Future<ScanResult> scan() async {
    // Simulate scanning delay
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Return a random mock product
    final mock = _mockProducts.values.first;
    return ScanResult.success(mock);
  }

  /// Look up a product by barcode string.
  ///
  /// Returns [ScanResult] with the product if found, or a not-found status.
  Future<ScanResult> lookup(String barcode) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final product = _mockProducts[barcode];
    if (product != null) {
      return ScanResult.success(product);
    }
    return ScanResult.notFound(barcode);
  }

  /// Add a scanned product to the daily nutrition log.
  ///
  /// Returns the [BarcodeResult] that was added, or null if the lookup failed.
  Future<BarcodeResult?> addToLog(String barcode) async {
    final result = await lookup(barcode);
    if (result.isSuccess) {
      // In production, this would call the nutrition logger provider
      return result.product;
    }
    return null;
  }

  /// Manual barcode entry (for when scanning fails).
  Future<ScanResult> manualEntry(String barcode) async {
    return lookup(barcode);
  }

  // ── Mock Data ──────────────────────────────────────────────────────

  /// Mock product database for stub implementation.
  static const Map<String, BarcodeResult> _mockProducts = {
    '5000159484695': BarcodeResult(
      barcode: '5000159484695',
      productName: 'Protein Bar (Chocolate)',
      brand: 'Optimum Nutrition',
      macros: Macros(calories: 210, proteinGrams: 20, carbsGrams: 22, fatGrams: 7),
      servingSize: 60,
      servingUnit: 'g',
      source: 'stub',
    ),
    '0071928351029': BarcodeResult(
      barcode: '0071928351029',
      productName: 'Greek Yogurt (Plain)',
      brand: 'Chobani',
      macros: Macros(calories: 100, proteinGrams: 17, carbsGrams: 6, fatGrams: 0),
      servingSize: 150,
      servingUnit: 'g',
      source: 'stub',
    ),
    '0028400047685': BarcodeResult(
      barcode: '0028400047685',
      productName: 'Chicken Breast (Canned)',
      brand: 'Swanson',
      macros: Macros(calories: 150, proteinGrams: 26, carbsGrams: 0, fatGrams: 5),
      servingSize: 100,
      servingUnit: 'g',
      source: 'stub',
    ),
    '0041220576980': BarcodeResult(
      barcode: '0041220576980',
      productName: 'Whey Protein Powder',
      brand: 'Gold Standard',
      macros: Macros(calories: 120, proteinGrams: 24, carbsGrams: 3, fatGrams: 1),
      servingSize: 30,
      servingUnit: 'g',
      source: 'stub',
    ),
    '5000112637226': BarcodeResult(
      barcode: '5000112637226',
      productName: 'Peanut Butter (Smooth)',
      brand: 'Skippy',
      macros: Macros(calories: 190, proteinGrams: 7, carbsGrams: 7, fatGrams: 16),
      servingSize: 32,
      servingUnit: 'g',
      source: 'stub',
    ),
  };
}
