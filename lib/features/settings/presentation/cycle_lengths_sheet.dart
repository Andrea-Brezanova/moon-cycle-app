import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_controls.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/number_stepper.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/data/cycle_repository.dart';
import '../../cycle/domain/cycle_profile.dart';
import '../../cycle/domain/cycle_rules.dart';

/// Changes the usual cycle and period length (My Cycle › Cycle length or
/// Period length). Built from the onboarding step's steppers and copy; the
/// sheet itself isn't drawn (docs/design-deviations.md).
///
/// Once enough periods are logged, a switch chooses between the logged
/// average and the values set here.
Future<void> showCycleLengthsSheet(BuildContext context) =>
    showMoonSheet<void>(context, builder: (_) => const _CycleLengthsSheet());

class _CycleLengthsSheet extends ConsumerStatefulWidget {
  const _CycleLengthsSheet();

  @override
  ConsumerState<_CycleLengthsSheet> createState() => _CycleLengthsSheetState();
}

class _CycleLengthsSheetState extends ConsumerState<_CycleLengthsSheet> {
  CycleProfile? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final stored = ref.watch(cycleProfileProvider).value;
    final averages = ref.watch(historyAveragesProvider);
    final draft =
        _draft ??
        stored ??
        const CycleProfile(
          typicalCycleLength: CycleRules.defaultCycleLength,
          typicalPeriodLength: CycleRules.defaultPeriodLength,
        );
    final hasAverages =
        averages.cycleLength != null || averages.periodLength != null;

    void update(CycleProfile p) => setState(() => _draft = p);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Overline('Your rhythm'),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: EditorialHeading(
              'How long is your cycle, *usually?*',
              style: fraunces(32, height: 1.1),
            ),
          ),
          const SizedBox(height: 14),
          NumberStepper(
            label: 'Cycle length',
            value: draft.typicalCycleLength,
            min: CycleRules.minCycleLength,
            max: CycleRules.maxCycleLength,
            hint: 'From the first day of one period to the next.',
            onChanged: (v) => update(draft.copyWith(typicalCycleLength: v)),
          ),
          NumberStepper(
            label: 'Period length',
            value: draft.typicalPeriodLength,
            min: CycleRules.minPeriodLength,
            max: CycleRules.maxPeriodLength,
            hint: 'How many days you usually bleed.',
            onChanged: (v) => update(draft.copyWith(typicalPeriodLength: v)),
          ),
          if (hasAverages)
            MoonListRow(
              label: 'Use my logged average',
              subtitle: 'Instead of the lengths above',
              trailing: MoonToggle(
                value: draft.useHistoryAverages,
                semanticLabel: 'Use my logged average',
                onChanged: (v) => update(draft.copyWith(useHistoryAverages: v)),
              ),
            ),
          const SizedBox(height: 18),
          MoonButton(
            'Save',
            variant: MoonButtonVariant.secondary,
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await ref.read(cycleRepositoryProvider).saveProfile(draft);
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}
