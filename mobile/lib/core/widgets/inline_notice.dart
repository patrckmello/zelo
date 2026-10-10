import 'package:flutter/material.dart';

import '../theme/zelo_colors.dart';
import '../theme/zelo_tokens.dart';

enum NoticeTone { neutral, positive, attention }

/// Aviso discreto em linha, para limites da versão e orientações.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = NoticeTone.neutral,
    this.title,
    super.key,
  });

  final String message;
  final IconData icon;
  final NoticeTone tone;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      NoticeTone.neutral => (ZeloColors.shelfDeep, ZeloColors.inkSoft),
      NoticeTone.positive => (ZeloColors.greenTint, ZeloColors.onGreenTint),
      NoticeTone.attention => (ZeloColors.expiringTint, ZeloColors.expiringInk),
    };
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ZeloRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ZeloSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: foreground)),
            const SizedBox(width: ZeloSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title case final title?) ...[
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: ZeloSpace.xxs),
                  ],
                  Text(
                    message,
                    style: textTheme.bodySmall?.copyWith(
                      color: foreground,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
