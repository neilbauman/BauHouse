"""BauHouse narrative generator service.

Generates Build Brief narratives for puzzle sets using an LLM API (Anthropic Claude).
Includes a template fallback for development without an API key.

Usage:
    # Generate narratives for existing puzzle data (JSON file from puzzle generator)
    python generate_narrative.py --input puzzles.json --output enriched.json

    # Generate narratives and write directly to Supabase
    python generate_narrative.py --input puzzles.json --write-db

    # Use template fallback (no API key needed)
    python generate_narrative.py --input puzzles.json --output enriched.json --template

    # Generate for a specific date range
    python generate_narrative.py --days 7 --start-date 2026-02-15 --output narratives.json
"""

import argparse
import json
import os
import random
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import anthropic
except ImportError:
    anthropic = None

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass


PROMPTS_DIR = Path(__file__).parent / "prompts"
SYSTEM_PROMPT_FILE = PROMPTS_DIR / "build_brief.txt"

CONSTRUCTION_SEQUENCE = ["parcel", "setback", "draft", "conduit", "lamp"]

PUZZLE_TYPE_LABELS = {
    "parcel": "land division",
    "setback": "building placement",
    "draft": "blueprint drawing",
    "conduit": "utility routing",
    "lamp": "street lighting",
}


def load_system_prompt() -> str:
    """Load the system prompt from the prompts directory."""
    with open(SYSTEM_PROMPT_FILE, "r") as f:
        return f.read().strip()


def build_user_prompt(
    date_str: str,
    week_number: int,
    day_of_week: str,
    previous_briefs: Optional[List[Dict[str, str]]] = None,
) -> str:
    """Build the user prompt for a single day's Build Brief generation."""

    context_parts = [
        f"Generate a Build Brief for {day_of_week}, {date_str} (Week {week_number} in Elmfield).",
        "",
        "The construction sequence for each session is:",
        "  1. PARCEL — land division / plot layout",
        "  2. SETBACK — building placement with spacing rules",
        "  3. DRAFT — blueprint / floor plan reveal",
        "  4. CONDUIT — utility pipe routing",
        "  5. LAMP — street lighting placement",
        "",
        "There are two sessions: Schematic (5 puzzles) and Design (5 puzzles), "
        "both following the same construction sequence. That makes 10 task_descriptions total.",
        "",
    ]

    if previous_briefs:
        context_parts.append(
            "Previous briefs this week (avoid reusing these family names or project types):"
        )
        for pb in previous_briefs:
            context_parts.append(
                f'  - "{pb["project_name"]}" for {pb["client_name"]}'
            )
        context_parts.append("")

    context_parts.extend([
        "Return a single JSON object with these exact keys:",
        '  "project_name": string (max 5 words, e.g. "The Okafor Garden Cottage")',
        '  "client_name": string (a family or individual, e.g. "The Okafor-Hughes Family")',
        '  "brief_intro": string (2-3 sentences setting up today\'s project)',
        '  "task_descriptions": array of exactly 10 strings, each one sentence:',
        "    [0-4] = Schematic session tasks (parcel, setback, draft, conduit, lamp)",
        "    [5-9] = Design session tasks (parcel, setback, draft, conduit, lamp)",
        '  "completion_text": string (2-3 sentences of gentle resolution)',
        "",
        "Return ONLY the JSON object. No markdown fences, no explanation.",
    ])

    return "\n".join(context_parts)


def generate_narrative_llm(
    date_str: str,
    week_number: int,
    previous_briefs: Optional[List[Dict[str, str]]] = None,
    api_key: Optional[str] = None,
) -> Dict[str, Any]:
    """Generate a Build Brief narrative using Claude API."""
    if anthropic is None:
        raise RuntimeError(
            "anthropic package not installed. Run: pip install anthropic"
        )

    key = api_key or os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY not set. Provide via --api-key or environment variable."
        )

    client = anthropic.Anthropic(api_key=key)

    date_obj = datetime.strptime(date_str, "%Y-%m-%d")
    day_of_week = date_obj.strftime("%A")

    system_prompt = load_system_prompt()
    user_prompt = build_user_prompt(
        date_str, week_number, day_of_week, previous_briefs
    )

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1024,
        messages=[{"role": "user", "content": user_prompt}],
        system=system_prompt,
    )

    response_text = message.content[0].text.strip()

    # Strip markdown fences if present
    if response_text.startswith("```"):
        lines = response_text.split("\n")
        lines = lines[1:]  # Remove opening fence
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        response_text = "\n".join(lines)

    brief = json.loads(response_text)

    # Validate required fields
    required = ["project_name", "client_name", "brief_intro", "task_descriptions", "completion_text"]
    for field in required:
        if field not in brief:
            raise ValueError(f"LLM response missing required field: {field}")

    if len(brief["task_descriptions"]) != 10:
        raise ValueError(
            f"Expected 10 task_descriptions, got {len(brief['task_descriptions'])}"
        )

    return brief


# --- Template fallback for development without an API key ---

FAMILY_NAMES = [
    "The Kowalski Family", "The Martins", "The Okafor-Hughes Family",
    "The Petersen Household", "Mr and Mrs Chen", "The Nguyen Family",
    "The Johansens", "Rosa and Tomás Delgado", "The Campbell-Bells",
    "The Abara Family", "The McKinnons", "Anya and Leo Rossi",
    "The Takahashi Family", "The Dubois Household", "The Sharma-Patels",
    "The Bergströms", "The Moreau Family", "The Adeyemi-Clarks",
    "The Fitzpatricks", "The Kim-Santos Family", "The Wolfe-Bakers",
    "The El-Amin Family", "The Tsoukalas Household", "Mrs Oluwole",
    "The Henriksen-Lees", "The Papadopoulos Family", "The Andersons",
    "The Rivera-Nguyens", "The Blackwood Family", "The Ishikawa-Grants",
]

PROJECT_TEMPLATES = [
    ("{family}'s New Home", "Plot {plot} on {street} has been allocated to {family}. "
     "The planning permission came through last week and the build starts today. "
     "There's a busy schedule ahead — the family hopes to move in by month's end."),
    ("The {street} Extension", "{family} are extending their property on {street}. "
     "The plans were drawn up over the winter and all permissions are in order. "
     "Your job today is to see it through from foundation to first light."),
    ("{family}'s Garden Project", "{family} on {street} have commissioned a garden renovation. "
     "The existing layout needs rethinking — new boundaries, proper lighting, and a revised floor plan. "
     "This is careful work, and they're trusting you with it."),
    ("The {street} Renovation", "Number {plot} {street} is getting a makeover. "
     "{family} bought the property last autumn and the renovation starts today. "
     "It's a straightforward job if the plans are followed precisely."),
    ("A Cottage for {short_name}", "{family} have been on the waiting list for Plot {plot} on {street}. "
     "Today the land is theirs. A modest cottage is planned — nothing extravagant, just solid and well-lit. "
     "Good building starts with good planning."),
]

STREETS = [
    "Birch Street", "Elm Avenue", "Cedar Lane", "Oak Drive", "Pine Crescent",
    "Willow Road", "Maple Close", "Ash Way", "Rowan Terrace", "Hazel Court",
    "Linden Walk", "Beech Row", "Alder Lane", "Holly Street", "Ivy Place",
]

SCHEMATIC_TASK_TEMPLATES = {
    "parcel": [
        "Divide the land into the approved rectangular plots for {short_name}'s property.",
        "Section {short_name}'s plot according to the planning survey.",
        "Lay out the plot boundaries before the groundwork can begin.",
        "Mark out the garden and building zones as specified in the plans.",
        "Partition the site into the areas outlined in the development brief.",
    ],
    "setback": [
        "Position the buildings so every structure meets the setback regulations.",
        "Place the buildings with the required spacing between each dwelling.",
        "Arrange the outbuildings to comply with the minimum separation distances.",
        "Set the building footprints where the surveyor has marked.",
        "Locate each structure within the approved distance from the boundaries.",
    ],
    "draft": [
        "Reveal the ground-floor plan by filling in the blueprint.",
        "Complete the architectural drawing to show {short_name}'s layout.",
        "Draft the foundation plan following the structural grid.",
        "Fill in the elevation drawing for the planning committee review.",
        "Complete the cross-section to reveal the internal arrangement.",
    ],
    "conduit": [
        "Route the main water and gas lines from the street to the property.",
        "Connect {short_name}'s house to the underground utilities network.",
        "Design the drainage system linking the property to the main sewer.",
        "Wire the electrical conduits from the junction box to each room.",
        "Complete the service ducting before the foundation pour.",
    ],
    "lamp": [
        "Position the street lamps so every path around the property is lit.",
        "Install the exterior lights so no entrance is left in shadow.",
        "Place the garden lights to illuminate every pathway.",
        "Light the approach road for {short_name}'s housewarming.",
        "Set up the neighbourhood lighting for the street inspection.",
    ],
}

DESIGN_TASK_TEMPLATES = {
    "parcel": [
        "Refine the land division with the updated measurements from the surveyor.",
        "Finalise the plot boundaries for the detailed development plan.",
        "Section the larger site into the approved residential allotments.",
        "Divide the commercial zone according to the revised planning brief.",
        "Complete the final land parcel layout for council submission.",
    ],
    "setback": [
        "Place the full set of buildings for the development phase.",
        "Arrange the denser housing plan while maintaining fire safety distances.",
        "Position the community buildings with the correct separation.",
        "Set the final building placement for the architect's sign-off.",
        "Complete the advanced spacing plan for the planning review.",
    ],
    "draft": [
        "Reveal the detailed first-floor blueprint with all interior walls.",
        "Complete the architect's full elevation with precise specifications.",
        "Draft the complex structural layout for the engineering review.",
        "Fill in the detailed site plan for the building inspector.",
        "Complete the full technical drawing for {short_name}'s project.",
    ],
    "conduit": [
        "Design the advanced utility network for the expanded development.",
        "Route the complex piping system through the multi-storey structure.",
        "Connect the extended service corridor to all new properties.",
        "Wire the full electrical and data infrastructure.",
        "Complete the integrated utility routing for the entire block.",
    ],
    "lamp": [
        "Position the full lighting scheme for the expanded streetscape.",
        "Install the advanced lighting plan covering the entire development.",
        "Light every corner of the completed neighbourhood.",
        "Set up the ceremonial lighting for the grand opening.",
        "Complete the final illumination of {short_name}'s finished street.",
    ],
}

COMPLETION_TEMPLATES = [
    "The lights are on at {plot} {street}. {family} can see their new home from the "
    "end of the road, and it looks exactly as they'd hoped. Another good day in Elmfield.",
    "{short_name}'s project is complete. The plans were followed, the work was done well, "
    "and {street} has a new addition to be proud of. Tomorrow brings another brief.",
    "With the last lamp in place, {family}'s build is finished. {street} is a little "
    "brighter tonight. The town grows, one careful day at a time.",
    "Everything is connected, everything is lit. {family} will move in on Friday, "
    "and {street} will feel just a little more like home. Well done, builder.",
    "The build is done. {short_name}'s keys are ready for collection and {street} "
    "looks better for the work. Elmfield remembers everyone who builds here.",
]


def generate_narrative_template(
    date_str: str,
    week_number: int,
    previous_briefs: Optional[List[Dict[str, str]]] = None,
) -> Dict[str, Any]:
    """Generate a Build Brief narrative using templates (no API key needed)."""
    rng = random.Random(date_str)

    used_families = set()
    if previous_briefs:
        for pb in previous_briefs:
            used_families.add(pb.get("client_name", ""))

    available_families = [f for f in FAMILY_NAMES if f not in used_families]
    if not available_families:
        available_families = FAMILY_NAMES

    family = rng.choice(available_families)

    # Derive a short name from the family name
    short_name = family.replace("The ", "").replace(" Family", "").replace(
        " Household", ""
    ).split(",")[0].strip()
    if short_name.startswith("Mr and Mrs "):
        short_name = "the " + short_name.split(" ")[-1] + "s"

    street = rng.choice(STREETS)
    plot = rng.randint(1, 40)

    template = rng.choice(PROJECT_TEMPLATES)
    project_name = template[0].format(
        family=short_name, street=street.split(" ")[0], short_name=short_name
    )
    brief_intro = template[1].format(
        family=family, street=street, plot=plot, short_name=short_name
    )

    # Generate 10 task descriptions (5 schematic + 5 design)
    task_descriptions = []
    for puzzle_type in CONSTRUCTION_SEQUENCE:
        task = rng.choice(SCHEMATIC_TASK_TEMPLATES[puzzle_type])
        task_descriptions.append(task.format(short_name=short_name))

    for puzzle_type in CONSTRUCTION_SEQUENCE:
        task = rng.choice(DESIGN_TASK_TEMPLATES[puzzle_type])
        task_descriptions.append(task.format(short_name=short_name))

    completion = rng.choice(COMPLETION_TEMPLATES).format(
        family=family, street=street, plot=plot, short_name=short_name
    )

    return {
        "project_name": project_name,
        "client_name": family,
        "brief_intro": brief_intro,
        "task_descriptions": task_descriptions,
        "completion_text": completion,
    }


def enrich_puzzle_data(
    puzzle_data: Dict[str, Any],
    use_template: bool = False,
    api_key: Optional[str] = None,
) -> Dict[str, Any]:
    """Enrich existing puzzle data with narrative content.

    Takes the output from the puzzle generator and adds LLM-generated
    (or template) narratives to each puzzle_set and its puzzles.
    """
    enriched_sets = []
    enriched_puzzles = list(puzzle_data["puzzles"])

    previous_briefs = []  # type: List[Dict[str, str]]

    for ps in puzzle_data["puzzle_sets"]:
        date_str = ps["scheduled_date"]
        week_number = ps.get("week_number", 1)

        if use_template:
            brief = generate_narrative_template(date_str, week_number, previous_briefs)
        else:
            brief = generate_narrative_llm(date_str, week_number, previous_briefs, api_key)

        # Update puzzle set with narrative content
        ps["project_name"] = brief["project_name"]
        ps["client_name"] = brief["client_name"]
        ps["brief_intro"] = brief["brief_intro"]
        ps["completion_text"] = brief["completion_text"]

        enriched_sets.append(ps)

        # Update individual puzzle task descriptions
        set_puzzles = [
            p for p in enriched_puzzles if p["puzzle_set_id"] == ps["id"]
        ]

        # Sort by mode then slot
        schematic = sorted(
            [p for p in set_puzzles if p["mode"] == "schematic"],
            key=lambda x: x["slot_number"],
        )
        design = sorted(
            [p for p in set_puzzles if p["mode"] == "design"],
            key=lambda x: x["slot_number"],
        )

        ordered = schematic + design
        for i, puzzle in enumerate(ordered):
            if i < len(brief["task_descriptions"]):
                puzzle["task_description"] = brief["task_descriptions"][i]

        previous_briefs.append({
            "project_name": brief["project_name"],
            "client_name": brief["client_name"],
        })

    return {"puzzle_sets": enriched_sets, "puzzles": enriched_puzzles}


def generate_standalone_narratives(
    num_days: int,
    start_date: Optional[datetime] = None,
    use_template: bool = False,
    api_key: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Generate standalone narrative content (without puzzle data)."""
    if start_date is None:
        start_date = datetime.now()

    narratives = []
    previous_briefs = []  # type: List[Dict[str, str]]

    for day in range(num_days):
        date = start_date + timedelta(days=day)
        date_str = date.strftime("%Y-%m-%d")
        week_number = (day // 7) + 1

        if use_template:
            brief = generate_narrative_template(date_str, week_number, previous_briefs)
        else:
            brief = generate_narrative_llm(date_str, week_number, previous_briefs, api_key)

        brief["scheduled_date"] = date_str
        brief["week_number"] = week_number
        narratives.append(brief)

        previous_briefs.append({
            "project_name": brief["project_name"],
            "client_name": brief["client_name"],
        })

    return narratives


def write_to_supabase(
    enriched_data: Dict[str, Any],
    supabase_url: Optional[str] = None,
    supabase_key: Optional[str] = None,
) -> None:
    """Write enriched narrative data to Supabase."""
    try:
        from supabase import create_client
    except ImportError:
        raise RuntimeError("supabase package not installed. Run: pip install supabase")

    url = supabase_url or os.environ.get("SUPABASE_URL")
    key = supabase_key or os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not url or not key:
        raise RuntimeError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set."
        )

    client = create_client(url, key)

    for ps in enriched_data["puzzle_sets"]:
        client.table("puzzle_sets").upsert(ps).execute()

    for puzzle in enriched_data["puzzles"]:
        update_data = {
            "id": puzzle["id"],
            "task_description": puzzle["task_description"],
        }
        client.table("puzzles").upsert(update_data).execute()

    print(f"Wrote {len(enriched_data['puzzle_sets'])} puzzle sets and "
          f"{len(enriched_data['puzzles'])} puzzles to Supabase.")


def main():
    parser = argparse.ArgumentParser(
        description="BauHouse Narrative Generator"
    )
    parser.add_argument(
        "--input", type=str, default=None,
        help="Input puzzle data JSON (from puzzle generator)"
    )
    parser.add_argument(
        "--output", type=str, default=None,
        help="Output file (JSON)"
    )
    parser.add_argument(
        "--template", action="store_true",
        help="Use template narratives (no API key needed)"
    )
    parser.add_argument(
        "--write-db", action="store_true",
        help="Write results to Supabase"
    )
    parser.add_argument(
        "--api-key", type=str, default=None,
        help="Anthropic API key (overrides ANTHROPIC_API_KEY env var)"
    )
    parser.add_argument(
        "--days", type=int, default=None,
        help="Generate standalone narratives for N days"
    )
    parser.add_argument(
        "--start-date", type=str, default=None,
        help="Start date for standalone generation (YYYY-MM-DD)"
    )
    args = parser.parse_args()

    if args.input:
        with open(args.input, "r") as f:
            puzzle_data = json.load(f)

        print(f"Enriching {len(puzzle_data['puzzle_sets'])} puzzle sets with narratives...")

        enriched = enrich_puzzle_data(
            puzzle_data,
            use_template=args.template,
            api_key=args.api_key,
        )

        if args.write_db:
            write_to_supabase(enriched)

        if args.output:
            with open(args.output, "w") as f:
                json.dump(enriched, f, indent=2)
            print(f"Enriched data written to {args.output}")
        elif not args.write_db:
            print(json.dumps(enriched, indent=2))

    elif args.days:
        start_date = (
            datetime.strptime(args.start_date, "%Y-%m-%d")
            if args.start_date
            else datetime.now()
        )

        print(f"Generating narratives for {args.days} days...")

        narratives = generate_standalone_narratives(
            args.days,
            start_date=start_date,
            use_template=args.template,
            api_key=args.api_key,
        )

        if args.output:
            with open(args.output, "w") as f:
                json.dump(narratives, f, indent=2)
            print(f"Narratives written to {args.output}")
        else:
            print(json.dumps(narratives, indent=2))
    else:
        parser.error("Provide --input (puzzle data file) or --days (standalone generation)")


if __name__ == "__main__":
    main()
