"""LAMP (Light Up / Akari) puzzle generator.

Generates a valid Light Up puzzle.

Strategy:
1. Place random black cells on the grid.
2. Solve the puzzle using backtracking to find a valid light placement.
3. For black cells adjacent to lights, optionally add numeric clues.
4. Verify solvability.
"""

import random
from typing import Any, Optional, Set, List


def generate_lamp(
    width: int, height: int, black_ratio: float = 0.2
) -> dict:
    """Generate a LAMP puzzle.

    Args:
        width: Grid width.
        height: Grid height.
        black_ratio: Approximate fraction of cells to make black.

    Returns dict with 'grid_data' and 'solution_data' keys.
    """
    for _ in range(200):
        result = _try_generate(width, height, black_ratio)
        if result is not None:
            return result

    raise RuntimeError(f"Failed to generate LAMP puzzle for {width}x{height}")


def _try_generate(
    width: int, height: int, black_ratio: float
) -> Optional[dict]:
    """Attempt to generate a single LAMP puzzle."""
    total = width * height
    num_black = max(1, int(total * black_ratio))

    # Place black cells
    all_indices = list(range(total))
    random.shuffle(all_indices)
    black_set = set(all_indices[:num_black])

    # Find a valid light placement
    empty_cells = [i for i in range(total) if i not in black_set]
    lights = _solve_lamp(width, height, black_set, empty_cells)
    if lights is None:
        return None

    # Build grid cells with optional clues
    grid_cells = []
    for idx in range(total):
        if idx in black_set:
            row = idx // width
            col = idx % width
            adj_lights = _count_adjacent_lights(row, col, width, height, lights)
            # Add clue with ~60% probability
            if random.random() < 0.6:
                grid_cells.append({"type": "black", "clue": adj_lights})
            else:
                grid_cells.append({"type": "black", "clue": None})
        else:
            grid_cells.append({"type": "empty"})

    # Build solution
    light_positions = [
        {"row": idx // width, "col": idx % width}
        for idx in lights
    ]

    grid_data = {"width": width, "height": height, "cells": grid_cells}
    solution_data = {"lights": light_positions}

    return {"grid_data": grid_data, "solution_data": solution_data}


def _solve_lamp(
    width: int,
    height: int,
    black_set: Set[int],
    empty_cells: List[int],
) -> Optional[Set[int]]:
    """Find a valid light placement using greedy + backtracking.

    A valid placement has:
    - All empty cells illuminated
    - No two lights can see each other
    """
    lights: set[int] = set()
    illuminated: set[int] = set()

    def can_place(idx: int) -> bool:
        """Check if placing a light at idx causes a conflict."""
        row = idx // width
        col = idx % width
        # Check all four directions for existing lights
        for dr, dc in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
            r, c = row + dr, col + dc
            while 0 <= r < height and 0 <= c < width:
                nidx = r * width + c
                if nidx in black_set:
                    break
                if nidx in lights:
                    return False
                r += dr
                c += dc
        return True

    def illuminate(idx: int) -> set[int]:
        """Return cells illuminated by placing a light at idx."""
        row = idx // width
        col = idx % width
        lit = {idx}
        for dr, dc in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
            r, c = row + dr, col + dc
            while 0 <= r < height and 0 <= c < width:
                nidx = r * width + c
                if nidx in black_set:
                    break
                lit.add(nidx)
                r += dr
                c += dc
        return lit

    # Greedy: try to place lights to cover all empty cells
    random.shuffle(empty_cells)
    uncovered = set(empty_cells)

    for idx in empty_cells:
        if idx in illuminated:
            continue
        if not can_place(idx):
            continue

        lights.add(idx)
        lit = illuminate(idx)
        illuminated.update(lit)
        uncovered -= lit

    if not uncovered:
        return lights

    # If greedy didn't cover everything, try adding more lights
    remaining = [i for i in uncovered if i not in lights]
    random.shuffle(remaining)

    for idx in remaining:
        if idx in illuminated:
            continue
        if not can_place(idx):
            continue
        lights.add(idx)
        lit = illuminate(idx)
        illuminated.update(lit)
        uncovered -= lit

    if not uncovered:
        return lights

    return None  # Failed to find valid placement


def _count_adjacent_lights(
    row: int, col: int, width: int, height: int, lights: Set[int]
) -> int:
    """Count lights orthogonally adjacent to a cell."""
    count = 0
    for dr, dc in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
        nr, nc = row + dr, col + dc
        if 0 <= nr < height and 0 <= nc < width:
            if (nr * width + nc) in lights:
                count += 1
    return count
