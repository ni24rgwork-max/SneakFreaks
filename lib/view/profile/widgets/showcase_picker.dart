import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';

/// Lets the user choose what leads their profile.
Future<void> showShowcasePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ShowcasePicker(),
  );
}

class _ShowcasePicker extends ConsumerWidget {
  const _ShowcasePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(profileShowcaseProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text('Showcase', style: context.text.headlineSmall),
            Text(
              'What sits at the top of your profile.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final option in ProfileShowcase.values)
              _Option(
                option: option,
                selected: option == current,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(profileShowcaseProvider.notifier).select(option);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ProfileShowcase option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? context.colors.surfaceContainerHigh
            : context.colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.brand.cardRadius),
          side: BorderSide(
            color: selected ? context.colors.onSurface : context.brand.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(option.label, style: context.text.titleSmall),
                      Text(
                        option.blurb,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected
                      ? context.colors.onSurface
                      : context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
