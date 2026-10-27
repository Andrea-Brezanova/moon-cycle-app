import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_root.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pinned_actions_scroll.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../privacy/data/local_data_wiper.dart';
import 'widgets/export_action.dart';

/// Settings › Delete my data (`33-settings-delete-my-data`), over the tab
/// bar. Deleting removes everything on the phone and starts the app again
/// at onboarding.
class DeleteDataPage extends ConsumerStatefulWidget {
  const DeleteDataPage({super.key});

  @override
  ConsumerState<DeleteDataPage> createState() => _DeleteDataPageState();
}

class _DeleteDataPageState extends ConsumerState<DeleteDataPage> {
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    // Read both before the restart replaces this page's providers.
    final wiper = ref.read(localDataWiperProvider);
    final restart = ref.read(appRestartProvider);
    await restart(wiper.wipe);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SubScreenHeader(backLabel: 'My App', onBack: () => context.pop()),
            Expanded(
              child: PinnedActionsScroll(
                padding: EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  18,
                  MoonSpace.gutter,
                  // The design's 40 pt padding, above the 40 pt bottom
                  // margin onboarding uses (clear of the home indicator).
                  40 +
                      math.max(
                        40,
                        MediaQuery.viewPaddingOf(context).bottom + 6,
                      ),
                ),
                minGap: 18,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Overline('Delete my data'),
                    const SizedBox(height: 18),
                    Semantics(
                      header: true,
                      child: EditorialHeading(
                        'Delete your data *for good?*',
                        style: fraunces(36, height: 1.08),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'This permanently deletes your cycle history, food '
                      'preferences, shopping list, diary entries, activities, '
                      'personal Notes and saved links from this phone. It can’t be undone.',
                      style: dmSans(16, height: 1.55, color: c.text),
                    ),
                    const SizedBox(height: 18),
                    Builder(
                      builder: (context) => TextLink(
                        'Export my data first',
                        weight: FontWeight.w600,
                        onTap: _deleting
                            ? null
                            : () => exportMyData(context, ref),
                      ),
                    ),
                  ],
                ),
                actions: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MoonButton(
                      'Delete my data',
                      variant: MoonButtonVariant.destructive,
                      onPressed: _deleting ? null : _delete,
                    ),
                    const SizedBox(height: 14),
                    // The design's link sits in a 22 pt line box.
                    SizedBox(
                      height: 22,
                      child: Center(
                        child: TextLink(
                          'Cancel',
                          weight: FontWeight.w600,
                          onTap: _deleting ? null : () => context.pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
