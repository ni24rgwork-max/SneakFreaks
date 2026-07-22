import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/pdp_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';

/// Delivery serviceability check.
///
/// An Indian storefront staple: shoppers check whether an item reaches them
/// *before* adding to bag, not at checkout. Its absence is conspicuous.
///
/// ⚠️ The result is currently a stub — any valid 6-digit input returns a
/// plausible ETA. See pdp_provider.dart.
class PincodeCheck extends ConsumerStatefulWidget {
  const PincodeCheck({super.key});

  @override
  ConsumerState<PincodeCheck> createState() => _PincodeCheckState();
}

class _PincodeCheckState extends ConsumerState<PincodeCheck> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(pincodeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text('Delivery', style: context.text.titleMedium),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter pincode',
              counterText: '',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              suffixIcon: TextButton(
                onPressed: () =>
                    ref.read(pincodeProvider.notifier).check(_controller.text),
                child: const Text('Check'),
              ),
            ),
            onSubmitted: (v) => ref.read(pincodeProvider.notifier).check(v),
          ),
          if (result != null)
            Row(
              spacing: 7,
              children: [
                Icon(
                  result.valid
                      ? Icons.local_shipping_outlined
                      : Icons.error_outline,
                  size: 16,
                  color: result.valid
                      ? context.brand.success
                      : context.colors.error,
                ),
                Flexible(
                  child: Text(
                    result.valid
                        ? 'Delivers in ${result.days} days to ${result.pincode}'
                        : 'Enter a valid 6-digit pincode',
                    style: context.text.bodySmall?.copyWith(
                      color: result.valid
                          ? context.brand.success
                          : context.colors.error,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
