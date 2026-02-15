import 'package:flutter_test/flutter_test.dart';
import 'package:bauhouse/features/puzzles/parcel/parcel_models.dart';
import 'package:bauhouse/features/puzzles/parcel/parcel_engine.dart';

void main() {
  group('ParcelGiven', () {
    test('fromJson and toJson roundtrip', () {
      final json = {'row': 1, 'col': 2, 'value': 6};
      final given = ParcelGiven.fromJson(json);
      expect(given.row, 1);
      expect(given.col, 2);
      expect(given.value, 6);
      expect(given.toJson(), json);
    });
  });

  group('ParcelRegion', () {
    test('area is width * height', () {
      const region = ParcelRegion(row: 0, col: 0, width: 3, height: 2);
      expect(region.area, 6);
    });

    test('contains checks cell membership', () {
      const region = ParcelRegion(row: 1, col: 1, width: 2, height: 3);
      expect(region.contains(1, 1), true);
      expect(region.contains(3, 2), true);
      expect(region.contains(0, 1), false);
      expect(region.contains(1, 0), false);
      expect(region.contains(4, 1), false);
      expect(region.contains(1, 3), false);
    });

    test('cellIndices returns correct indices for grid width', () {
      const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
      final indices = region.cellIndices(4);
      expect(indices, {0, 1, 4, 5});
    });

    test('fromJson and toJson roundtrip', () {
      final json = {'row': 1, 'col': 2, 'width': 3, 'height': 4};
      final region = ParcelRegion.fromJson(json);
      expect(region.row, 1);
      expect(region.col, 2);
      expect(region.width, 3);
      expect(region.height, 4);
      expect(region.toJson(), json);
    });

    test('equality', () {
      const a = ParcelRegion(row: 0, col: 0, width: 2, height: 3);
      const b = ParcelRegion(row: 0, col: 0, width: 2, height: 3);
      const c = ParcelRegion(row: 0, col: 0, width: 3, height: 2);
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('ParcelEngine', () {
    test('puzzleType is parcel', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      expect(engine.puzzleType, 'parcel');
    });

    test('fromGridData creates correct engine', () {
      final gridData = {
        'width': 4,
        'height': 4,
        'givens': [
          {'row': 0, 'col': 0, 'value': 4},
          {'row': 2, 'col': 2, 'value': 4},
        ],
      };
      final engine = ParcelEngine.fromGridData(gridData);
      expect(engine.width, 4);
      expect(engine.height, 4);
      expect(engine.givens.length, 2);
    });

    test('givenAt returns given at position or null', () {
      final engine = ParcelEngine(
        width: 4,
        height: 4,
        givens: [
          const ParcelGiven(row: 0, col: 1, value: 6),
          const ParcelGiven(row: 2, col: 3, value: 4),
        ],
      );
      expect(engine.givenAt(0, 1)?.value, 6);
      expect(engine.givenAt(2, 3)?.value, 4);
      expect(engine.givenAt(0, 0), null);
    });

    test('addRegion succeeds within bounds and no overlap', () {
      final engine = ParcelEngine(
        width: 4,
        height: 4,
        givens: [const ParcelGiven(row: 0, col: 0, value: 4)],
      );
      const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
      expect(engine.addRegion(region), true);
      expect(engine.regions.length, 1);
    });

    test('addRegion fails if region exceeds grid bounds', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      const region = ParcelRegion(row: 3, col: 3, width: 2, height: 2);
      expect(engine.addRegion(region), false);
      expect(engine.regions.length, 0);
    });

    test('addRegion fails if region overlaps existing', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      const r1 = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
      const r2 = ParcelRegion(row: 1, col: 1, width: 2, height: 2);
      engine.addRegion(r1);
      expect(engine.addRegion(r2), false);
      expect(engine.regions.length, 1);
    });

    test('removeRegionAt removes the correct region', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
      engine.addRegion(region);
      final removed = engine.removeRegionAt(1, 1);
      expect(removed, region);
      expect(engine.regions.length, 0);
    });

    test('removeRegionAt returns null for empty cell', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      expect(engine.removeRegionAt(0, 0), null);
    });

    test('regionIndexAt returns correct index', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      const r1 = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
      const r2 = ParcelRegion(row: 0, col: 2, width: 2, height: 2);
      engine.addRegion(r1);
      engine.addRegion(r2);
      expect(engine.regionIndexAt(0, 0), 0);
      expect(engine.regionIndexAt(0, 3), 1);
      expect(engine.regionIndexAt(2, 0), -1);
    });

    test('handleDrag creates region and removes overlaps', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      const existing = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
      engine.addRegion(existing);

      // Drag a region that overlaps the existing one
      engine.handleDrag(0, 0, 1, 3);
      expect(engine.regions.length, 1);
      expect(engine.regions.first.width, 4);
      expect(engine.regions.first.height, 2);
    });

    test('handleTap removes region at tapped cell', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
      engine.addRegion(region);
      engine.handleTap(1, 1);
      expect(engine.regions.length, 0);
    });

    group('isSolved', () {
      test('solved when all cells covered and all regions valid', () {
        // 4x4 grid with 4 givens of value 4
        final engine = ParcelEngine(
          width: 4,
          height: 4,
          givens: [
            const ParcelGiven(row: 0, col: 0, value: 4),
            const ParcelGiven(row: 0, col: 2, value: 4),
            const ParcelGiven(row: 2, col: 0, value: 4),
            const ParcelGiven(row: 2, col: 2, value: 4),
          ],
        );

        engine.addRegion(const ParcelRegion(row: 0, col: 0, width: 2, height: 2));
        engine.addRegion(const ParcelRegion(row: 0, col: 2, width: 2, height: 2));
        engine.addRegion(const ParcelRegion(row: 2, col: 0, width: 2, height: 2));
        engine.addRegion(const ParcelRegion(row: 2, col: 2, width: 2, height: 2));

        expect(engine.isSolved, true);
      });

      test('not solved when cells are uncovered', () {
        final engine = ParcelEngine(
          width: 4,
          height: 4,
          givens: [
            const ParcelGiven(row: 0, col: 0, value: 4),
          ],
        );
        engine.addRegion(const ParcelRegion(row: 0, col: 0, width: 2, height: 2));
        expect(engine.isSolved, false);
      });

      test('not solved when region has wrong area', () {
        // 2x2 grid: given is 3 but region area is 4
        final engine = ParcelEngine(
          width: 2,
          height: 2,
          givens: [
            const ParcelGiven(row: 0, col: 0, value: 3),
          ],
        );
        engine.addRegion(const ParcelRegion(row: 0, col: 0, width: 2, height: 2));
        expect(engine.isSolved, false);
      });

      test('not solved when region has no given', () {
        final engine = ParcelEngine(
          width: 4,
          height: 2,
          givens: [
            const ParcelGiven(row: 0, col: 0, value: 4),
          ],
        );
        engine.addRegion(const ParcelRegion(row: 0, col: 0, width: 2, height: 2));
        engine.addRegion(const ParcelRegion(row: 0, col: 2, width: 2, height: 2));
        expect(engine.isSolved, false);
      });

      test('not solved when region has multiple givens', () {
        final engine = ParcelEngine(
          width: 2,
          height: 2,
          givens: [
            const ParcelGiven(row: 0, col: 0, value: 2),
            const ParcelGiven(row: 0, col: 1, value: 2),
          ],
        );
        engine.addRegion(const ParcelRegion(row: 0, col: 0, width: 2, height: 2));
        expect(engine.isSolved, false);
      });

      test('empty grid with no givens is solved trivially', () {
        // Edge case: 0 givens, 0 regions — not solved because cells aren't covered
        // Actually a 0x0 grid with 0 givens...
        final engine = ParcelEngine(width: 0, height: 0, givens: []);
        expect(engine.isSolved, true);
      });
    });

    group('validateRegion', () {
      test('returns valid for correctly sized region with one given', () {
        final engine = ParcelEngine(
          width: 4,
          height: 4,
          givens: [const ParcelGiven(row: 0, col: 0, value: 4)],
        );
        const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
        expect(engine.validateRegion(region), 'valid');
      });

      test('returns no_given for region without a given', () {
        final engine = ParcelEngine(
          width: 4,
          height: 4,
          givens: [const ParcelGiven(row: 3, col: 3, value: 1)],
        );
        const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
        expect(engine.validateRegion(region), 'no_given');
      });

      test('returns wrong_area when area does not match given', () {
        final engine = ParcelEngine(
          width: 4,
          height: 4,
          givens: [const ParcelGiven(row: 0, col: 0, value: 6)],
        );
        const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
        expect(engine.validateRegion(region), 'wrong_area');
      });

      test('returns multi_given when region covers two givens', () {
        final engine = ParcelEngine(
          width: 4,
          height: 4,
          givens: [
            const ParcelGiven(row: 0, col: 0, value: 2),
            const ParcelGiven(row: 0, col: 1, value: 2),
          ],
        );
        const region = ParcelRegion(row: 0, col: 0, width: 2, height: 2);
        expect(engine.validateRegion(region), 'multi_given');
      });
    });

    test('reset clears all regions', () {
      final engine = ParcelEngine(width: 4, height: 4, givens: []);
      engine.addRegion(const ParcelRegion(row: 0, col: 0, width: 2, height: 2));
      engine.reset();
      expect(engine.regions.length, 0);
    });

    test('currentState serialises correctly', () {
      final engine = ParcelEngine(
        width: 4,
        height: 4,
        givens: [const ParcelGiven(row: 0, col: 0, value: 4)],
      );
      engine.addRegion(const ParcelRegion(row: 0, col: 0, width: 2, height: 2));
      final state = engine.currentState;
      expect(state['width'], 4);
      expect(state['height'], 4);
      expect((state['givens'] as List).length, 1);
      expect((state['regions'] as List).length, 1);
    });

    test('solved 6x6 realistic puzzle', () {
      // A realistic 6×6 Shikaku puzzle:
      //   Givens at specific positions, solution covers all 36 cells.
      //
      //   [6] .  .  | [4]  .  .  .
      //    .  .  .  |  .   .  .  .
      //   --- --- ---|--- --- --- ---
      //    .  .  .  | [3]  .  .  .
      //   [6] .  .  |  .   .  .  .
      //    .  .  .  | [6]  .  .  .
      //    .  .  .  |  .   .  .  .
      //   Nah, let me make a simpler 6×6

      // Simple 6×6: 6 regions
      final engine = ParcelEngine(
        width: 6,
        height: 6,
        givens: [
          const ParcelGiven(row: 0, col: 0, value: 6), // 6x1 top row
          const ParcelGiven(row: 1, col: 0, value: 6), // 1x6 second row
          const ParcelGiven(row: 2, col: 0, value: 6), // 6x1 third row
          const ParcelGiven(row: 3, col: 0, value: 6), // 1x6 fourth row
          const ParcelGiven(row: 4, col: 0, value: 6), // 6x1 fifth row
          const ParcelGiven(row: 5, col: 0, value: 6), // 1x6 sixth row
        ],
      );

      for (int r = 0; r < 6; r++) {
        engine.addRegion(ParcelRegion(row: r, col: 0, width: 6, height: 1));
      }

      expect(engine.isSolved, true);
    });
  });
}
