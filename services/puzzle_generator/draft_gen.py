"""DRAFT (Nonogram) puzzle generator.

Generates a valid Nonogram puzzle from a random pattern.

Strategy:
1. Generate a random binary pattern (the solution).
2. Compute row and column clues from the pattern.
3. The grid_data contains the clues; solution_data has the filled cells.
"""

import random
from typing import Any


def generate_draft(width: int, height: int, fill_ratio: float = 0.5) -> dict:
    """Generate a DRAFT (Nonogram) puzzle.

    Args:
        width: Grid width.
        height: Grid height.
        fill_ratio: Approximate fraction of cells to fill (0.3-0.7 works well).

    Returns dict with 'grid_data' and 'solution_data' keys.
    """
    # Generate a random pattern
    cells = [1 if random.random() < fill_ratio else 0 for _ in range(width * height)]

    # Ensure at least some cells are filled and some are empty
    filled_count = sum(cells)
    if filled_count < 2:
        # Force some fills
        indices = list(range(len(cells)))
        random.shuffle(indices)
        for idx in indices[:3]:
            cells[idx] = 1
    elif filled_count > len(cells) - 2:
        # Force some empties
        indices = [i for i, c in enumerate(cells) if c == 1]
        random.shuffle(indices)
        for idx in indices[:3]:
            cells[idx] = 0

    # Compute row clues
    row_clues = []
    for row in range(height):
        groups = []
        count = 0
        for col in range(width):
            if cells[row * width + col] == 1:
                count += 1
            else:
                if count > 0:
                    groups.append(count)
                count = 0
        if count > 0:
            groups.append(count)
        row_clues.append(groups)

    # Compute column clues
    col_clues = []
    for col in range(width):
        groups = []
        count = 0
        for row in range(height):
            if cells[row * width + col] == 1:
                count += 1
            else:
                if count > 0:
                    groups.append(count)
                count = 0
        if count > 0:
            groups.append(count)
        col_clues.append(groups)

    grid_data = {
        "width": width,
        "height": height,
        "row_clues": row_clues,
        "col_clues": col_clues,
        "cells": None,
    }

    solution_data = {"cells": cells}

    return {"grid_data": grid_data, "solution_data": solution_data}
