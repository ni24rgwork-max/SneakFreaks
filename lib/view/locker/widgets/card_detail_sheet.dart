import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/locker/widgets/sneaker_card.dart';

/// Card close-up: the card at size, plus add/remove from the collection.
void showCardDetailSheet(BuildContext context, LockerCard slot) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _CardDetail(slot: slot),
  );
}

class _CardDetail extends ConsumerWidget {
  const _CardDetail({required this.slot});

  final LockerCard slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Builder(builder: (context) {
                final featured = ref.watch(featuredCardIdProvider);
                final isFeatured = featured == slot.product.id;
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // Deliberately not a toggle-off: the profile always shows
                    // some card, so un-featuring has no meaning. Feature a
                    // different one instead.
                    onPressed: isFeatured
                        ? null
                        : () {
                            ref
                                .read(featuredCardIdProvider.notifier)
                                .select(slot.product.id);
                            Navigator.pop(context);
                          },
                    icon: Icon(isFeatured ? Icons.check : Icons.person_outline),
                    label: Text(
                      isFeatured ? 'On your profile' : 'Put on my profile',
                    ),
                  ),
                );
              }),
              SizedBox(
                width: double.infinity,
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
        ),
      ),
    );
  }
}
