import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

class TransformFitBrandMark extends StatelessWidget {
  const TransformFitBrandMark({
    super.key,
    this.width = 190,
    this.semanticsLabel = defaultSemanticsLabel,
  });

  static const assetPath = 'assets/brand/transformfitai-logo-original.jpg';
  static const defaultSemanticsLabel = 'TransformFitAI brand mark';

  final double width;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        child: Image.asset(assetPath, width: width, fit: BoxFit.contain),
      ),
    );
  }
}
