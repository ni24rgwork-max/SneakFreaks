import 'package:flutter/material.dart';

import 'package:sneakers_app/theme/app_theme.dart';

/// Stock, returns and authenticity signals.
///
/// Placed directly under the price because in Indian e-commerce these are
/// decision inputs, not fine print — a shopper checks returns before size.
class TrustRow extends StatelessWidget {
  const TrustRow({super.key, required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _Item(
            icon: inStock ? Icons.check_circle : Icons.remove_circle_outline,
            label: inStock ? 'In stock' : 'Sold out',
            color: inStock ? context.brand.success : context.colors.error,
          ),
          const _Item(icon: Icons.autorenew, label: '14-day exchange'),
          const _Item(icon: Icons.verified_outlined, label: '100% authentic'),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(icon, size: 15, color: c),
        Text(label, style: context.text.bodySmall?.copyWith(color: c)),
      ],
    );
  }
}
