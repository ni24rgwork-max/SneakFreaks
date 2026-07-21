import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/locker/widgets/sneaker_card.dart';

/// Card close-up: the card at size, plus add/remove from the collection.
void showCardDetailSheet(BuildContext context, BinderSlot slot) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _CardDetail(slot: slot),
  );
}

class _CardDetail extends ConsumerWidget {
  const _CardDetail({required this.slot});

  final BinderSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read live rather than from the captured slot, so the sheet updates the
    // moment the collection changes underneath it.
    final owned = ref.watch(ownedPairsProvider).contains(slot.product.id);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 18,
            children: [
              Center(
                child: SizedBox(
                  width: 260,
                  child: SneakerCard(
                    product: slot.product,
                    meta: slot.meta,
                    owned: true,
                    width: 260,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(slot.product.model,
                            style: context.text.titleMedium),
                        Text(
                          '${slot.meta.rarity.label} · ${slot.meta.type.label} · ${slot.meta.setLabel}',
                          style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: owned
                        ? OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(ownedPairsProvider.notifier)
                                  .remove(slot.product.id);
                            },
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                            label: const Text('In collection'),
                          )
                        : FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              ref
                                  .read(ownedPairsProvider.notifier)
                                  .add(slot.product.id);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('I own this'),
                          ),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(Routes.productPath(slot.product.id));
                      },
                      child: const Text('View product'),
                    ),
                  ),
                ],
              ),
              Text(
                'Adding a pair you already own is fine — the Locker is your '
                'collection, not a purchase history.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
