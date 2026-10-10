import 'package:flutter/material.dart';

/// Símbolo oficial do Zelo, sem redesenho ou recorte.
class BrandSymbol extends StatelessWidget {
  const BrandSymbol({
    this.size = 56,
    this.semanticLabel = 'Símbolo do Zelo',
    this.decorative = false,
    super.key,
  });

  static const assetPath = 'assets/branding/zelo-symbol.png';

  final double size;
  final String semanticLabel;

  /// Quando verdadeiro, o símbolo é ignorado por leitores de tela.
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: decorative ? null : semanticLabel,
      excludeFromSemantics: decorative,
    );
  }
}
