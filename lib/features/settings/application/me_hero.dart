import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/storage/ui_prefs.dart';

/// A MoonCycle picture offered for the top of Me.
final class BundledHero {
  const BundledHero(this.id, this.label, this.asset);

  final String id;
  final String label;
  final String asset;
}

/// The small set of pictures that ship with the app (all already in it).
const bundledHeroes = [
  BundledHero('tea', 'Tea', 'assets/images/home/home_relax_tea.jpg'),
  BundledHero('yoga', 'Yoga mat', 'assets/images/home/home_move_yoga_mat.jpg'),
  BundledHero(
    'broccoli',
    'Broccoli',
    'assets/images/home/home_eat_broccoli.jpg',
  ),
  BundledHero(
    'salad',
    'Salad',
    'assets/images/recipes/red-cabbage-apricot-chickpea-salad.jpg',
  ),
  BundledHero('diary', 'Notebook', 'assets/images/home/quick_my_diary.jpg'),
  BundledHero(
    'market',
    'Market basket',
    'assets/images/home/quick_shopping_list.jpg',
  ),
];

/// What Me shows when nothing was chosen.
const defaultHero = BundledHero(
  'tea',
  'Tea',
  'assets/images/home/home_relax_tea.jpg',
);

enum HeroPickSource { gallery, camera }

/// The photo library or camera permission was refused (or is restricted).
class HeroPermissionDenied implements Exception {
  const HeroPermissionDenied(this.source);

  final HeroPickSource source;
}

/// Gets one picture from the photo library or the camera, as JPEG bytes that
/// are already scaled down and have their orientation applied. Returns null
/// when the user cancels. The picture is never uploaded anywhere.
abstract interface class HeroImagePicker {
  Future<Uint8List?> pick(HeroPickSource source);
}

/// The system picker (`image_picker`). The photo library uses the iOS photo
/// picker, which shows only what the user selects and asks for no library
/// access; `requestFullMetadata: false` keeps it that way.
class DeviceHeroImagePicker implements HeroImagePicker {
  DeviceHeroImagePicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Longest side kept, in pixels: plenty for a full-width card, small to store.
  static const maxSide = 1600.0;

  @override
  Future<Uint8List?> pick(HeroPickSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == HeroPickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      return file == null ? null : await file.readAsBytes();
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied') ||
          e.code.contains('access_restricted')) {
        throw HeroPermissionDenied(source);
      }
      rethrow;
    }
  }
}

final heroImagePickerProvider = Provider<HeroImagePicker>(
  (ref) => DeviceHeroImagePicker(),
);

/// What the Me hero shows now, from the saved choice. A missing personal image
/// (deleted, or from before a wipe) quietly falls back to the default.
final meHeroImageProvider = Provider<ImageProvider>((ref) {
  final choice = ref.watch(uiPrefsProvider.select((p) => p.meHero));
  final store = ref.watch(uiPrefsStoreProvider);
  if (choice != null) {
    if (choice.startsWith('custom:')) {
      final custom = store.heroImage(choice.substring(7));
      if (custom != null) return custom;
    } else if (choice.startsWith('bundled:')) {
      for (final h in bundledHeroes) {
        if (h.id == choice.substring(8)) return AssetImage(h.asset);
      }
    }
  }
  return const AssetImage('assets/images/home/home_relax_tea.jpg');
});

/// Whether Me shows something other than the default.
final meHeroCustomisedProvider = Provider<bool>(
  (ref) => ref.watch(uiPrefsProvider.select((p) => p.meHero)) != null,
);

/// Changes the Me hero.
class MeHeroActions {
  MeHeroActions(this._ref);

  final Ref _ref;

  UiPrefsStore get _store => _ref.read(uiPrefsStoreProvider);

  Future<void> _removeOld() async {
    final old = _ref.read(uiPrefsProvider).meHero;
    if (old != null && old.startsWith('custom:')) {
      await _store.deleteHeroImage(old.substring(7));
    }
  }

  Future<void> useBundled(String id) async {
    await _removeOld();
    await _ref
        .read(uiPrefsProvider.notifier)
        .update(_ref.read(uiPrefsProvider).copyWith(meHero: 'bundled:$id'));
  }

  Future<void> useBytes(Uint8List bytes) async {
    final name = await _store.saveHeroImage(bytes);
    await _removeOld();
    await _ref
        .read(uiPrefsProvider.notifier)
        .update(_ref.read(uiPrefsProvider).copyWith(meHero: 'custom:$name'));
  }

  Future<void> restoreDefault() async {
    await _removeOld();
    await _ref
        .read(uiPrefsProvider.notifier)
        .update(_ref.read(uiPrefsProvider).copyWith(clearMeHero: true));
  }
}

final meHeroActionsProvider = Provider<MeHeroActions>(MeHeroActions.new);
