"""BauHouse puzzle generator — all 5 types.

Generates a full day's worth of puzzles (10 total: 5 schematic + 5 design)
in the correct construction sequence:
  PARCEL(1) → SETBACK(2) → DRAFT(3) → CONDUIT(4) → LAMP(5)

Usage:
    python generate.py --days 14 --output puzzles.json
    python generate.py --days 7 --output puzzles.sql --format sql
"""

import argparse
import json
import uuid
from datetime import datetime, timedelta
from typing import Any, Optional, List, Dict

from conduit_gen import generate_conduit
from parcel_gen import generate_parcel
from setback_gen import generate_setback
from draft_gen import generate_draft
from lamp_gen import generate_lamp

# Grid sizes per mode (from tech spec)
PUZZLE_CONFIGS = {
    "parcel": {"schematic": (6, 6), "design": (8, 8)},
    "setback": {
        "schematic": {"size": (5, 5), "houses": 4, "restricted": 0},
        "design": {"size": (7, 7), "houses": 6, "restricted": 0},
    },
    "draft": {"schematic": (8, 8), "design": (10, 10)},
    "conduit": {"schematic": (5, 5), "design": (7, 7)},
    "lamp": {"schematic": (5, 5), "design": (7, 7)},
}

CONSTRUCTION_SEQUENCE = ["parcel", "setback", "draft", "conduit", "lamp"]

TASK_DESCRIPTIONS = {
    "parcel": [
        "Divide the development zone into rectangular plots matching the planning applications.",
        "Section the land parcels according to the approved subdivision plan.",
        "Mark out the plot boundaries for the residential allotments.",
        "Partition the green space into garden plots for the community.",
        "Lay out the commercial zones matching the zoning requirements.",
    ],
    "setback": [
        "Place the houses respecting the minimum setback regulations between properties.",
        "Position the buildings so no two structures are too close together.",
        "Arrange the dwellings with proper spacing for fire safety compliance.",
        "Set the building footprints within the approved distance from each other.",
        "Locate the structures so every property maintains adequate separation.",
    ],
    "draft": [
        "Reveal the architectural floor plan by filling in the blueprint cells.",
        "Complete the elevation drawing following the given row and column specifications.",
        "Draft the foundation layout by marking the structural grid correctly.",
        "Fill in the site plan to show the building footprint from above.",
        "Complete the cross-section drawing to reveal the interior layout.",
    ],
    "conduit": [
        "Route the main utility conduits through the underground service corridor.",
        "Connect the water and gas lines from the street main to each property.",
        "Design the drainage network linking all properties to the main sewer.",
        "Wire the electrical conduits from the transformer to each building.",
        "Complete the telecommunications ducting for the entire street.",
    ],
    "lamp": [
        "Position the street lamps so every footpath section is illuminated.",
        "Place the lights to cover every corner of the neighbourhood park.",
        "Install the building exterior lights to illuminate all entrance areas.",
        "Set up the garden lighting so no pathway is left in darkness.",
        "Light up the entire streetscape for the official opening ceremony.",
    ],
}


def generate_puzzle(
    puzzle_type: str, mode: str, slot: int
) -> dict:
    """Generate a single puzzle of the given type and mode."""
    if puzzle_type == "conduit":
        w, h = PUZZLE_CONFIGS["conduit"][mode]
        result = generate_conduit(w, h)
    elif puzzle_type == "parcel":
        w, h = PUZZLE_CONFIGS["parcel"][mode]
        result = generate_parcel(w, h)
    elif puzzle_type == "setback":
        cfg = PUZZLE_CONFIGS["setback"][mode]
        w, h = cfg["size"]
        result = generate_setback(w, h, cfg["houses"], cfg["restricted"])
    elif puzzle_type == "draft":
        w, h = PUZZLE_CONFIGS["draft"][mode]
        result = generate_draft(w, h)
    elif puzzle_type == "lamp":
        w, h = PUZZLE_CONFIGS["lamp"][mode]
        result = generate_lamp(w, h)
    else:
        raise ValueError(f"Unknown puzzle type: {puzzle_type}")

    task_descs = TASK_DESCRIPTIONS[puzzle_type]
    task_desc = task_descs[(slot - 1) % len(task_descs)]

    return {
        "puzzle_type": puzzle_type,
        "mode": mode,
        "slot_number": slot,
        "grid_data": result["grid_data"],
        "solution_data": result["solution_data"],
        "task_description": task_desc,
    }


def generate_day(
    puzzle_set_id: str,
) -> list:
    """Generate a full day of 10 puzzles (5 schematic + 5 design)."""
    puzzles = []

    for mode in ["schematic", "design"]:
        for slot, puzzle_type in enumerate(CONSTRUCTION_SEQUENCE, 1):
            puzzle = generate_puzzle(puzzle_type, mode, slot)
            puzzle["id"] = str(uuid.uuid4())
            puzzle["puzzle_set_id"] = puzzle_set_id
            puzzles.append(puzzle)

    return puzzles


def generate_days(
    num_days: int, start_date: Optional[datetime] = None
) -> dict:
    """Generate multiple days of puzzles.

    Returns a dict with 'puzzle_sets' and 'puzzles' lists.
    """
    if start_date is None:
        start_date = datetime.now()

    puzzle_sets = []
    all_puzzles = []

    for day in range(num_days):
        date = start_date + timedelta(days=day)
        date_str = date.strftime("%Y-%m-%d")
        week_num = (day // 7) + 1

        set_id = str(uuid.uuid4())
        puzzle_set = {
            "id": set_id,
            "scheduled_date": date_str,
            "project_name": f"Project Day {day + 1}",
            "client_name": f"The Elmfield Family {day + 1}",
            "brief_intro": f"Today's project for {date_str}. A new day of building in Elmfield.",
            "completion_text": f"Another successful day in Elmfield. The work on this project is complete.",
            "week_number": week_num,
        }
        puzzle_sets.append(puzzle_set)

        day_puzzles = generate_day(set_id)
        all_puzzles.extend(day_puzzles)

    return {"puzzle_sets": puzzle_sets, "puzzles": all_puzzles}


def to_sql(data: dict) -> str:
    """Convert generated data to SQL INSERT statements."""
    lines = ["-- Generated puzzle data\n"]

    for ps in data["puzzle_sets"]:
        lines.append(
            f"INSERT INTO puzzle_sets (id, scheduled_date, project_name, client_name, "
            f"brief_intro, completion_text, week_number) VALUES ("
            f"'{ps['id']}', '{ps['scheduled_date']}', "
            f"'{_esc(ps['project_name'])}', '{_esc(ps['client_name'])}', "
            f"'{_esc(ps['brief_intro'])}', '{_esc(ps['completion_text'])}', "
            f"{ps['week_number']});"
        )

    lines.append("")

    for p in data["puzzles"]:
        grid_json = json.dumps(p["grid_data"]).replace("'", "''")
        sol_json = json.dumps(p["solution_data"]).replace("'", "''")
        lines.append(
            f"INSERT INTO puzzles (id, puzzle_set_id, puzzle_type, mode, slot_number, "
            f"difficulty_score, grid_data, solution_data, task_description) VALUES ("
            f"'{p['id']}', '{p['puzzle_set_id']}', '{p['puzzle_type']}', "
            f"'{p['mode']}', {p['slot_number']}, "
            f"{3.0 + (5.0 if p['mode'] == 'design' else 0.0)}, "
            f"'{grid_json}', '{sol_json}', "
            f"'{_esc(p['task_description'])}');"
        )

    return "\n".join(lines)


def _esc(s: str) -> str:
    """Escape single quotes for SQL."""
    return s.replace("'", "''")


def main():
    parser = argparse.ArgumentParser(description="BauHouse Puzzle Generator")
    parser.add_argument("--days", type=int, default=7, help="Number of days to generate")
    parser.add_argument("--output", type=str, default="puzzles.json", help="Output file")
    parser.add_argument(
        "--format", type=str, choices=["json", "sql"], default="json"
    )
    parser.add_argument("--start-date", type=str, default=None, help="Start date (YYYY-MM-DD)")
    args = parser.parse_args()

    start_date = (
        datetime.strptime(args.start_date, "%Y-%m-%d")
        if args.start_date
        else datetime.now()
    )

    print(f"Generating {args.days} days of puzzles starting from {start_date.strftime('%Y-%m-%d')}...")

    data = generate_days(args.days, start_date)

    print(f"Generated {len(data['puzzle_sets'])} puzzle sets and {len(data['puzzles'])} puzzles")

    if args.format == "sql":
        output = to_sql(data)
    else:
        output = json.dumps(data, indent=2)

    with open(args.output, "w") as f:
        f.write(output)

    print(f"Output written to {args.output}")


if __name__ == "__main__":
    main()
