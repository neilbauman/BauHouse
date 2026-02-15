import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const UNLOCK_CREDIT_COST = 20;

/**
 * unlock-archive
 *
 * Unlocks a past puzzle_set for the requesting player.
 * Supports two unlock methods:
 *   - "credits": deducts Builder's Credits from the player
 *   - "rewarded_ad": validated client-side, no credit deduction
 *
 * Premium (Full Resident) players have free unlimited archive access
 * and should not need to call this endpoint.
 */
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get the authenticated user
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    // Create client with user's auth to get their ID
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
    } = await userClient.auth.getUser();

    if (!user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { puzzle_set_id, unlock_method } = await req.json();

    if (!puzzle_set_id || !unlock_method) {
      return new Response(
        JSON.stringify({ error: "Missing puzzle_set_id or unlock_method" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!["credits", "rewarded_ad"].includes(unlock_method)) {
      return new Response(
        JSON.stringify({ error: "Invalid unlock_method" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Use service role client for database operations
    const serviceClient = createClient(supabaseUrl, supabaseServiceKey);

    // Verify the puzzle set exists
    const { data: puzzleSet } = await serviceClient
      .from("puzzle_sets")
      .select("id, scheduled_date")
      .eq("id", puzzle_set_id)
      .single();

    if (!puzzleSet) {
      return new Response(
        JSON.stringify({ error: "Puzzle set not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check if already unlocked
    const { data: existingUnlock } = await serviceClient
      .from("archive_unlocks")
      .select("id")
      .eq("player_id", user.id)
      .eq("puzzle_set_id", puzzle_set_id)
      .maybeSingle();

    if (existingUnlock) {
      return new Response(
        JSON.stringify({ success: true, message: "Already unlocked" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let creditsRemaining: number | null = null;

    if (unlock_method === "credits") {
      // Fetch current credits
      const { data: player } = await serviceClient
        .from("players")
        .select("builder_credits")
        .eq("id", user.id)
        .single();

      if (!player || player.builder_credits < UNLOCK_CREDIT_COST) {
        return new Response(
          JSON.stringify({
            error: "Insufficient credits",
            required: UNLOCK_CREDIT_COST,
            available: player?.builder_credits || 0,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Deduct credits
      creditsRemaining = player.builder_credits - UNLOCK_CREDIT_COST;

      await serviceClient
        .from("players")
        .update({ builder_credits: creditsRemaining })
        .eq("id", user.id);

      // Record credit transaction
      await serviceClient.from("credit_transactions").insert({
        player_id: user.id,
        amount: -UNLOCK_CREDIT_COST,
        reason: "unlock_archive",
        reference_id: puzzle_set_id,
      });
    }

    // Record the unlock
    await serviceClient.from("archive_unlocks").insert({
      player_id: user.id,
      puzzle_set_id: puzzle_set_id,
      unlock_method: unlock_method,
    });

    // Calculate days ago for analytics
    const scheduledDate = new Date(puzzleSet.scheduled_date);
    const today = new Date();
    const daysAgo = Math.floor(
      (today.getTime() - scheduledDate.getTime()) / (1000 * 60 * 60 * 24)
    );

    console.log(
      `Archive unlocked: player=${user.id}, set=${puzzle_set_id}, ` +
      `method=${unlock_method}, days_ago=${daysAgo}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        credits_remaining: creditsRemaining,
        days_ago: daysAgo,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Unlock archive error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
