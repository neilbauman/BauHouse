import 'package:flutter_test/flutter_test.dart';
import 'package:bauhouse/features/puzzles/setback/setback_models.dart';
import 'package:bauhouse/features/puzzles/setback/setback_engine.dart';

void main() {
  group('CellPosition', () {
    test('fromJson and toJson roundtrip', () {
      final json = {'row': 2, 'col': 3};
      final pos = CellPosition.fromJson(json);
      expect(pos.row, 2);
      expect(pos.col, 3);
      expect(pos.toJson(), json);
    });

    test('equality', () {
      const a = CellPosition(row: 1, col: 2);
      const b = CellPosition(row: 1, col: 2);
      const c = CellPosition(row: 2, col: 1);
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('SetbackEngine', () {
    test('puzzleType is setback', () {
      final engine = SetbackEngine(
        width: 5,
        height: 5,
        houseCount: 4,
        cells: List.filled(25, SetbackCellState.empty),
      );
      expect(engine.puzzleType, 'setback');
    });

    test('fromGridData creates correct engine', () {
      final gridData = {
        'width': 5,
        'height': 5,
        'house_count': 4,
        'fixed': [
          {'row': 0, 'col': 0},
        ],
        'restricted': [
          {'row': 2, 'col': 2},
        ],
      };
      final engine = SetbackEngine.fromGridData(gridData);
      expect(engine.width, 5);
      expect(engine.height, 5);
      expect(engine.houseCount, 4);
      expect(engine.cellAt(0, 0), SetbackCellState.fixed);
      expect(engine.cellAt(2, 2), SetbackCellState.restricted);
      expect(engine.cellAt(1, 1), SetbackCellState.empty);
    });

    test('fromGridData with no fixed or restricted', () {
      final gridData = {
        'width': 3,
        'height': 3,
        'house_count': 2,
      };
      final engine = SetbackEngine.fromGridData(gridData);
      expect(engine.width, 3);
      expect(engine.houseCount, 2);
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          expect(engine.cellAt(r, c), SetbackCellState.empty);
        }
      }
    });

    test('handleTap toggles empty to house', () {
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: List.filled(9, SetbackCellState.empty),
      );
      engine.handleTap(0, 0);
      expect(engine.cellAt(0, 0), SetbackCellState.house);
    });

    test('handleTap toggles house to empty', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.house;
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      engine.handleTap(0, 0);
      expect(engine.cellAt(0, 0), SetbackCellState.empty);
    });

    test('handleTap does not change fixed cells', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.fixed;
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      engine.handleTap(0, 0);
      expect(engine.cellAt(0, 0), SetbackCellState.fixed);
    });

    test('handleTap does not change restricted cells', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[4] = SetbackCellState.restricted;
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      engine.handleTap(1, 1);
      expect(engine.cellAt(1, 1), SetbackCellState.restricted);
    });

    test('handleTap ignores out of bounds', () {
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: List.filled(9, SetbackCellState.empty),
      );
      engine.handleTap(-1, 0);
      engine.handleTap(0, -1);
      engine.handleTap(3, 0);
      engine.handleTap(0, 3);
      // No exception thrown, all cells still empty
      for (int i = 0; i < 9; i++) {
        expect(engine.cells[i], SetbackCellState.empty);
      }
    });

    test('placedCount includes both house and fixed', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.fixed;
      cells[8] = SetbackCellState.house;
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      expect(engine.placedCount, 2);
    });

    test('hasConflict detects horizontal adjacency', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.house; // (0,0)
      cells[1] = SetbackCellState.house; // (0,1) — adjacent!
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      expect(engine.hasConflict(0, 0), true);
      expect(engine.hasConflict(0, 1), true);
    });

    test('hasConflict detects diagonal adjacency', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.house; // (0,0)
      cells[4] = SetbackCellState.house; // (1,1) — diagonal!
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      expect(engine.hasConflict(0, 0), true);
      expect(engine.hasConflict(1, 1), true);
    });

    test('hasConflict returns false for non-adjacent houses', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.house; // (0,0)
      cells[8] = SetbackCellState.house; // (2,2) — not adjacent
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      expect(engine.hasConflict(0, 0), false);
      expect(engine.hasConflict(2, 2), false);
    });

    test('conflictCells returns all cells in conflict', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.house; // (0,0)
      cells[1] = SetbackCellState.house; // (0,1)
      cells[8] = SetbackCellState.house; // (2,2) — no conflict
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 3,
        cells: cells,
      );
      expect(engine.conflictCells, {0, 1});
    });

    group('isSolved', () {
      test('solved with correct count and no conflicts', () {
        // 5x5 grid, place 5 houses with no adjacency:
        // H . H . H
        // . . . . .
        // H . . . H
        // . . . . .
        // . . . . .
        final cells = List.filled(25, SetbackCellState.empty);
        cells[0] = SetbackCellState.house;  // (0,0)
        cells[2] = SetbackCellState.house;  // (0,2)
        cells[4] = SetbackCellState.house;  // (0,4)
        cells[10] = SetbackCellState.house; // (2,0)
        cells[14] = SetbackCellState.house; // (2,4)
        final engine = SetbackEngine(
          width: 5,
          height: 5,
          houseCount: 5,
          cells: cells,
        );
        expect(engine.isSolved, true);
      });

      test('not solved when count is wrong', () {
        final cells = List.filled(9, SetbackCellState.empty);
        cells[0] = SetbackCellState.house;
        final engine = SetbackEngine(
          width: 3,
          height: 3,
          houseCount: 2,
          cells: cells,
        );
        expect(engine.isSolved, false);
      });

      test('not solved when houses are adjacent', () {
        final cells = List.filled(9, SetbackCellState.empty);
        cells[0] = SetbackCellState.house;
        cells[1] = SetbackCellState.house;
        final engine = SetbackEngine(
          width: 3,
          height: 3,
          houseCount: 2,
          cells: cells,
        );
        expect(engine.isSolved, false);
      });

      test('solved with fixed houses counting toward total', () {
        // 3x3, house_count=2, one fixed at (0,0), player places at (2,2)
        final cells = List.filled(9, SetbackCellState.empty);
        cells[0] = SetbackCellState.fixed; // (0,0)
        cells[8] = SetbackCellState.house; // (2,2)
        final engine = SetbackEngine(
          width: 3,
          height: 3,
          houseCount: 2,
          cells: cells,
        );
        expect(engine.isSolved, true);
      });
    });

    test('reset restores initial state', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.fixed;
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      engine.handleTap(2, 2);
      expect(engine.cellAt(2, 2), SetbackCellState.house);
      engine.reset();
      expect(engine.cellAt(2, 2), SetbackCellState.empty);
      expect(engine.cellAt(0, 0), SetbackCellState.fixed);
    });

    test('currentState serialises house positions', () {
      final cells = List.filled(9, SetbackCellState.empty);
      cells[0] = SetbackCellState.fixed;
      cells[8] = SetbackCellState.house;
      final engine = SetbackEngine(
        width: 3,
        height: 3,
        houseCount: 2,
        cells: cells,
      );
      final state = engine.currentState;
      expect((state['houses'] as List).length, 2);
    });
  });
}
