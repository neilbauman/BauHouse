import 'package:flutter_test/flutter_test.dart';
import 'package:bauhouse/features/puzzles/conduit/conduit_engine.dart';
import 'package:bauhouse/features/puzzles/conduit/conduit_models.dart';

void main() {
  group('ConduitCell', () {
    test('straight cell at rotation 0 connects up and down', () {
      final cell = ConduitCell(type: CellType.straight, rotation: 0);
      expect(cell.connections, equals({0, 2}));
    });

    test('straight cell at rotation 90 connects right and left', () {
      final cell = ConduitCell(type: CellType.straight, rotation: 90);
      expect(cell.connections, equals({1, 3}));
    });

    test('corner cell at rotation 0 connects up and right', () {
      final cell = ConduitCell(type: CellType.corner, rotation: 0);
      expect(cell.connections, equals({0, 1}));
    });

    test('corner cell at rotation 90 connects right and down', () {
      final cell = ConduitCell(type: CellType.corner, rotation: 90);
      expect(cell.connections, equals({1, 2}));
    });

    test('corner cell at rotation 180 connects down and left', () {
      final cell = ConduitCell(type: CellType.corner, rotation: 180);
      expect(cell.connections, equals({2, 3}));
    });

    test('corner cell at rotation 270 connects left and up', () {
      final cell = ConduitCell(type: CellType.corner, rotation: 270);
      expect(cell.connections, equals({3, 0}));
    });

    test('tee cell at rotation 0 connects up, right, down', () {
      final cell = ConduitCell(type: CellType.tee, rotation: 0);
      expect(cell.connections, equals({0, 1, 2}));
    });

    test('cross cell connects all four directions at any rotation', () {
      for (final rot in [0, 90, 180, 270]) {
        final cell = ConduitCell(type: CellType.cross, rotation: rot);
        expect(cell.connections, equals({0, 1, 2, 3}));
      }
    });

    test('end cell at rotation 0 connects up only', () {
      final cell = ConduitCell(type: CellType.end, rotation: 0);
      expect(cell.connections, equals({0}));
    });

    test('end cell at rotation 90 connects right only', () {
      final cell = ConduitCell(type: CellType.end, rotation: 90);
      expect(cell.connections, equals({1}));
    });

    test('rotateCW advances rotation by 90', () {
      final cell = ConduitCell(type: CellType.straight, rotation: 0);
      cell.rotateCW();
      expect(cell.rotation, equals(90));
      cell.rotateCW();
      expect(cell.rotation, equals(180));
      cell.rotateCW();
      expect(cell.rotation, equals(270));
      cell.rotateCW();
      expect(cell.rotation, equals(0));
    });

    test('fromJson and toJson roundtrip', () {
      final original = ConduitCell(type: CellType.tee, rotation: 180);
      final json = original.toJson();
      final restored = ConduitCell.fromJson(json);
      expect(restored.type, equals(CellType.tee));
      expect(restored.rotation, equals(180));
    });
  });

  group('ConduitEngine', () {
    // A simple 2x2 solved grid:
    // corner(90)  corner(180)
    // corner(0)   corner(270)
    //
    // Top-left: right+down, Top-right: down+left
    // Bottom-left: up+right, Bottom-right: left+up
    Map<String, dynamic> make2x2Solved() {
      return {
        'width': 2,
        'height': 2,
        'cells': [
          {'type': 'corner', 'rotation': 90}, // right+down
          {'type': 'corner', 'rotation': 180}, // down+left
          {'type': 'corner', 'rotation': 0}, // up+right
          {'type': 'corner', 'rotation': 270}, // left+up
        ],
      };
    }

    test('fromGridData creates correct grid', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      expect(engine.width, equals(2));
      expect(engine.height, equals(2));
      expect(engine.cells.length, equals(4));
    });

    test('puzzleType is conduit', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      expect(engine.puzzleType, equals('conduit'));
    });

    test('solved 2x2 grid is detected as solved', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      expect(engine.isSolved, isTrue);
    });

    test('unsolved grid is not solved', () {
      final data = make2x2Solved();
      // Rotate top-left to break the solution
      (data['cells'] as List)[0]['rotation'] = 0;
      final engine = ConduitEngine.fromGridData(data);
      expect(engine.isSolved, isFalse);
    });

    test('handleTap rotates cell', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      expect(engine.cellAt(0, 0).rotation, equals(90));
      engine.handleTap(0, 0);
      expect(engine.cellAt(0, 0).rotation, equals(180));
    });

    test('handleTap ignores out of bounds', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      engine.handleTap(-1, 0);
      engine.handleTap(0, 5);
      // No crash
    });

    test('reset restores initial state', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      expect(engine.isSolved, isTrue);
      engine.handleTap(0, 0);
      expect(engine.isSolved, isFalse);
      engine.reset();
      expect(engine.isSolved, isTrue);
    });

    test('currentState serialises correctly', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      final state = engine.currentState;
      expect(state['width'], equals(2));
      expect(state['height'], equals(2));
      expect((state['cells'] as List).length, equals(4));
    });

    test('connectedComponent finds full grid when solved', () {
      final engine = ConduitEngine.fromGridData(make2x2Solved());
      final component = engine.connectedComponent(0, 0);
      expect(component.length, equals(4));
    });

    test('connectedComponent partial when grid has isolated cells', () {
      // 2x2 grid where bottom-right is an end pointing down (off-grid)
      // so it cannot connect to its neighbors
      final gridData = {
        'width': 2,
        'height': 2,
        'cells': [
          {'type': 'corner', 'rotation': 90}, // right+down
          {'type': 'end', 'rotation': 180}, // down only (cannot connect left)
          {'type': 'end', 'rotation': 0}, // up only
          {'type': 'end', 'rotation': 180}, // down only (off-grid)
        ],
      };
      final engine = ConduitEngine.fromGridData(gridData);
      // (0,0) connects right to (0,1), but (0,1) is end(180)=down, no left
      // (0,0) connects down to (1,0), (1,0) is end(0)=up, reciprocated
      final component = engine.connectedComponent(0, 0);
      expect(component, equals({0, 2})); // (0,0) and (1,0) only
    });

    // Larger 3x3 test with a solved configuration
    test('3x3 fully connected grid is solved', () {
      // Row 0: corner(90)=R+D    tee(90)=R+D+L     corner(180)=D+L
      // Row 1: tee(0)=U+R+D      cross(0)=all       tee(180)=D+L+U
      // Row 2: corner(0)=U+R     tee(270)=L+U+R     corner(270)=L+U
      final gridData = {
        'width': 3,
        'height': 3,
        'cells': [
          {'type': 'corner', 'rotation': 90},
          {'type': 'tee', 'rotation': 90},
          {'type': 'corner', 'rotation': 180},
          {'type': 'tee', 'rotation': 0},
          {'type': 'cross', 'rotation': 0},
          {'type': 'tee', 'rotation': 180},
          {'type': 'corner', 'rotation': 0},
          {'type': 'tee', 'rotation': 270},
          {'type': 'corner', 'rotation': 270},
        ],
      };
      final engine = ConduitEngine.fromGridData(gridData);
      expect(engine.isSolved, isTrue);
    });

    test('fromGridData throws on mismatched dimensions', () {
      expect(
        () => ConduitEngine.fromGridData({
          'width': 2,
          'height': 2,
          'cells': [
            {'type': 'straight', 'rotation': 0},
          ],
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
