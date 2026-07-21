import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/palette.dart';
import 'package:sneakers_app/theme/theme_controller.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/utils/money.dart';

/// Design-system reference screen.
///
/// Renders every token in one place so the two brand directions can be
/// compared honestly — surface ramp, CTAs, commerce signals, type scale and
/// price treatments — rather than judging them from a half-migrated product
/// screen. Keep this during development; it is the fastest way to catch a
/// token that breaks in one brightness.
class TokenPreview extends ConsumerWidget {
  const TokenPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final cs = context.colors;
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(
        title: Text('${settings.palette.label} — ${settings.palette.blurb}'),
        actions: [
          IconButton(
            tooltip: 'Switch palette',
            onPressed: controller.togglePalette,
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: 'Switch brightness',
            onPressed: () => controller.setMode(
              Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: const Icon(Icons.contrast),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _section(context, 'Surface ramp'),
          _SurfaceRamp(),
          const SizedBox(height: 28),

          _section(context, 'Commerce signals'),
          Row(
            spacing: 10,
            children: [
              _Swatch(color: cs.primary, label: 'primary'),
              _Swatch(color: brand.sale, label: 'sale'),
              _Swatch(color: brand.success, label: 'success'),
              _Swatch(color: brand.interactiveBorder, label: 'border'),
            ],
          ),
          const SizedBox(height: 28),

          _section(context, 'Price treatment'),
          _PriceBlock(),
          const SizedBox(height: 28),

          _section(context, 'Actions'),
          FilledButton(onPressed: () {}, child: const Text('Add to bag')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () {}, child: const Text('Save for later')),
          const SizedBox(height: 14),
          Row(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('UK 8'),
                selected: true,
                onSelected: (_) {},
                showCheckmark: false,
                labelStyle: context.text.labelLarge
                    ?.copyWith(color: cs.onPrimary),
              ),
              FilterChip(
                label: const Text('UK 9'),
                selected: false,
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('UK 10'),
                selected: false,
                onSelected: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            decoration: InputDecoration(
              hintText: 'Delivery pincode',
              suffixIcon: TextButton(
                onPressed: () {},
                child: const Text('Check'),
              ),
            ),
          ),
          const SizedBox(height: 28),

          _section(context, 'Type scale'),
          Text('Display small', style: context.text.displaySmall),
          Text('Headline small', style: context.text.headlineSmall),
          Text('Title medium', style: context.text.titleMedium),
          Text(
            'Body medium — the quick brown fox jumps over the lazy dog. '
            '₹1,50,000 · ₹1.5L · ₹1.25Cr',
            style: context.text.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text('AIR-MAX', style: AppTypography.wordmark(size: 34)),
        ],
      ),
    );
  }

  static Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: context.text.labelSmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      );
}

class _SurfaceRamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final steps = <(String, Color)>[
      ('lowest', cs.surfaceContainerLowest),
      ('low', cs.surfaceContainerLow),
      ('base', cs.surfaceContainer),
      ('high', cs.surfaceContainerHigh),
      ('highest', cs.surfaceContainerHighest),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.brand.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final (name, color) in steps)
            Expanded(
              child: Container(
                height: 64,
                color: color,
                alignment: Alignment.center,
                child: Text(name, style: context.text.labelSmall),
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.brand.hairline),
            ),
          ),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const mrp = Money(1699500);
    const price = Money(1299500);
    final off = (((mrp.paise - price.paise) / mrp.paise) * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10,
      children: [
        Text(
          price.formatted,
          style: context.text.headlineSmall
              ?.copyWith(fontFeatures: AppTypography.tabular),
        ),
        Text(
          mrp.formatted,
          style: context.text.bodyMedium?.copyWith(
            color: context.brand.priceStrike,
            decoration: TextDecoration.lineThrough,
            fontFeatures: AppTypography.tabular,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.brand.sale,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$off% OFF',
            style: context.text.labelSmall
                ?.copyWith(color: context.brand.onSale),
          ),
        ),
        const Spacer(),
        Icon(Icons.check_circle, size: 16, color: context.brand.success),
        Text('In stock', style: context.text.labelMedium),
      ],
    );
  }
}
