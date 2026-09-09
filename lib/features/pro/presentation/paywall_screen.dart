import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/doodle_figure.dart';
import '../../../services/pro.dart';

/// The Pro paywall. Plain language about what the money pays for, one
/// primary action, packages straight from RevenueCat offerings so pricing
/// is never hard-coded here.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _selected;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final pro = ref.watch(proProvider);
    final t = Theme.of(context).textTheme;
    final packages = pro.offerings?.current?.availablePackages ?? const <Package>[];
    _selected ??= packages.isEmpty ? null : (packages.firstWhere((p) => p.packageType == PackageType.annual, orElse: () => packages.first));

    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
              children: [
                const Center(child: DoodleFigure(Figure.unboxing, hue: AppColors.yellow, height: 170, semanticLabel: 'Person opening a box')),
                const SizedBox(height: AppSpacing.md),
                Text('TechiNews Pro', style: AppTypography.kicker(color: AppColors.accent)),
                const SizedBox(height: AppSpacing.sm),
                Text('The alerts, not\njust the feed.', style: t.displayMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Reading stays free. Pro pays for the collector that runs every hour and the pushes that go out the minute a story matters.',
                  style: t.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                _line('01', 'Instant alerts', 'A push when a story scores 85 or higher. Usually two or three a day.'),
                _line('02', 'Topic alerts', 'Follow a company, a repo, or a keyword. Get pinged only for that.'),
                _line('03', 'Unlimited saves', 'The free tier keeps ten. Pro keeps all of them, offline.'),
                const SizedBox(height: AppSpacing.xl),
                if (pro.status == ProStatus.unavailable)
                  Text(
                    'Purchases are not available in this build. On Android and iOS this screen lists live prices from RevenueCat.',
                    style: t.bodyMedium?.copyWith(color: AppColors.warning),
                  )
                else if (pro.isPro)
                  Text('You are on Pro. Thank you.', style: t.titleMedium)
                else if (packages.isEmpty)
                  Text('Loading prices…', style: t.bodyMedium)
                else
                  for (final p in packages) _PackageRow(p, selected: p == _selected, onTap: () => setState(() => _selected = p)),
                if (pro.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(pro.error!, style: t.bodySmall?.copyWith(color: AppColors.danger)),
                ],
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: (!pro.canPurchase || _selected == null || _busy) ? null : () async {
                        setState(() => _busy = true);
                        final ok = await ref.read(proProvider.notifier).purchase(_selected!);
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        if (ok) context.pop();
                      },
                      child: Text(_selected == null ? 'Continue' : 'Continue with ${_selected!.storeProduct.priceString}'),
                    ),
                    TextButton(
                      onPressed: pro.status == ProStatus.unavailable ? null : () => ref.read(proProvider.notifier).restore(),
                      child: const Text('Restore purchases'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String n, String title, String body) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: Text(n, style: AppTypography.mono(12, color: AppColors.accent))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title, style: t.titleMedium), const SizedBox(height: 3), Text(body, style: t.bodyMedium)],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  final Package package;
  final bool selected;
  final VoidCallback onTap;
  const _PackageRow(this.package, {required this.selected, required this.onTap});

  String get _period => switch (package.packageType) {
        PackageType.annual => 'per year',
        PackageType.monthly => 'per month',
        PackageType.weekly => 'per week',
        PackageType.lifetime => 'once',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final trial = package.storeProduct.introductoryPrice;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: selected ? AppColors.accent : AppColors.hairline, width: selected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.storeProduct.title.split(' (').first, style: t.titleMedium),
                  if (trial != null) Text('${trial.periodNumberOfUnits} ${trial.periodUnit.name.toLowerCase()} free, then', style: t.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(package.storeProduct.priceString, style: AppTypography.mono(15, weight: FontWeight.w600, color: AppColors.ink)),
                Text(_period, style: AppTypography.kicker()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
