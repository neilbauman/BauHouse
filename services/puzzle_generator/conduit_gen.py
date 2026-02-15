"""CONDUIT (Pipes) puzzle generator.

Generates a connected pipe network on a grid, then scrambles rotations.
Uses a serpentine path through the grid as the connected solution,
then determines the correct pipe type and rotation for each cell.
"""

import random
import json
from typing import Any, List, Tuple, Set


def generate_conduit(width: int, height: int) -> dict:
    """Generate a CONDUIT puzzle with given dimensions.

    Returns dict with 'grid_data' and 'solution_data' keys.
    """
    # Build a serpentine path covering all cells
    path = _build_serpentine_path(width, height)

    # For each cell, determine connections based on neighbors in the path
    connections = _compute_connections(path, width, height)

    # Convert connections to cell type and rotation
    solution_cells = []
    for row in range(height):
        for col in range(width):
            dirs = connections[row * width + col]
            cell_type, rotation = _dirs_to_type_rotation(dirs)
            solution_cells.append({"type": cell_type, "rotation": rotation})

    # Scramble rotations for the grid_data
    scrambled_cells = []
    for cell in solution_cells:
        scrambled_rot = random.choice([0, 90, 180, 270])
        scrambled_cells.append({"type": cell["type"], "rotation": scrambled_rot})

    grid_data = {"width": width, "height": height, "cells": scrambled_cells}
    solution_data = {"width": width, "height": height, "cells": solution_cells}

    return {"grid_data": grid_data, "solution_data": solution_data}


def _build_serpentine_path(width: int, height: int) -> List[Tuple[int, int]]:
    """Build a serpentine path covering all cells."""
    path = []
    for row in range(height):
        if row % 2 == 0:
            for col in range(width):
                path.append((row, col))
        else:
            for col in range(width - 1, -1, -1):
                path.append((row, col))
    return path


def _compute_connections(
    path: List[Tuple[int, int]], width: int, height: int
) -> List[Set[int]]:
    """For each cell, compute which directions it connects to.

    Directions: 0=up, 1=right, 2=down, 3=left
    """
    connections = [set() for _ in range(width * height)]
    dr = [-1, 0, 1, 0]
    dc = [0, 1, 0, -1]
    opposite = [2, 3, 0, 1]

    for i in range(len(path) - 1):
        r1, c1 = path[i]
        r2, c2 = path[i + 1]
        # Find direction from (r1,c1) to (r2,c2)
        for d in range(4):
            if r1 + dr[d] == r2 and c1 + dc[d] == c2:
                connections[r1 * width + c1].add(d)
                connections[r2 * width + c2].add(opposite[d])
                break

    return connections


def _dirs_to_type_rotation(dirs: set) -> Tuple[str, int]:
    """Convert a set of directions to a cell type and rotation.

    Base types at rotation 0:
    - end: {0} (up)
    - straight: {0, 2} (up+down)
    - corner: {0, 1} (up+right)
    - tee: {0, 1, 2} (up+right+down)
    - cross: {0, 1, 2, 3}
    """
    n = len(dirs)
    sorted_dirs = sorted(dirs)

    if n == 1:
        # end — rotated so the connection matches
        rotation = sorted_dirs[0] * 90
        return ("end", rotation)

    if n == 4:
        return ("cross", 0)

    if n == 2:
        d1, d2 = sorted_dirs
        if abs(d1 - d2) == 2:
            # straight
            rotation = d1 * 90
            return ("straight", rotation)
        else:
            # corner — base is {0,1}
            # Find rotation: which rotation of {0,1} gives {d1,d2}?
            for rot in range(4):
                mapped = {(0 + rot) % 4, (1 + rot) % 4}
                if mapped == dirs:
                    return ("corner", rot * 90)

    if n == 3:
        # tee — base is {0,1,2}
        for rot in range(4):
            mapped = {(0 + rot) % 4, (1 + rot) % 4, (2 + rot) % 4}
            if mapped == dirs:
                return ("tee", rot * 90)

    # Fallback
    return ("straight", 0)
