import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';

/// Trajeto do descarte, desenhado como uma linha de metrô: trechos retos
/// (horizontal, vertical e diagonal a 45°, a inclinação da cápsula do
/// símbolo), cantos com raio constante e um laço em círculo perfeito, como a
/// seta de devolução. Sai de onde a pessoa confirmou e deixa a tela em linha
/// reta.
Path disposalRoute(Size size, {Offset? origin}) {
  final w = size.width;
  final h = size.height;
  final unit = math.min(w, h * 0.55);
  final start = origin ?? Offset(w * 0.5, h * 0.86);
  final rail = w * 0.12;
  final corner = Offset(rail, start.dy);
  final bend = Offset(rail, math.min(h * 0.5, start.dy - unit * 0.45));
  const diagonal = Offset(math.sqrt1_2, -math.sqrt1_2);
  final loopAt = bend + diagonal * ((w * 0.42 - rail) / math.sqrt1_2);
  final loopRadius = unit * 0.13;

  final path = Path()..moveTo(start.dx, start.dy);
  _roundCorner(path, start, corner, bend, unit * 0.14);
  _roundCorner(path, corner, bend, loopAt, unit * 0.24);
  path.lineTo(loopAt.dx, loopAt.dy);

  // Laço: círculo tangente à diagonal, à esquerda de quem segue por ela;
  // volta ao mesmo ponto na mesma direção.
  final normal = Offset(diagonal.dy, -diagonal.dx);
  final center = loopAt + normal * loopRadius;
  final circle = Rect.fromCircle(center: center, radius: loopRadius);
  final from = (loopAt - center).direction;
  path
    ..arcTo(circle, from, -math.pi, false)
    ..arcTo(circle, from - math.pi, -math.pi, false);

  // Saída em linha reta, até passar da borda.
  const margin = 40.0;
  final leave = math.min(
    (w + margin - loopAt.dx) / diagonal.dx,
    (loopAt.dy + margin) / -diagonal.dy,
  );
  final exit = loopAt + diagonal * leave;
  return path..lineTo(exit.dx, exit.dy);
}

/// Segue reto até perto de [corner] e contorna o canto com um arco de raio
/// [radius], saindo já na direção de [next].
void _roundCorner(
  Path path,
  Offset previous,
  Offset corner,
  Offset next,
  double radius,
) {
  final incoming = _unit(corner - previous);
  final outgoing = _unit(next - corner);
  final turn = math.acos(
    (incoming.dx * outgoing.dx + incoming.dy * outgoing.dy).clamp(-1.0, 1.0),
  );
  if (turn < 0.001) {
    path.lineTo(corner.dx, corner.dy);
    return;
  }
  final cut = radius * math.tan(turn / 2);
  final before = corner - incoming * cut;
  final after = corner + outgoing * cut;
  // Na tela (y para baixo), produto vetorial positivo é curva à direita.
  final clockwise = incoming.dx * outgoing.dy - incoming.dy * outgoing.dx > 0;
  path
    ..lineTo(before.dx, before.dy)
    ..arcToPoint(after, radius: Radius.circular(radius), clockwise: clockwise);
}

Offset _unit(Offset vector) => vector / vector.distance;

/// Desenha o trajeto nas três fases da celebração.
///
/// - [draw]: o traço nasce no botão e percorre a tela (0 a 1);
/// - [sweep]: o traço engrossa e cresce até cobrir a tela, passando do verde
///   ao petróleo;
/// - [rest]: depois da varredura, o trajeto volta fino ao fundo; [head] é a
///   posição do brilho que percorre o caminho em laço.
class DisposalRoutePainter extends CustomPainter {
  DisposalRoutePainter({
    required this.draw,
    required this.sweep,
    required this.rest,
    required this.head,
    this.origin,
  });

  final double draw;
  final double sweep;
  final double rest;
  final double? head;
  final Offset? origin;

  @override
  void paint(Canvas canvas, Size size) {
    final route = disposalRoute(size, origin: origin);
    final metric = route.computeMetrics().first;

    if (rest == 0) {
      // Fases 1 e 2: traço que nasce e depois varre a tela.
      final diagonal = math.sqrt(
        size.width * size.width + size.height * size.height,
      );
      final width = lerpDouble(
        12,
        diagonal * 1.4,
        Curves.easeInCubic.transform(sweep),
      )!;
      final color = Color.lerp(
        ZeloColors.green,
        ZeloColors.petroleumBlue,
        Curves.easeIn.transform(sweep),
      )!;
      final center = size.center(Offset.zero);
      final scale = 1 + 1.4 * Curves.easeInCubic.transform(sweep);
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..scale(scale)
        ..translate(-center.dx, -center.dy)
        ..drawPath(
          metric.extractPath(0, metric.length * draw),
          _stroke(color, width / scale),
        )
        ..restore();
      return;
    }

    // Fase 3: trajeto ao fundo, atrás do "Mandou bem!".
    canvas.drawPath(
      metric.extractPath(0, metric.length * rest),
      _stroke(ZeloColors.green.withValues(alpha: 0.24), 16),
    );
    if (head case final position?) {
      final length = metric.length * 0.16;
      final end = metric.length * position;
      canvas.drawPath(
        metric.extractPath(math.max(end - length, 0), end),
        _stroke(ZeloColors.green.withValues(alpha: 0.5), 16),
      );
    }
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(DisposalRoutePainter oldDelegate) =>
      oldDelegate.draw != draw ||
      oldDelegate.sweep != sweep ||
      oldDelegate.rest != rest ||
      oldDelegate.head != head ||
      oldDelegate.origin != origin;
}
