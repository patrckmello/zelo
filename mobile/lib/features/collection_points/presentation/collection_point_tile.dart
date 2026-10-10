import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../domain/collection_point.dart';
import 'collection_point_presentation.dart';

class CollectionPointTile extends StatelessWidget {
  const CollectionPointTile({
    required this.point,
    required this.onTap,
    super.key,
  });

  final CollectionPoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final distance = point.distanceMeters;

    return Card(
      child: InkWell(
        key: ValueKey('collection-point-${point.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ZeloSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      point.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (distance != null) ...[
                    const SizedBox(width: ZeloSpace.sm),
                    Text(
                      formatDistance(distance),
                      style: textTheme.labelMedium?.copyWith(
                        color: ZeloColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: ZeloSpace.xxs),
              Text(
                [
                  point.address,
                  point.locality,
                ].where((part) => part.isNotEmpty).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: ZeloSpace.sm),
              CollectionPointOriginBadge(point: point),
            ],
          ),
        ),
      ),
    );
  }
}
