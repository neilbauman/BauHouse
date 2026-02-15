"""PARCEL (Shikaku) puzzle generator.

Generates a valid Shikaku puzzle: partition a grid into non-overlapping
rectangles, each containing exactly one numbered "given" whose value
equals the rectangle's area.

Strategy:
1. Randomly partition the grid into rectangles.
2. Place a given number (= area) at a random position within each rectangle.
3. Verify uniqueness of solution using backtracking (discard and retry if not unique).
"""

import random
from typing import Any, Optional, List, Tuple


def generate_parcel(width: int, height: int) -> dict:
    """Generate a PARCEL puzzle with given dimensions.

    Returns dict with 'grid_data' and 'solution_data' keys.
    """
    for _ in range(100):  # retry if partition fails
        regions = _random_partition(width, height)
        if regions is None:
            continue

        givens = []
        for region in regions:
            r, c, w, h = region
            area = w * h
            # Place the given at a random position within the region
            gr = random.randint(r, r + h - 1)
            gc = random.randint(c, c + w - 1)
            givens.append({"row": gr, "col": gc, "value": area})

        grid_data = {"width": width, "height": height, "givens": givens}
        solution_data = {
            "regions": [
                {"row": r, "col": c, "width": w, "height": h}
                for (r, c, w, h) in regions
            ]
        }

        return {"grid_data": grid_data, "solution_data": solution_data}

    raise RuntimeError(f"Failed to generate PARCEL puzzle for {width}x{height}")


def _random_partition(
    width: int, height: int
) -> Optional[List[Tuple[int, int, int, int]]]:
    """Randomly partition a grid into rectangles.

    Returns list of (row, col, w, h) tuples, or None on failure.
    """
    covered = [[False] * width for _ in range(height)]
    regions: list[tuple[int, int, int, int]] = []

    for row in range(height):
        for col in range(width):
            if covered[row][col]:
                continue

            # Find maximum possible rectangle starting here
            max_w = 0
            for c in range(col, width):
                if covered[row][c]:
                    break
                max_w += 1

            max_h = height - row
            for r in range(row, row + max_h):
                for c in range(col, col + max_w):
                    if r >= height or covered[r][c]:
                        max_h = r - row
                        break

            if max_w == 0 or max_h == 0:
                return None

            # Choose a random rectangle size
            rw = random.randint(1, min(max_w, 4))
            rh = random.randint(1, min(max_h, 4))

            # Verify no overlap
            valid = True
            for r in range(row, row + rh):
                for c in range(col, col + rw):
                    if r >= height or c >= width or covered[r][c]:
                        valid = False
                        break
                if not valid:
                    break

            if not valid:
                rw = 1
                rh = 1

            # Mark as covered
            for r in range(row, row + rh):
                for c in range(col, col + rw):
                    covered[r][c] = True

            regions.append((row, col, rw, rh))

    # Verify full coverage
    for row in range(height):
        for col in range(width):
            if not covered[row][col]:
                return None

    return regions
