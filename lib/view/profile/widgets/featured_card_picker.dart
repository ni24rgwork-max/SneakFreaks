import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/locker/widgets/scaled_sneaker_card.dart';

/// Choose which single card goes on the profile.
Future<void> showFeaturedCardPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _FeaturedCardPicker(),
  );
}

class _FeaturedCardPicker extends ConsumerWidget {
  const _FeaturedCardPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(lockerProvider);
    final chosenId = ref.watch(featuredCardIdProvider);
    final shown = ref.watch(featuredCardProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text('Your card', style: context.text.headlineSmall),
                Text(
                  chosenId == null
                      ? 'No pick yet — your rarest card is standing in.'
                      : 'The one card on your profile.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 268,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              physics: const BouncingScrollPhysics(),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final card = cards[i];
                final isShown = card.product.id == shown?.product.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(featuredCardIdProvider.notifier)
                        .select(card.product.id);
                    Navigator.of(context).pop();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Opacity(
                          // Unpicked cards recede rather than disappear — you
                          // are choosing between them, so you need to see them.
                          opacity: isShown ? 1 : 0.55,
                          child: ScaledSneakerCard(
                            product: card.product,
                            meta: card.meta,
                          ),
                        ),
                      ),
                      Icon(
                        isShown ? Icons.check_circle : Icons.circle_outlined,
                        size: 18,
                        color: isShown
                            ? context.colors.onSurface
                            : context.colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (chosenId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: OutlinedButton(
                onPressed: () {
                  ref.read(featuredCardIdProvider.notifier).clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Use my rarest instead'),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
