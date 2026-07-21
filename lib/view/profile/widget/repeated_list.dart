import 'package:flutter/material.dart';

import 'package:sneakers_app/theme/app_theme.dart';

class RoundedLisTile extends StatelessWidget {
  const RoundedLisTile({
    super.key,
    required this.leadingBackColor,
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  final Color? leadingBackColor;
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: leadingBackColor ?? context.colors.surfaceContainerHigh,
        radius: 24,
        child: Icon(icon, color: context.colors.onPrimary),
      ),
      title: Text(title, style: context.text.titleMedium),
      trailing: trailing,
    );
  }
}
