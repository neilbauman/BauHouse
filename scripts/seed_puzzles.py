"""
Seed script: Generate 2 weeks of CONDUIT puzzles for BauHouse prototype.
Produces 14 puzzle_sets (one per day) and 140 puzzles (10 per day).

For Phase 0, all 5 puzzle types in each session are CONDUIT.
Schematic: 5x5 grid, Design: 7x7 grid.
"""

import json
import random
import uuid
from datetime import datetime, timedelta

# Puzzle generation parameters
SCHEMATIC_SIZE = 5
DESIGN_SIZE = 7
CELL_TYPES = ["straight", "corner", "tee", "cross", "end"]

# Connection definitions: direction indices 0=up, 1=right, 2=down, 3=left
CONNECTIONS = {
    "straight": {0, 2},
    "corner": {0, 1},
    "tee": {0, 1, 2},
    "cross": {0, 1, 2, 3},
    "end": {0},
}

OPPOSITE = {0: 2, 1: 3, 2: 0, 3: 1}
DR = {0: -1, 1: 0, 2: 1, 3: 0}
DC = {0: 0, 1: 1, 2: 0, 3: -1}


def rotated_connections(cell_type, rotation):
    """Get the set of directions a cell connects to given its rotation."""
    base = CONNECTIONS[cell_type]
    return {(d + rotation // 90) % 4 for d in base}


def generate_solved_grid(width, height):
    """
    Generate a valid solved CONDUIT grid using a spanning tree approach.
    1. Build a random spanning tree over the grid cells.
    2. Assign cell types and rotations that match the tree edges.
    """
    total = width * height
    # Build adjacency: for each cell, store which directions have an edge
    edges = {i: set() for i in range(total)}

    # Random spanning tree via randomized DFS
    visited = set()
    stack = [0]
    visited.add(0)

    while stack:
        current = stack[-1]
        row, col = divmod(current, width)

        # Find unvisited neighbors
        neighbors = []
        for d in [0, 1, 2, 3]:
            nr, nc = row + DR[d], col + DC[d]
            if 0 <= nr < height and 0 <= nc < width:
                nidx = nr * width + nc
                if nidx not in visited:
                    neighbors.append((d, nidx))

        if neighbors:
            d, nidx = random.choice(neighbors)
            edges[current].add(d)
            edges[nidx].add(OPPOSITE[d])
            visited.add(nidx)
            stack.append(nidx)
        else:
            stack.pop()

    # Now assign cell types and rotations to match the edge set
    cells = []
    for i in range(total):
        needed_dirs = edges[i]
        cell_type, rotation = find_cell_type(needed_dirs)
        cells.append({"type": cell_type, "rotation": rotation})

    return cells


def find_cell_type(needed_dirs):
    """Find a cell type and rotation that exactly matches the needed directions."""
    n = len(needed_dirs)

    # Map connection count to possible types
    if n == 1:
        candidates = ["end"]
    elif n == 2:
        # Check if directions are opposite (straight) or adjacent (corner)
        dirs = sorted(needed_dirs)
        if (dirs[1] - dirs[0]) % 4 == 2:
            candidates = ["straight"]
        else:
            candidates = ["corner"]
    elif n == 3:
        candidates = ["tee"]
    elif n == 4:
        candidates = ["cross"]
    else:
        candidates = ["end"]  # fallback

    for cell_type in candidates:
        for rot in [0, 90, 180, 270]:
            if rotated_connections(cell_type, rot) == needed_dirs:
                return cell_type, rot

    # Fallback (should not happen with correct spanning tree)
    return "cross", 0


def scramble_grid(cells):
    """Create a scrambled version of the grid for the player to solve."""
    scrambled = []
    for cell in cells:
        new_rot = random.choice([0, 90, 180, 270])
        scrambled.append({"type": cell["type"], "rotation": new_rot})
    return scrambled


def verify_solution(width, height, cells):
    """Verify that a grid is a valid solved CONDUIT puzzle."""
    total = width * height
    if len(cells) != total:
        return False

    # Check all connections are reciprocated
    for i in range(total):
        row, col = divmod(i, width)
        cell = cells[i]
        conns = rotated_connections(cell["type"], cell["rotation"])
        for d in conns:
            nr, nc = row + DR[d], col + DC[d]
            if nr < 0 or nr >= height or nc < 0 or nc >= width:
                return False
            ni = nr * width + nc
            neighbor = cells[ni]
            n_conns = rotated_connections(neighbor["type"], neighbor["rotation"])
            if OPPOSITE[d] not in n_conns:
                return False

    # Check connectivity (single component)
    visited = set()
    queue = [0]
    visited.add(0)
    while queue:
        i = queue.pop(0)
        row, col = divmod(i, width)
        cell = cells[i]
        conns = rotated_connections(cell["type"], cell["rotation"])
        for d in conns:
            nr, nc = row + DR[d], col + DC[d]
            if 0 <= nr < height and 0 <= nc < width:
                ni = nr * width + nc
                if ni not in visited:
                    visited.add(ni)
                    queue.append(ni)

    return len(visited) == total


# Build Brief narrative data for 14 days
BRIEFS = [
    {
        "project_name": "The Kowalski Cottage",
        "client_name": "The Kowalski Family",
        "brief_intro": "The Kowalskis have been allocated Plot 14 on Birch Street. They need power, water, and their garden connected before move-in day.",
        "completion_text": "The lights are on at the Kowalski cottage. Steam rises from the kitchen window. Birch Street has a new family.",
    },
    {
        "project_name": "Martin Workshop",
        "client_name": "Elena Martin",
        "brief_intro": "Elena Martin is converting her shed into a ceramics workshop. The utility connections need rerouting through the back garden.",
        "completion_text": "The kiln hums gently in the corner. Elena sets her first piece on the shelf. The workshop is open.",
    },
    {
        "project_name": "Okafor-Hughes Extension",
        "client_name": "The Okafor-Hughes Family",
        "brief_intro": "A new bedroom extension on Maple Close. All services need extending from the main house to the new wing.",
        "completion_text": "The extension stands solid. A child's drawing appears in the new window by evening.",
    },
    {
        "project_name": "Birch Street Bakery",
        "client_name": "Yuki Tanaka",
        "brief_intro": "Yuki is opening a bakery on the corner of Birch Street. Gas, water, and electrical connections all need routing from the street main.",
        "completion_text": "The smell of fresh bread drifts down Birch Street at dawn. The bakery is ready for its first morning.",
    },
    {
        "project_name": "The Chen Residence",
        "client_name": "David and Lin Chen",
        "brief_intro": "A modest house on Oak Avenue. The Chens want everything connected before the weekend so they can settle in quietly.",
        "completion_text": "Two chairs appear on the porch of the Chen residence. The garden gate closes softly behind them.",
    },
    {
        "project_name": "Elm Terrace Clinic",
        "client_name": "Dr. Amara Diallo",
        "brief_intro": "Dr. Diallo is setting up a small general practice on Elm Terrace. Medical-grade utilities need careful routing.",
        "completion_text": "A brass nameplate appears beside the door. Dr. Diallo opens the appointment book to a fresh page.",
    },
    {
        "project_name": "The Novak Garden Studio",
        "client_name": "Petra Novak",
        "brief_intro": "An artist's studio at the bottom of the garden on Cedar Lane. Power and water need to reach the far end of the plot.",
        "completion_text": "Light fills the studio through the north-facing window. Petra unwraps her brushes.",
    },
    {
        "project_name": "Willow Walk Playground",
        "client_name": "Elmfield Council",
        "brief_intro": "A community playground on Willow Walk. Lighting and water fountains need connecting to the street grid.",
        "completion_text": "The first children arrive at the playground as the lamps flicker on. Willow Walk sounds different now.",
    },
    {
        "project_name": "The Petrov Flat",
        "client_name": "Alexei Petrov",
        "brief_intro": "A converted attic flat above the hardware store on Ash Road. Services need routing vertically through the building.",
        "completion_text": "Alexei hangs a small plant in the attic window. From up here, you can see the whole of Elmfield.",
    },
    {
        "project_name": "Pine Crescent Greenhouse",
        "client_name": "Margaret Osei",
        "brief_intro": "Margaret is building a greenhouse on Pine Crescent. Water and heating conduits need running from the house.",
        "completion_text": "The first seedlings appear in neat rows. Margaret labels each one in her careful handwriting.",
    },
    {
        "project_name": "The Rivera Terrace",
        "client_name": "The Rivera Family",
        "brief_intro": "A roof terrace addition on Hazel Court. All conduits must route through the existing structure.",
        "completion_text": "String lights glow on the Rivera terrace. The family eats dinner under the stars for the first time.",
    },
    {
        "project_name": "Rowan Way Library",
        "client_name": "Elmfield Trust",
        "brief_intro": "A lending library for Rowan Way. Electricity and data connections needed throughout the reading room.",
        "completion_text": "Books line the shelves. Someone has left a bookmark in the first novel on the shelf.",
    },
    {
        "project_name": "The Andersen Cottage",
        "client_name": "Sven Andersen",
        "brief_intro": "A traditional cottage on Birch Street. Simple connections but everything must be done with care.",
        "completion_text": "Smoke curls from the cottage chimney. Sven places a welcome mat at the door.",
    },
    {
        "project_name": "Maple Close Fountain",
        "client_name": "Elmfield Arts Committee",
        "brief_intro": "A small fountain for the centre of Maple Close. Water supply and drainage need routing from the main.",
        "completion_text": "Water catches the afternoon light. Residents pause on their way home to listen.",
    },
]

# Task descriptions for each slot (construction sequence)
SLOT_TASKS = {
    1: "Divide the development zone into service corridors for the conduit network.",
    2: "Mark the routing zones, ensuring no conduits cross restricted areas.",
    3: "Draft the connection blueprint showing all pipe junctions.",
    4: "Route the main conduit lines through the street grid.",
    5: "Connect the final service line and bring the system online.",
}


def generate_seed_sql():
    """Generate SQL INSERT statements for 14 days of puzzle data."""
    start_date = datetime(2026, 2, 16)  # Start from tomorrow
    statements = []
    puzzle_set_ids = []

    for day in range(14):
        date = start_date + timedelta(days=day)
        date_str = date.strftime("%Y-%m-%d")
        week_number = date.isocalendar()[1]
        brief = BRIEFS[day]

        set_id = str(uuid.uuid4())
        puzzle_set_ids.append(set_id)

        statements.append(
            f"INSERT INTO puzzle_sets (id, scheduled_date, project_name, client_name, brief_intro, completion_text, week_number) "
            f"VALUES ('{set_id}', '{date_str}', "
            f"'{brief['project_name'].replace(chr(39), chr(39)+chr(39))}', "
            f"'{brief['client_name'].replace(chr(39), chr(39)+chr(39))}', "
            f"'{brief['brief_intro'].replace(chr(39), chr(39)+chr(39))}', "
            f"'{brief['completion_text'].replace(chr(39), chr(39)+chr(39))}', "
            f"{week_number});"
        )

        # Generate 10 puzzles: 5 schematic + 5 design
        for mode in ["schematic", "design"]:
            size = SCHEMATIC_SIZE if mode == "schematic" else DESIGN_SIZE
            difficulty_base = 3.0 if mode == "schematic" else 6.0

            for slot in range(1, 6):
                # Generate a valid puzzle
                solution_cells = generate_solved_grid(size, size)
                assert verify_solution(size, size, solution_cells), \
                    f"Generated invalid puzzle for day {day}, {mode}, slot {slot}"

                grid_cells = scramble_grid(solution_cells)

                grid_data = {
                    "width": size,
                    "height": size,
                    "cells": grid_cells,
                }
                solution_data = {
                    "width": size,
                    "height": size,
                    "cells": solution_cells,
                }

                difficulty = round(difficulty_base + random.uniform(-1.0, 1.5), 2)
                task_desc = SLOT_TASKS[slot]
                puzzle_id = str(uuid.uuid4())

                grid_json = json.dumps(grid_data).replace("'", "''")
                sol_json = json.dumps(solution_data).replace("'", "''")

                statements.append(
                    f"INSERT INTO puzzles (id, puzzle_set_id, puzzle_type, mode, slot_number, "
                    f"difficulty_score, grid_data, solution_data, task_description) "
                    f"VALUES ('{puzzle_id}', '{set_id}', 'conduit', '{mode}', {slot}, "
                    f"{difficulty}, '{grid_json}', '{sol_json}', "
                    f"'{task_desc.replace(chr(39), chr(39)+chr(39))}');"
                )

    return "\n".join(statements)


if __name__ == "__main__":
    random.seed(42)  # Reproducible
    sql = generate_seed_sql()

    output_path = "supabase/migrations/20260215000009_seed_puzzles.sql"
    with open(output_path, "w") as f:
        f.write("-- Seed data: 14 days of CONDUIT puzzles (140 total)\n")
        f.write("-- Generated by scripts/seed_puzzles.py\n\n")
        f.write(sql)

    print(f"Generated seed SQL at {output_path}")
    print(f"  14 puzzle_sets")
    print(f"  140 puzzles (10 per day: 5 schematic 5x5 + 5 design 7x7)")
