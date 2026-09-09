import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Open Doodles figure (CC0, Pablo Stanley), recoloured at load time so the
/// same asset can wear any poster hue. Ink lines are white; `hue` replaces
/// the packed accent colour. Names match files in assets/illustrations.
enum Figure {
  sittingReading('doodle-sitting-reading'),
  clumsy('doodle-clumsy'),
  meditating('doodle-meditating'),
  coffee('doodle-coffee'),
  float('doodle-float'),
  selfie('doodle-selfie'),
  unboxing('doodle-unboxing'),
  reading('doodle-reading'),
  levitate('doodle-levitate');

  final String file;
  const Figure(this.file);
}

class DoodleFigure extends StatelessWidget {
  final Figure figure;
  final Color hue;
  final double height;
  final String? semanticLabel;
  const DoodleFigure(this.figure, {super.key, this.hue = AppColors.accent, this.height = 160, this.semanticLabel});

  static const _packedAccent = '#2495FF';
  static final _cache = <String, String>{};

  Future<String> _load() async {
    final key = '${figure.file}:${hue.toARGB32()}';
    final hit = _cache[key];
    if (hit != null) return hit;
    final raw = await rootBundle.loadString('assets/illustrations/${figure.file}.svg');
    final hex = '#${hue.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final out = raw.replaceAll(_packedAccent, hex);
    _cache[key] = out;
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FutureBuilder<String>(
        future: _load(),
        builder: (_, snap) => snap.hasData
            ? SvgPicture.string(snap.data!, height: height, fit: BoxFit.contain, semanticsLabel: semanticLabel)
            : const SizedBox.shrink(),
      ),
    );
  }
}
