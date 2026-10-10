import 'package:flutter/widgets.dart';

/// Espaçamento em múltiplos de 4 px.
abstract final class ZeloSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;

  /// Margem lateral das telas.
  static const gutter = 20.0;

  /// Largura máxima do conteúdo em telas largas.
  static const contentMaxWidth = 640.0;
}

/// Raios: controles, cartões e folhas. Cartões somam o raio interno ao
/// próprio padding para manter cantos concêntricos.
abstract final class ZeloRadii {
  static const stamp = 6.0;
  static const control = 14.0;
  static const card = 20.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

/// Movimento curto, com desaceleração, e desativado sob redução de movimento.
abstract final class ZeloMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 240);
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
