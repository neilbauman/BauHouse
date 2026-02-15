import 'package:flutter_test/flutter_test.dart';
import 'package:bauhouse/features/puzzles/draft/draft_models.dart';
import 'package:bauhouse/features/puzzles/draft/draft_engine.dart';

void main() {
  group('DraftCellState', () {
    test('has three states', () {
      expect(DraftCellState.values.length, 3);
    });
  });

  group('DraftEngine', () {
    test('puzzleType is draft', () {
      final engine = DraftEngine(
        width: 3,
        height: 3,
        rowClues: [
          [1],
          [1],
          [1]
        ],
        colClues: [
          [1],
          [1],
          [1]
        ],
      );
      expect(engine.puzzleType, 'draft');
    });

    test('fromGridData creates correct engine', () {
      final gridData = {
        'width': 5,
        'height': 5,
        'row_clues': [
          [3],
          [1, 1],
          [5],
          [1],
          [2, 1]
        ],
        'col_clues': [
          [2],
          [1, 1],
          [3],
          [1],
          [2, 1]
        ],
      };
      final engine = DraftEngine.fromGridData(gridData);
      expect(engine.width, 5);
      expect(engine.height, 5);
      expect(engine.rowClues.length, 5);
      expect(engine.colClues.length, 5);
      expect(engine.rowClues[0], [3]);
      expect(engine.rowClues[1], [1, 1]);
    });

    test('initial cells are all empty', () {
      final engine = DraftEngine(
        width: 3,
        height: 3,
        rowClues: [
          [1],
          [1],
          [1]
        ],
        colClues: [
          [1],
          [1],
          [1]
        ],
      );
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          expect(engine.cellAt(r, c), DraftCellState.empty);
        }
      }
    });

    test('handleTap cycles empty → filled → marked → empty', () {
      final engine = DraftEngine(
        width: 3,
        height: 3,
        rowClues: [
          [1],
          [0],
          [0]
        ],
        colClues: [
          [1],
          [0],
          [0]
        ],
      );
      expect(engine.cellAt(0, 0), DraftCellState.empty);
      engine.handleTap(0, 0);
      expect(engine.cellAt(0, 0), DraftCellState.filled);
      engine.handleTap(0, 0);
      expect(engine.cellAt(0, 0), DraftCellState.marked);
      engine.handleTap(0, 0);
      expect(engine.cellAt(0, 0), DraftCellState.empty);
    });

    test('handleTap ignores out of bounds', () {
      final engine = DraftEngine(
        width: 3,
        height: 3,
        rowClues: [
          [0],
          [0],
          [0]
        ],
        colClues: [
          [0],
          [0],
          [0]
        ],
      );
      engine.handleTap(-1, 0);
      engine.handleTap(0, -1);
      engine.handleTap(3, 0);
      engine.handleTap(0, 3);
      // No exceptions, all still empty
      for (int i = 0; i < 9; i++) {
        expect(engine.cells[i], DraftCellState.empty);
      }
    });

    test('rowGroups computes groups correctly', () {
      // 5-wide row: F F E F F → [2, 2]
      final engine = DraftEngine(
        width: 5,
        height: 1,
        rowClues: [
          [2, 2]
        ],
        colClues: [
          [1],
          [1],
          [0],
          [1],
          [1]
        ],
      );
      engine.handleTap(0, 0); // fill
      engine.handleTap(0, 1); // fill
      engine.handleTap(0, 3); // fill
      engine.handleTap(0, 4); // fill
      expect(engine.rowGroups(0), [2, 2]);
    });

    test('rowGroups returns empty list for empty row', () {
      final engine = DraftEngine(
        width: 3,
        height: 1,
        rowClues: [
          [0]
        ],
        colClues: [
          [0],
          [0],
          [0]
        ],
      );
      expect(engine.rowGroups(0), []);
    });

    test('colGroups computes groups correctly', () {
      // 3-high column: F E F → [1, 1]
      final engine = DraftEngine(
        width: 1,
        height: 3,
        rowClues: [
          [1],
          [0],
          [1]
        ],
        colClues: [
          [1, 1]
        ],
      );
      engine.handleTap(0, 0); // fill
      engine.handleTap(2, 0); // fill
      expect(engine.colGroups(0), [1, 1]);
    });

    test('isRowSatisfied checks row clue match', () {
      final engine = DraftEngine(
        width: 3,
        height: 1,
        rowClues: [
          [2]
        ],
        colClues: [
          [1],
          [1],
          [0]
        ],
      );
      expect(engine.isRowSatisfied(0), false);
      engine.handleTap(0, 0);
      engine.handleTap(0, 1);
      expect(engine.isRowSatisfied(0), true);
    });

    test('isColSatisfied checks column clue match', () {
      final engine = DraftEngine(
        width: 1,
        height: 3,
        rowClues: [
          [1],
          [0],
          [1]
        ],
        colClues: [
          [1, 1]
        ],
      );
      engine.handleTap(0, 0);
      expect(engine.isColSatisfied(0), false);
      engine.handleTap(2, 0);
      expect(engine.isColSatisfied(0), true);
    });

    group('isSolved', () {
      test('solved when all rows and columns satisfied', () {
        // Simple 3x3 nonogram:
        // Row clues: [1], [3], [1]
        // Col clues: [1], [3], [1]
        //
        // Solution:
        //  . X .
        //  X X X
        //  . X .
        final engine = DraftEngine(
          width: 3,
          height: 3,
          rowClues: [
            [1],
            [3],
            [1]
          ],
          colClues: [
            [1],
            [3],
            [1]
          ],
        );

        engine.handleTap(0, 1); // (0,1) filled
        engine.handleTap(1, 0); // (1,0) filled
        engine.handleTap(1, 1); // (1,1) filled
        engine.handleTap(1, 2); // (1,2) filled
        engine.handleTap(2, 1); // (2,1) filled

        expect(engine.isSolved, true);
      });

      test('not solved when a row is incomplete', () {
        final engine = DraftEngine(
          width: 3,
          height: 3,
          rowClues: [
            [1],
            [3],
            [1]
          ],
          colClues: [
            [1],
            [3],
            [1]
          ],
        );

        engine.handleTap(0, 1); // (0,1) filled
        engine.handleTap(1, 0); // (1,0) filled
        engine.handleTap(1, 1); // (1,1) filled
        // Missing (1,2) and (2,1)

        expect(engine.isSolved, false);
      });

      test('empty grid with all-zero clues is solved', () {
        final engine = DraftEngine(
          width: 2,
          height: 2,
          rowClues: [
            [],
            []
          ],
          colClues: [
            [],
            []
          ],
        );
        expect(engine.isSolved, true);
      });
    });

    test('handleDrag fills horizontal line', () {
      final engine = DraftEngine(
        width: 5,
        height: 1,
        rowClues: [
          [3]
        ],
        colClues: [
          [1],
          [1],
          [1],
          [0],
          [0]
        ],
      );
      engine.handleDrag(0, 0, 0, 2);
      expect(engine.cellAt(0, 0), DraftCellState.filled);
      expect(engine.cellAt(0, 1), DraftCellState.filled);
      expect(engine.cellAt(0, 2), DraftCellState.filled);
      expect(engine.cellAt(0, 3), DraftCellState.empty);
    });

    test('handleDrag fills vertical line', () {
      final engine = DraftEngine(
        width: 1,
        height: 5,
        rowClues: [
          [1],
          [1],
          [1],
          [0],
          [0]
        ],
        colClues: [
          [3]
        ],
      );
      engine.handleDrag(0, 0, 2, 0);
      expect(engine.cellAt(0, 0), DraftCellState.filled);
      expect(engine.cellAt(1, 0), DraftCellState.filled);
      expect(engine.cellAt(2, 0), DraftCellState.filled);
      expect(engine.cellAt(3, 0), DraftCellState.empty);
    });

    test('currentState serialises to 0/1 array', () {
      final engine = DraftEngine(
        width: 2,
        height: 2,
        rowClues: [
          [1],
          [1]
        ],
        colClues: [
          [1],
          [1]
        ],
      );
      engine.handleTap(0, 0);
      engine.handleTap(1, 1);
      final state = engine.currentState;
      expect(state['cells'], [1, 0, 0, 1]);
    });

    test('reset clears all cells', () {
      final engine = DraftEngine(
        width: 2,
        height: 2,
        rowClues: [
          [1],
          [1]
        ],
        colClues: [
          [1],
          [1]
        ],
      );
      engine.handleTap(0, 0);
      engine.handleTap(1, 1);
      engine.reset();
      for (int i = 0; i < 4; i++) {
        expect(engine.cells[i], DraftCellState.empty);
      }
    });

    test('marked cells do not count as filled', () {
      final engine = DraftEngine(
        width: 3,
        height: 1,
        rowClues: [
          [1]
        ],
        colClues: [
          [0],
          [1],
          [0]
        ],
      );
      engine.handleTap(0, 0); // fill
      engine.handleTap(0, 0); // mark
      engine.handleTap(0, 1); // fill
      expect(engine.rowGroups(0), [1]);
      expect(engine.cellAt(0, 0), DraftCellState.marked);
      expect(engine.cellAt(0, 1), DraftCellState.filled);
    });
  });
}
