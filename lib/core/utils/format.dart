import 'package:intl/intl.dart';

class Format {
  Format._();

  static String compactNumber(num n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static String money(num usd) {
    if (usd >= 1000000000) return '\$${(usd / 1000000000).toStringAsFixed(1)}B';
    if (usd >= 1000000) return '\$${(usd / 1000000).toStringAsFixed(0)}M';
    if (usd >= 1000) return '\$${(usd / 1000).toStringAsFixed(0)}K';
    return '\$$usd';
  }

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  static String absoluteDate(DateTime dt) {
    return DateFormat('MMM d, y').format(dt);
  }
}

/// Compact mono-friendly forms used in kickers: 12M, 3H, 2D, 5W.
extension FormatShort on Format {
  static String short(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    if (d.inDays < 60) return '${(d.inDays / 7).floor()}w';
    return '${(d.inDays / 30).floor()}mo';
  }

  static String until(DateTime dt) {
    final d = dt.difference(DateTime.now());
    if (d.isNegative || d.inMinutes < 1) return 'any minute';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    return '${d.inHours} h ${d.inMinutes % 60} min';
  }
}
