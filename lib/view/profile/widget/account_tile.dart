import 'package:flutter/material.dart';

import 'package:sneakers_app/theme/app_theme.dart';

/// A row in the account list.
///
/// Replaces three near-identical hand-built `RoundedLisTile` variants that had
/// drifted apart, and — unlike them — has a disabled state. A signed-out user
/// should see that Orders exists and is unavailable, not have it silently do
/// nothing when tapped.
class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive
        ? context.colors.error
        : enabled
            ? context.colors.onSurface
            : context.colors.onSurfaceVariant;

    return ListTile(
      // A tile with no destination is inert on purpose while the feature is
      // unbuilt; the chevron is hidden so it does not promise navigation.
      onTap: enabled ? onTap : null,
      enabled: enabled,
      leading: Icon(icon, size: 21, color: fg),
      title: Text(title, style: context.text.titleSmall?.copyWith(color: fg)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
      trailing: onTap != null && enabled
          ? Icon(Icons.chevron_right,
              size: 20, color: context.colors.onSurfaceVariant)
          : null,
    );
  }
}
