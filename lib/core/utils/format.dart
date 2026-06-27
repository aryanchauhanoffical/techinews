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
