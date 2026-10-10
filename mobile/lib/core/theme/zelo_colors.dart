import 'package:flutter/material.dart';

/// Paleta do Zelo.
///
/// As primitivas seguem o briefing mais recente da identidade (D006, ainda
/// proposta). Os tons derivados foram calculados para manter contraste WCAG
/// AA: texto ≥ 4,5:1 e bordas de controles ≥ 3:1 sobre o fundo.
abstract final class ZeloColors {
  // Primitivas da identidade.
  static const green = Color(0xFF28A87B);
  static const petroleumBlue = Color(0xFF174C5B);
  static const lightBackground = Color(0xFFF4F7F6);
  static const warningAmber = Color(0xFFF5A623);
  static const textGray = Color(0xFF687078);
  static const expiredRed = Color(0xFFB64343);

  // Superfícies: a prateleira (fundo) e o papel das embalagens (cartões).
  static const shelf = lightBackground;
  static const paper = Color(0xFFFFFFFF);
  static const shelfDeep = Color(0xFFE9EFED);
  static const hairline = Color(0xFFDDE5E3);
  static const fieldBorder = Color(0xFF7E8D90);

  // Tinta: títulos, corpo, metadados e desabilitado.
  static const ink = petroleumBlue;
  static const inkSoft = Color(0xFF3F5660);
  static const inkMuted = textGray;
  static const inkDisabled = Color(0xFFA3AEB1);
  static const inkInverse = Color(0xFF12343E);

  // Tons de apoio da marca.
  static const petroleumTint = Color(0xFFE1E8EA);
  static const onPetroleumTint = Color(0xFF0F3843);
  static const greenTint = Color(0xFFDDF1EA);
  static const onGreenTint = Color(0xFF0E4A35);

  // Validade: faixa (accent), fundo (tint) e texto sobre o fundo (ink).
  static const validTint = Color(0xFFE3F4EE);
  static const validInk = Color(0xFF1B6E52);
  static const expiringTint = Color(0xFFFDF1DC);
  static const expiringInk = Color(0xFF7A4A00);
  static const expiredTint = Color(0xFFF8ECEC);
  static const expiredInk = Color(0xFF9E3535);
}
