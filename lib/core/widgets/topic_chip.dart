import 'package:flutter/material.dart';

import 'doodles.dart';

/// Hue-outlined pill tag. Kept as a thin wrapper over [HueTag] so existing
/// call sites keep working.
class TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;
  final bool hashtag;

  const TopicChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.dense = false,
    this.hashtag = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = hashtag && !label.startsWith('#') ? '#${label.replaceAll(' ', '')}' : label;
    return HueTag(text, filled: selected, onTap: onTap, dense: dense);
  }
}
