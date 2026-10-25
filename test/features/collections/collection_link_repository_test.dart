import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';

import '../../helpers/pump_app.dart' show testDatabase;

void main() {
  group('which addresses are accepted', () {
    test('http and https, with or without a scheme', () {
      expect(
        parseLinkAddress('https://www.youtube.com/watch?v=abc')?.host,
        'www.youtube.com',
      );
      expect(parseLinkAddress('http://example.com/x')?.scheme, 'http');
      expect(parseLinkAddress('  instagram.com/p/xyz  ')?.scheme, 'https');
    });

    test('anything else is refused', () {
      for (final bad in [
        '',
        '   ',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'tel:+123',
        'mailto:a@b.co',
        'data:text/html,hi',
        'ftp://example.com/x',
        'https://user:pw@example.com/x',
        'https://nodot',
        'has space.com',
        'https://',
        'x' * 2100,
      ]) {
        expect(parseLinkAddress(bad), isNull, reason: bad);
      }
    });

    test('the platform comes from the host only', () {
      LinkPlatform of(String s) => platformOf(parseLinkAddress(s)!);
      expect(of('https://youtu.be/abc'), LinkPlatform.youtube);
      expect(of('https://m.youtube.com/watch'), LinkPlatform.youtube);
      expect(of('https://www.instagram.com/reel/x'), LinkPlatform.instagram);
      expect(of('https://vm.tiktok.com/x'), LinkPlatform.tiktok);
      expect(of('https://pin.it/x'), LinkPlatform.pinterest);
      expect(of('https://example.com/youtube.com'), LinkPlatform.website);
      expect(of('https://notyoutube.com/x'), LinkPlatform.website);
    });
  });

  group('the repository', () {
    late AppDatabase db;
    late CollectionLinkRepository repo;
    setUp(() {
      db = testDatabase();
      repo = CollectionLinkRepository(db);
    });
    tearDown(() => db.close());

    test('adds, lists newest first, and reads back what was typed', () async {
      final a = await repo.add(
        category: LinkCategory.recipes,
        address: 'https://www.youtube.com/watch?v=abc',
        title: '  Lentil soup ',
        creator: 'Sam',
        note: 'Try with lemon',
      );
      expect(a, isNotNull);
      expect(a!.title, 'Lentil soup');
      expect(a.creator, 'Sam');
      expect(a.platform, LinkPlatform.youtube);
      expect(a.source, 'YouTube');
      final b = await repo.add(
        category: LinkCategory.sounds,
        address: 'example.com/calm',
        title: 'Calm',
      );
      expect(b!.creator, isNull);
      expect(b.source, 'example.com');
      expect((await repo.all()).map((l) => l.title), ['Calm', 'Lentil soup']);
    });

    test(
      'refuses an unusable address or an empty title, saving nothing',
      () async {
        expect(
          await repo.add(
            category: LinkCategory.workouts,
            address: 'javascript:alert(1)',
            title: 'x',
          ),
          isNull,
        );
        expect(
          await repo.add(
            category: LinkCategory.workouts,
            address: 'https://example.com',
            title: '   ',
          ),
          isNull,
        );
        expect(await repo.all(), isEmpty);
      },
    );

    test('edit changes the fields and the category', () async {
      final a = (await repo.add(
        category: LinkCategory.workouts,
        address: 'https://example.com/a',
        title: 'A',
      ))!;
      final ok = await repo.update(
        a.id,
        category: LinkCategory.sounds,
        address: 'https://www.tiktok.com/@x/video/1',
        title: 'B',
        creator: 'Pat',
        note: 'n',
      );
      expect(ok, isTrue);
      final b = (await repo.byId(a.id))!;
      expect(
        (b.category, b.title, b.platform, b.creator, b.note),
        (LinkCategory.sounds, 'B', LinkPlatform.tiktok, 'Pat', 'n'),
      );
      expect(
        await repo.update(
          a.id,
          category: LinkCategory.sounds,
          address: 'ftp://x.com',
          title: 'B',
        ),
        isFalse,
      );
      expect((await repo.byId(a.id))!.title, 'B'); // unchanged
    });

    test('moving a link to another category keeps the rest', () async {
      final a = (await repo.add(
        category: LinkCategory.recipes,
        address: 'https://example.com/a',
        title: 'A',
        note: 'keep',
      ))!;
      await repo.setCategory(a.id, LinkCategory.workouts);
      final b = (await repo.byId(a.id))!;
      expect(
        (b.category, b.title, b.note),
        (LinkCategory.workouts, 'A', 'keep'),
      );
    });

    test('delete tombstones the row and empties what the user typed', () async {
      final a = (await repo.add(
        category: LinkCategory.recipes,
        address: 'https://example.com/secret',
        title: 'Private',
        creator: 'Someone',
        note: 'a note',
      ))!;
      await repo.delete(a.id);
      expect(await repo.all(), isEmpty);
      expect(await repo.byId(a.id), isNull);
      final row = await db.select(db.collectionLinks).getSingle();
      expect(row.deletedAt, isNotNull);
      expect((row.url, row.title, row.creator, row.note), ('', '', null, null));
    });
  });
}
