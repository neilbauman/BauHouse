import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CompletePuzzleRequest {
  puzzle_id: string;
  solution_attempt: Record<string, unknown>;
  difficulty_played: string;
  solve_seconds: number;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Get the user's JWT from the Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create a client with the user's JWT for auth
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });

    // Create a service role client for privileged operations
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Get the authenticated user
    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body: CompletePuzzleRequest = await req.json();
    const { puzzle_id, solution_attempt, difficulty_played, solve_seconds } = body;

    // Validate required fields
    if (!puzzle_id || !solution_attempt || !difficulty_played || solve_seconds == null) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate difficulty_played
    if (!["apprentice", "resident", "architect"].includes(difficulty_played)) {
      return new Response(
        JSON.stringify({ error: "Invalid difficulty_played value" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch the puzzle with solution_data (service role only)
    const { data: puzzle, error: puzzleError } = await adminClient
      .from("puzzles")
      .select("id, puzzle_set_id, puzzle_type, solution_data")
      .eq("id", puzzle_id)
      .single();

    if (puzzleError || !puzzle) {
      return new Response(
        JSON.stringify({ error: "Puzzle not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate the solution attempt against the stored solution
    const isCorrect = validateSolution(
      puzzle.puzzle_type,
      puzzle.solution_data,
      solution_attempt
    );

    if (!isCorrect) {
      return new Response(
        JSON.stringify({ success: false, error: "Incorrect solution" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if already completed
    const { data: existing } = await adminClient
      .from("player_completions")
      .select("id")
      .eq("player_id", user.id)
      .eq("puzzle_id", puzzle_id)
      .maybeSingle();

    if (existing) {
      return new Response(
        JSON.stringify({ success: true, already_completed: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Insert player_completion
    await adminClient.from("player_completions").insert({
      player_id: user.id,
      puzzle_id: puzzle_id,
      difficulty_played: difficulty_played,
      solve_seconds: solve_seconds,
      hints_used: 0,
    });

    // Check if all 10 puzzles in the set are now complete
    const { data: setCompletions } = await adminClient
      .from("player_completions")
      .select("puzzle_id, puzzles!inner(puzzle_set_id)")
      .eq("player_id", user.id)
      .eq("puzzles.puzzle_set_id", puzzle.puzzle_set_id);

    const completedCount = setCompletions?.length ?? 0;

    // Check if schematic session (5 puzzles) is complete
    const { data: schematicCompletions } = await adminClient
      .from("player_completions")
      .select("puzzle_id, puzzles!inner(puzzle_set_id, mode)")
      .eq("player_id", user.id)
      .eq("puzzles.puzzle_set_id", puzzle.puzzle_set_id)
      .eq("puzzles.mode", "schematic");

    const schematicComplete = (schematicCompletions?.length ?? 0) >= 5;
    const dailyComplete = completedCount >= 10;

    // Award credits
    let creditsAwarded = 0;

    if (dailyComplete) {
      // Full daily completion: +10 credits
      creditsAwarded = 10;
      await adminClient.from("credit_transactions").insert({
        player_id: user.id,
        amount: 10,
        reason: "daily_complete",
        reference_id: puzzle.puzzle_set_id,
      });
    } else if (schematicComplete && completedCount === 5) {
      // Just completed schematic session: +5 credits
      creditsAwarded = 5;
      await adminClient.from("credit_transactions").insert({
        player_id: user.id,
        amount: 5,
        reason: "morning_complete",
        reference_id: puzzle.puzzle_set_id,
      });
    }

    // Update streak
    const today = new Date().toISOString().substring(0, 10);
    const { data: player } = await adminClient
      .from("players")
      .select("current_streak, longest_streak, last_active_date, builder_credits")
      .eq("id", user.id)
      .single();

    let newStreak = player?.current_streak ?? 0;
    const lastActive = player?.last_active_date;
    let streakUpdated = false;

    if (lastActive !== today) {
      const yesterday = new Date(Date.now() - 86400000)
        .toISOString()
        .substring(0, 10);

      if (lastActive === yesterday) {
        newStreak += 1;
      } else if (!lastActive) {
        newStreak = 1;
      } else {
        newStreak = 1; // Streak broken
      }
      streakUpdated = true;

      const longestStreak = Math.max(
        newStreak,
        player?.longest_streak ?? 0
      );

      // Check for 7-day streak milestone
      if (newStreak > 0 && newStreak % 7 === 0) {
        creditsAwarded += 15;
        await adminClient.from("credit_transactions").insert({
          player_id: user.id,
          amount: 15,
          reason: "streak_7",
        });
      }

      await adminClient
        .from("players")
        .update({
          current_streak: newStreak,
          longest_streak: longestStreak,
          last_active_date: today,
          builder_credits: (player?.builder_credits ?? 0) + creditsAwarded,
        })
        .eq("id", user.id);
    } else if (creditsAwarded > 0) {
      // Same day, just update credits
      await adminClient
        .from("players")
        .update({
          builder_credits: (player?.builder_credits ?? 0) + creditsAwarded,
        })
        .eq("id", user.id);
    }

    return new Response(
      JSON.stringify({
        success: true,
        credits_awarded: creditsAwarded,
        streak_updated: streakUpdated,
        new_streak: newStreak,
        daily_complete: dailyComplete,
        schematic_complete: schematicComplete,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

/**
 * Validates a solution attempt against the stored solution.
 * Supports CONDUIT and PARCEL puzzle types with proper validation.
 */
function validateSolution(
  puzzleType: string,
  solutionData: Record<string, unknown>,
  attempt: Record<string, unknown>
): boolean {
  switch (puzzleType) {
    case "conduit":
      return validateConduitSolution(solutionData, attempt);
    case "parcel":
      return validateParcelSolution(solutionData, attempt);
    case "setback":
      return validateSetbackSolution(solutionData, attempt);
    case "draft":
      return validateDraftSolution(solutionData, attempt);
    case "lamp":
      // Placeholder — will be implemented when LAMP puzzle type is built
      return JSON.stringify(solutionData) === JSON.stringify(attempt);
    default:
      return false;
  }
}

/**
 * Validates a CONDUIT (pipes) solution.
 * Checks that each cell's rotation matches the solution.
 */
function validateConduitSolution(
  solution: Record<string, unknown>,
  attempt: Record<string, unknown>
): boolean {
  const solCells = (solution as { cells: Array<{ type: string; rotation: number }> }).cells;
  const attCells = (attempt as { cells: Array<{ type: string; rotation: number }> }).cells;

  if (!solCells || !attCells || solCells.length !== attCells.length) {
    return false;
  }

  for (let i = 0; i < solCells.length; i++) {
    if (solCells[i].rotation !== attCells[i].rotation) {
      return false;
    }
  }

  return true;
}

interface ParcelRegion {
  row: number;
  col: number;
  width: number;
  height: number;
}

/**
 * Validates a PARCEL (Shikaku) solution.
 * Checks that the submitted regions match the expected solution regions
 * (same set of rectangles, order-independent).
 */
function validateParcelSolution(
  solution: Record<string, unknown>,
  attempt: Record<string, unknown>
): boolean {
  const solRegions = (solution as { regions: ParcelRegion[] }).regions;
  const attRegions = (attempt as { regions: ParcelRegion[] }).regions;

  if (!solRegions || !attRegions || solRegions.length !== attRegions.length) {
    return false;
  }

  // Normalise and sort both sets of regions for order-independent comparison
  const normalise = (r: ParcelRegion) =>
    `${r.row},${r.col},${r.width},${r.height}`;

  const solSet = new Set(solRegions.map(normalise));
  const attSet = new Set(attRegions.map(normalise));

  if (solSet.size !== attSet.size) return false;
  for (const key of solSet) {
    if (!attSet.has(key)) return false;
  }

  return true;
}

interface HousePosition {
  row: number;
  col: number;
}

/**
 * Validates a SETBACK (Kings variant) solution.
 * Checks that the submitted house positions match the expected solution
 * (same set of positions, order-independent).
 */
function validateSetbackSolution(
  solution: Record<string, unknown>,
  attempt: Record<string, unknown>
): boolean {
  const solHouses = (solution as { houses: HousePosition[] }).houses;
  const attHouses = (attempt as { houses: HousePosition[] }).houses;

  if (!solHouses || !attHouses || solHouses.length !== attHouses.length) {
    return false;
  }

  const normalise = (h: HousePosition) => `${h.row},${h.col}`;

  const solSet = new Set(solHouses.map(normalise));
  const attSet = new Set(attHouses.map(normalise));

  if (solSet.size !== attSet.size) return false;
  for (const key of solSet) {
    if (!attSet.has(key)) return false;
  }

  return true;
}

/**
 * Validates a DRAFT (Nonogram) solution.
 * Compares the flat cells array (0=empty, 1=filled) against the expected solution.
 */
function validateDraftSolution(
  solution: Record<string, unknown>,
  attempt: Record<string, unknown>
): boolean {
  const solCells = (solution as { cells: number[] }).cells;
  const attCells = (attempt as { cells: number[] }).cells;

  if (!solCells || !attCells || solCells.length !== attCells.length) {
    return false;
  }

  for (let i = 0; i < solCells.length; i++) {
    if (solCells[i] !== attCells[i]) return false;
  }

  return true;
}
