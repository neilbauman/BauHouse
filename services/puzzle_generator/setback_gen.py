"""SETBACK (Kings variant) puzzle generator.

Generates a valid Kings puzzle: place N houses on a grid such that
no two houses are adjacent (including diagonals). Some cells may be
pre-placed (fixed) or restricted.

Strategy:
1. Use backtracking to find a valid placement of N houses.
2. Optionally fix some houses and add restricted zones.
"""

import random
from typing import Any, Optional, List, Tuple


def generate_setback(
    width: int, height: int, house_count: int, num_restricted: int = 0
) -> dict:
    """Generate a SETBACK puzzle.

    Returns dict with 'grid_data' and 'solution_data' keys.
    """
    for _ in range(200):
        solution = _find_placement(width, height, house_count)
        if solution is None:
            continue

        # Decide how many to pre-place as fixed (0 to 2 for schematic)
        num_fixed = random.randint(0, min(2, house_count - 1))
        fixed_positions = random.sample(solution, num_fixed)
        remaining = [p for p in solution if p not in fixed_positions]

        # Generate restricted cells (cells not in solution, not adjacent to solution)
        restricted = _generate_restricted(
            width, height, solution, num_restricted
        )

        grid_data = {
            "width": width,
            "height": height,
            "house_count": house_count,
        }
        if fixed_positions:
            grid_data["fixed"] = [
                {"row": r, "col": c} for r, c in fixed_positions
            ]
        if restricted:
            grid_data["restricted"] = [
                {"row": r, "col": c} for r, c in restricted
            ]

        solution_data = {
            "houses": [{"row": r, "col": c} for r, c in solution]
        }

        return {"grid_data": grid_data, "solution_data": solution_data}

    raise RuntimeError(
        f"Failed to generate SETBACK puzzle {width}x{height} with {house_count} houses"
    )


def _find_placement(
    width: int, height: int, house_count: int
) -> Optional[List[Tuple[int, int]]]:
    """Find a valid placement of houses using backtracking."""
    cells = [(r, c) for r in range(height) for c in range(width)]
    random.shuffle(cells)

    placed: list[tuple[int, int]] = []

    def is_valid(r: int, c: int) -> bool:
        for pr, pc in placed:
            if abs(pr - r) <= 1 and abs(pc - c) <= 1:
                return False
        return True

    def backtrack(idx: int) -> bool:
        if len(placed) == house_count:
            return True
        if idx >= len(cells):
            return False
        remaining_cells = len(cells) - idx
        if remaining_cells + len(placed) < house_count:
            return False

        r, c = cells[idx]
        if is_valid(r, c):
            placed.append((r, c))
            if backtrack(idx + 1):
                return True
            placed.pop()

        return backtrack(idx + 1)

    if backtrack(0):
        return placed
    return None


def _generate_restricted(
    width: int,
    height: int,
    solution: List[Tuple[int, int]],
    count: int,
) -> List[Tuple[int, int]]:
    """Generate restricted cells that don't conflict with the solution."""
    if count <= 0:
        return []

    solution_set = set(solution)
    # Can't restrict solution cells or cells adjacent to solution
    forbidden = set()
    for r, c in solution:
        for dr in range(-1, 2):
            for dc in range(-1, 2):
                forbidden.add((r + dr, c + dc))

    candidates = [
        (r, c)
        for r in range(height)
        for c in range(width)
        if (r, c) not in forbidden
    ]

    if len(candidates) < count:
        count = len(candidates)

    return random.sample(candidates, count) if candidates else []
